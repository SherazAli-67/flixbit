import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flixbit/src/res/firebase_constants.dart';
import 'package:flutter/cupertino.dart';
import '../models/wallet_models.dart';
import '../models/reward_model.dart';

/// Service for managing wallet operations including buy, sell, and balance management
class WalletService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user's wallet
  static Future<WalletBalance> getWallet(String userId) async {
    try {
      final doc = await _firestore
          .collection('wallets')
          .doc(userId)
          .get();


      if (!doc.exists) {
        // Create default wallet
        return await _createWallet(userId);
      }
      return WalletBalance.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get wallet: $e');
    }
  }

  /// Create new wallet for user
  static Future<WalletBalance> _createWallet(String userId) async {
    final settings = WalletSettings.defaults();
    
    final wallet = WalletBalance(
      userId: userId,
      flixbitPoints: 0,
      tournamentPoints: 0, // Analytics tracking field
      lastUpdated: DateTime.now(),
      limits: {
        'min_purchase': settings.transactionLimits['min_purchase']!,
        'max_purchase': settings.transactionLimits['max_purchase']!,
        'daily_earning_cap': settings.transactionLimits['daily_earning_cap']!,
      },
    );

    await _firestore
        .collection('wallets')
        .doc(userId)
        .set(wallet.toFirestore());

    return wallet;
  }

  /// Purchase Flixbit points
  static Future<WalletTransaction> purchasePoints({
    required String userId,
    required int points,
    required double amountUSD,
    required String paymentMethod,
    required String paymentId,
  }) async {
    try {
      final wallet = await getWallet(userId);
      final settings = WalletSettings.defaults();

      // Check limits
      if (points < settings.transactionLimits['min_purchase']! ||
          points > settings.transactionLimits['max_purchase']!) {
        throw Exception(
            'Purchase amount must be between ${settings.transactionLimits['min_purchase']} and ${settings.transactionLimits['max_purchase']} points');
      }

      final newBalance = wallet.flixbitPoints + points;

      // Update balance in wallets collection
      await _firestore.collection('wallets').doc(userId).update({
        'balance': newBalance,
        'last_updated': FieldValue.serverTimestamp(),
      });

      // Also update user document for quick access
      await _firestore.collection('users').doc(userId).update({
        'flixbitBalance': newBalance.toInt(),
      });

      // Create transaction
      final transactionId = _firestore.collection('wallet_transactions').doc().id;
      
      final transaction = WalletTransaction(
        id: transactionId,
        userId: userId,
        type: TransactionType.buy,
        amount: points.toDouble(),
        balanceBefore: wallet.flixbitPoints,
        balanceAfter: newBalance,
        source: TransactionSource.purchase,
        referenceId: paymentId,
        sourceDetails: {
          'payment_method': paymentMethod,
          'amount_usd': amountUSD,
        },
        status: TransactionStatus.completed,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('wallet_transactions')
          .doc(transaction.id)
          .set(transaction.toFirestore());

      // Send notification
      await _sendNotification(
        userId: userId,
        title: '✅ Purchase Successful!',
        body: 'You purchased $points Flixbit points for \$$amountUSD',
        type: 'purchase',
      );

      return transaction;
    } catch (e) {
      throw Exception('Failed to purchase points: $e');
    }
  }

  /// Sell Flixbit points (convert to cash)
  static Future<WalletTransaction> sellPoints({
    required String userId,
    required int points,
    required String payoutMethod,
  }) async {
    try {
      final wallet = await getWallet(userId);
      final settings = WalletSettings.defaults();

      // Check minimum withdrawal
      if (points < settings.transactionLimits['min_withdrawal']!) {
        throw Exception(
            'Minimum withdrawal is ${settings.transactionLimits['min_withdrawal']} points');
      }

      // Calculate USD amount and fees
      final usdAmount = points * settings.conversionRates['flixbit_to_usd']!;
      final fee = settings.platformFees['withdrawal_fee_flat']!.toInt();
      final totalDeduction = points + fee;

      if (wallet.flixbitPoints < totalDeduction) {
        throw Exception(
            'Insufficient balance. Required: $totalDeduction points (including $fee points withdrawal fee)');
      }

      final newBalance = wallet.flixbitPoints - totalDeduction;

      // Update balance
      await _firestore.collection('wallets').doc(userId).update({
        'balance': newBalance,
        'last_updated': FieldValue.serverTimestamp(),
      });

      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'flixbitBalance': newBalance.toInt(),
      });

      // Create transaction
      final transactionId = _firestore.collection('wallet_transactions').doc().id;
      
      final transaction = WalletTransaction(
        id: transactionId,
        userId: userId,
        type: TransactionType.sell,
        amount: totalDeduction.toDouble(),
        balanceBefore: wallet.flixbitPoints,
        balanceAfter: newBalance,
        source: TransactionSource.purchase,
        referenceId: 'sell_${DateTime.now().millisecondsSinceEpoch}',
        sourceDetails: {
          'payout_method': payoutMethod,
          'usd_amount': usdAmount,
          'points_sold': points,
          'fee': fee,
        },
        status: TransactionStatus.pending,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('wallet_transactions')
          .doc(transaction.id)
          .set(transaction.toFirestore());

      // Send notification
      await _sendNotification(
        userId: userId,
        title: '💸 Withdrawal Requested',
        body: 'Your withdrawal of $points points (\$$usdAmount) is being processed',
        type: 'withdrawal',
      );

      return transaction;
    } catch (e) {
      throw Exception('Failed to sell points: $e');
    }
  }

  /// Get transaction history with optional filters
  static Future<List<WalletTransaction>> getTransactionHistory({
    required String userId,
    int limit = 50,
    TransactionType? type,
    TransactionSource? source,
  }) async {
    try {
      Query query = _firestore
          .collection('wallet_transactions')
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => WalletTransaction.fromFirestore(doc))
          .where((tx) {
            if (type != null && tx.type != type) return false;
            if (source != null && tx.source != source) return false;
            return true;
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get transaction history: $e');
    }
  }

  /// Get daily summary of points earned by source
  static Future<Map<String, num>> getDailySummary(String userId) async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      final snapshot = await _firestore
          .collection('wallet_transactions')
          .where('user_id', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .get();

      final summary = <String, num>{};

      for (var doc in snapshot.docs) {
        final tx = WalletTransaction.fromFirestore(doc);
        
        // Only count earned points
        if (tx.type == TransactionType.earn) {
          final sourceKey = tx.source.toString().split('.').last;
          summary[sourceKey] = (summary[sourceKey] ?? 0) + tx.amount;
        }
      }

      return summary;
    } catch (e) {
      throw Exception('Failed to get daily summary: $e');
    }
  }

  /// Get total balance from user document (quick access)
  static Future<double> getBalance(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      final balance = userDoc.data()?['flixbitBalance'] as int? ?? 0;
      debugPrint("Balance found: $balance");
      return balance.toDouble();
    } catch (e) {
      throw Exception('Failed to get balance: $e');
    }
  }

  /// Get wallet settings (admin controlled)
  static Future<WalletSettings> getSettings() async {
    try {
      final doc = await _firestore
          .collection('wallet_settings')
          .doc('global')
          .get();

      if (!doc.exists) {
        // Return default settings
        return WalletSettings.defaults();
      }

      return WalletSettings.fromFirestore(doc);
    } catch (e) {
      // Return defaults on error
      return WalletSettings.defaults();
    }
  }

  /// Update wallet settings (admin only)
  static Future<void> updateSettings(WalletSettings settings) async {
    try {
      await _firestore
          .collection('wallet_settings')
          .doc('global')
          .set(settings.toFirestore());
    } catch (e) {
      throw Exception('Failed to update settings: $e');
    }
  }

  /// Get active multipliers
  Map<String, double> getActiveMultipliers() {
    // Check for weekend bonus
    final now = DateTime.now();
    final multipliers = <String, double>{};

    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      multipliers['weekend_bonus'] = 2.0;
    }

    // Check for happy hour (example: 6 PM - 9 PM)
    if (now.hour >= 18 && now.hour < 21) {
      multipliers['happy_hour'] = 1.5;
    }

    return multipliers;
  }

  /// Get affordable rewards for user based on their current balance
  static Future<List<Reward>> getAffordableRewards(String userId) async {
    try {
      // Get user's current balance
      final wallet = await getWallet(userId);
      final userBalance = wallet.flixbitPoints;

      // Query rewards that user can afford
      final snapshot = await _firestore
          .collection(FirebaseConstants.rewardsCollection)
          .where('isActive', isEqualTo: true)
          .where('pointsCost', isLessThanOrEqualTo: userBalance)
          .where('stockQuantity', isGreaterThan: 0)
          .orderBy('pointsCost', descending: false) // Cheapest first
          .limit(20) // Limit to prevent too many results
          .get();

      return snapshot.docs
          .map((doc) => Reward.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting affordable rewards: $e');
      return [];
    }
  }

  /// Get rewards within a specific price range
  static Future<List<Reward>> getRewardsInRange({
    required String userId,
    required int minPoints,
    required int maxPoints,
  }) async {
    try {
      // Get user's current balance to ensure they can afford the rewards
      final wallet = await getWallet(userId);
      final userBalance = wallet.flixbitPoints;

      // Adjust maxPoints to user's balance if needed
      final adjustedMaxPoints = maxPoints > userBalance ? userBalance : maxPoints;

      if (adjustedMaxPoints < minPoints) {
        return []; // User can't afford any rewards in this range
      }

      final snapshot = await _firestore
          .collection(FirebaseConstants.rewardsCollection)
          .where('isActive', isEqualTo: true)
          .where('pointsCost', isGreaterThanOrEqualTo: minPoints)
          .where('pointsCost', isLessThanOrEqualTo: adjustedMaxPoints)
          .where('stockQuantity', isGreaterThan: 0)
          .orderBy('pointsCost', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Reward.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting rewards in range: $e');
      return [];
    }
  }

  /// Get recommended rewards based on user's balance and preferences
  static Future<List<Reward>> getRecommendedRewards(String userId) async {
    try {
      // Get user's current balance
      final wallet = await getWallet(userId);
      final userBalance = wallet.flixbitPoints;

      if (userBalance <= 0) {
        return [];
      }

      // Get rewards that are 50-80% of user's balance (good value)
      final minPoints = (userBalance * 0.5).round();
      final maxPoints = (userBalance * 0.8).round();

      final snapshot = await _firestore
          .collection(FirebaseConstants.rewardsCollection)
          .where('isActive', isEqualTo: true)
          .where('pointsCost', isGreaterThanOrEqualTo: minPoints)
          .where('pointsCost', isLessThanOrEqualTo: maxPoints)
          .where('stockQuantity', isGreaterThan: 0)
          .orderBy('pointsCost', descending: false)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => Reward.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting recommended rewards: $e');
      return [];
    }
  }

  /// Send notification helper
  static Future<void> _sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Don't throw error if notification fails
      debugPrint('Failed to send notification: $e');
    }
  }
}
