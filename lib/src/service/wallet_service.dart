import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/points_config.dart';
import '../models/wallet_models.dart';
import 'points_logger.dart';

class WalletService {
  // Singleton pattern
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PointsLogger _pointsLogger = PointsLogger();

  // Collection references
  CollectionReference get _balances => _firestore.collection('wallet_balances');
  CollectionReference get _transactions => _firestore.collection('wallet_transactions');
  DocumentReference get _settings => _firestore.collection('wallet_settings').doc('global_settings');
  
  // Cache for current multipliers
  Map<String, double> _activeMultipliers = {};

  // Cache for wallet settings
  WalletSettings? _cachedSettings;

  /// Initialize wallet for a new user
  Future<void> initializeWallet(String userId) async {
    try {
      final defaultLimits = {
        'daily_transaction_limit': 10000,
        'max_balance': 1000000,
        'min_balance': 0,
      };

      await _balances.doc(userId).set({
        'balance': 0.0,
        'tournament_points': 0,
        'last_updated': FieldValue.serverTimestamp(),
        'currency': 'FLIXBIT',
        'status': 'active',
        'account_type': 'user',
        'limits': defaultLimits,
      });

      debugPrint('Wallet initialized for user: $userId');
    } catch (e) {
      throw Exception('Failed to initialize wallet: $e');
    }
  }

  /// Get user's wallet balance
  Stream<WalletBalance> getWalletBalance(String userId) {
    return _balances.doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        throw Exception('Wallet not found');
      }
      return WalletBalance.fromFirestore(doc);
    });
  }

  /// Get wallet settings
  Future<WalletSettings> getWalletSettings() async {
    try {
      if (_cachedSettings != null) {
        return _cachedSettings!;
      }

      final doc = await _settings.get();
      if (!doc.exists) {
        // Initialize with default settings if not exists
        final defaults = WalletSettings.defaults();
        await _settings.set(defaults.toFirestore());
        _cachedSettings = defaults;
        return defaults;
      }

      _cachedSettings = WalletSettings.fromFirestore(doc);
      return _cachedSettings!;
    } catch (e) {
      throw Exception('Failed to get wallet settings: $e');
    }
  }

  /// Add transaction and update balance
  Future<WalletTransaction> createTransaction({
    required String userId,
    required TransactionType type,
    required double amount,
    required TransactionSource source,
    String? referenceId,
    Map<String, dynamic>? sourceDetails,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Start a Firestore transaction
      return await _firestore.runTransaction<WalletTransaction>((transaction) async {
        // Get current balance
        final balanceDoc = await transaction.get(_balances.doc(userId));
        if (!balanceDoc.exists) {
          throw Exception('Wallet not found');
        }

        final data = balanceDoc.data() as Map<String, dynamic>;
        final currentBalance = (data['balance'] as num).toDouble();
        double newBalance;

        // Calculate new balance based on transaction type
        switch (type) {
          case TransactionType.earn:
          case TransactionType.buy:
          case TransactionType.gift:
          case TransactionType.reward:
          case TransactionType.refund:
            newBalance = currentBalance + amount;
            break;
          case TransactionType.spend:
          case TransactionType.sell:
            if (currentBalance < amount) {
              throw Exception('Insufficient balance');
            }
            newBalance = currentBalance - amount;
            break;
        }

        // Create transaction document
        final transactionDoc = _transactions.doc();
        final timestamp = FieldValue.serverTimestamp();
        
        final transactionData = {
          'user_id': userId,
          'transaction_type': type.toString().split('.').last,
          'amount': amount,
          'balance_before': currentBalance,
          'balance_after': newBalance,
          'source': {
            'type': source.toString().split('.').last,
            'reference_id': referenceId,
            'details': sourceDetails,
          },
          'status': TransactionStatus.completed.toString().split('.').last,
          'timestamp': timestamp,
          'metadata': metadata,
        };

        // Update balance
        transaction.update(_balances.doc(userId), {
          'balance': newBalance,
          'last_updated': timestamp,
        });

        // Create transaction record
        transaction.set(transactionDoc, transactionData);

        return WalletTransaction(
          id: transactionDoc.id,
          userId: userId,
          type: type,
          amount: amount,
          balanceBefore: currentBalance,
          balanceAfter: newBalance,
          source: source,
          referenceId: referenceId,
          sourceDetails: sourceDetails,
          status: TransactionStatus.completed,
          timestamp: DateTime.now(), // Will be replaced by server timestamp
          metadata: metadata,
        );
      });
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  /// Get transaction history for a user
  Stream<List<WalletTransaction>> getTransactionHistory(String userId, {
    int limit = 50,
    TransactionType? type,
    TransactionSource? source,
  }) {
    Query query = _transactions
        .where('user_id', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (type != null) {
      query = query.where('transaction_type', 
          isEqualTo: type.toString().split('.').last);
    }

    if (source != null) {
      query = query.where('source.type', 
          isEqualTo: source.toString().split('.').last);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => WalletTransaction.fromFirestore(doc))
          .toList();
    });
  }

  /// Add tournament points
  Future<void> addTournamentPoints(String userId, int points) async {
    try {
      await _balances.doc(userId).update({
        'tournament_points': FieldValue.increment(points),
        'last_updated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add tournament points: $e');
    }
  }

  /// Convert tournament points to Flixbit points
  Future<void> convertTournamentPoints(String userId, int pointsToConvert) async {
    try {
      final settings = await getWalletSettings();
      final conversionRate = settings.conversionRates['tournament_to_flixbit'] ?? 5;
      
      await _firestore.runTransaction((transaction) async {
        final balanceDoc = await transaction.get(_balances.doc(userId));
        if (!balanceDoc.exists) {
          throw Exception('Wallet not found');
        }

        final data = balanceDoc.data() as Map<String, dynamic>;
        final currentTournamentPoints = (data['tournament_points'] as num).toInt();
        if (currentTournamentPoints < pointsToConvert) {
          throw Exception('Insufficient tournament points');
        }

        final flixbitPointsToAdd = pointsToConvert * conversionRate;

        transaction.update(_balances.doc(userId), {
          'tournament_points': FieldValue.increment(-pointsToConvert),
          'balance': FieldValue.increment(flixbitPointsToAdd),
          'last_updated': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to convert tournament points: $e');
    }
  }

  /// Check if user has sufficient balance
  Future<bool> hasSufficientBalance(String userId, double amount) async {
    try {
      final doc = await _balances.doc(userId).get();
      if (!doc.exists) {
        return false;
      }
      final data = doc.data() as Map<String, dynamic>;
      final balance = (data['balance'] as num).toDouble();
      return balance >= amount;
    } catch (e) {
      throw Exception('Failed to check balance: $e');
    }
  }

  /// Award points for an activity
  Future<void> awardPoints({
    required String userId,
    required String activity,
    Map<String, dynamic>? metadata,
    String? eventMultiplier,
  }) async {
    try {
      // Check daily limit
      if (await _pointsLogger.hasReachedDailyLimit(userId, activity)) {
        throw Exception('Daily limit reached for $activity');
      }

      // Get base points
      int points = PointsConfig.getPoints(activity);

      // Apply multiplier if any
      if (eventMultiplier != null) {
        points = (PointsConfig.applyEventMultiplier(eventMultiplier, points)).toInt();
      }

      // Log points
      await _pointsLogger.logPoints(
        userId: userId,
        activity: activity,
        points: points,
        metadata: metadata,
      );

      // Create wallet transaction
      await createTransaction(
        userId: userId,
        type: TransactionType.earn,
        amount: points.toDouble(),
        source: TransactionSource.reward,
        sourceDetails: {
          'activity': activity,
          'multiplier': eventMultiplier,
        },
        metadata: metadata,
      );

      debugPrint('Awarded $points points for $activity');
    } catch (e) {
      debugPrint('Error awarding points: $e');
      rethrow;
    }
  }

  /// Update achievement progress
  Future<void> updateAchievement({
    required String userId,
    required String achievement,
    required int progress,
  }) async {
    try {
      await _pointsLogger.updateAchievementProgress(
        userId,
        achievement,
        progress,
      );
    } catch (e) {
      debugPrint('Error updating achievement: $e');
      rethrow;
    }
  }

  /// Get points history with achievements
  Future<Map<String, dynamic>> getPointsOverview(String userId) async {
    try {
      final dailyStats = await _pointsLogger.getDailyStats(userId);
      final achievements = await _pointsLogger.getAchievements(userId);
      
      return {
        'daily_stats': dailyStats,
        'achievements': achievements,
      };
    } catch (e) {
      debugPrint('Error getting points overview: $e');
      rethrow;
    }
  }

  /// Set active event multiplier
  void setEventMultiplier(String event, double multiplier) {
    _activeMultipliers[event] = multiplier;
  }

  /// Clear event multiplier
  void clearEventMultiplier(String event) {
    _activeMultipliers.remove(event);
  }

  /// Get active multipliers
  Map<String, double> getActiveMultipliers() {
    return Map.unmodifiable(_activeMultipliers);
  }

  /// Get daily transaction summary
  Future<Map<String, num>> getDailyTransactionSummary(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final querySnapshot = await _transactions
          .where('user_id', isEqualTo: userId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(startOfDay.subtract(const Duration(seconds: 1))))
          .get();

      double totalEarned = 0;
      double totalSpent = 0;

      for (var doc in querySnapshot.docs) {
        final transaction = WalletTransaction.fromFirestore(doc);
        switch (transaction.type) {
          case TransactionType.earn:
          case TransactionType.buy:
          case TransactionType.gift:
          case TransactionType.reward:
          case TransactionType.refund:
            totalEarned += transaction.amount;
            break;
          case TransactionType.spend:
          case TransactionType.sell:
            totalSpent += transaction.amount;
            break;
        }
      }

      return {
        'total_earned': totalEarned,
        'total_spent': totalSpent,
        'transaction_count': querySnapshot.size,
      };
    } catch (e) {
      throw Exception('Failed to get daily summary: $e');
    }
  }
}
