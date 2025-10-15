import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/points_config.dart';
import '../models/wallet_models.dart';
import '../res/firebase_constants.dart';

class FlixbitPointsManager {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Earning rates configuration from PointsConfig
  static Map<TransactionSource, int> get earningRates {
    return {
      TransactionSource.tournamentPrediction: PointsConfig.getPoints('tournament_prediction'),
      TransactionSource.tournamentQualification: PointsConfig.getPoints('tournament_qualification'),
      TransactionSource.tournamentWin: PointsConfig.getPoints('tournament_win'),
      TransactionSource.videoAd: PointsConfig.getPoints('video_ad'),
      TransactionSource.referral: PointsConfig.getPoints('referral'),
      TransactionSource.review: PointsConfig.getPoints('review'),
      TransactionSource.qrScan: PointsConfig.getPoints('qr_scan'),
      TransactionSource.dailyLogin: PointsConfig.getPoints('daily_login'),
    };
  }

  /// Award points to user wallet
  static Future<void> awardPoints({
    required String userId,
    required int pointsEarned,
    required TransactionSource source,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Get current user balance
      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      final currentBalance = userDoc.data()?['flixbitBalance'] as int? ?? 0;
      final newBalance = currentBalance + pointsEarned;

      // Update user balance
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({
        'flixbitBalance': newBalance,
        'totalPointsEarned': FieldValue.increment(pointsEarned),
      });

      // Create transaction record using WalletTransaction model
      final transactionId = _firestore
          .collection('wallet_transactions')
          .doc()
          .id;
      
      final transaction = WalletTransaction(
        id: transactionId,
        userId: userId,
        type: TransactionType.earn,
        amount: pointsEarned.toDouble(),
        balanceBefore: currentBalance.toDouble(),
        balanceAfter: newBalance.toDouble(),
        source: source,
        referenceId: metadata?['tournamentId'] ?? metadata?['matchId'],
        sourceDetails: metadata,
        status: TransactionStatus.completed,
        timestamp: DateTime.now(),
        metadata: {'description': description},
      );

      await _firestore
          .collection('wallet_transactions')
          .doc(transaction.id)
          .set(transaction.toFirestore());
      
      // Update tournament points tracking if from tournament source
      if (_isTournamentSource(source)) {
        await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(userId)
            .update({
          'tournamentPointsEarned': FieldValue.increment(pointsEarned),
        });
      }

      // Send notification
      await _sendPointsNotification(
        userId: userId,
        amount: pointsEarned,
        isEarned: true,
        description: description,
      );
    } catch (e) {
      throw Exception('Failed to award points: $e');
    }
  }

  /// Deduct points from user wallet
  static Future<bool> deductPoints({
    required String userId,
    required int amount,
    required TransactionSource source,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Check if user has sufficient balance
      final hasBalance = await checkBalance(userId, amount);
      if (!hasBalance) {
        throw InsufficientBalanceException(
            'Insufficient balance. Required: $amount points');
      }

      // Get current balance
      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      final currentBalance = userDoc.data()?['flixbitBalance'] as int? ?? 0;
      final newBalance = currentBalance - amount;

      // Update user balance
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({
        'flixbitBalance': newBalance,
      });

      // Create transaction record using WalletTransaction model
      final transactionId = _firestore
          .collection('wallet_transactions')
          .doc()
          .id;
      
      final transaction = WalletTransaction(
        id: transactionId,
        userId: userId,
        type: TransactionType.spend,
        amount: amount.toDouble(),
        balanceBefore: currentBalance.toDouble(),
        balanceAfter: newBalance.toDouble(),
        source: source,
        referenceId: metadata?['tournamentId'] ?? metadata?['offerId'],
        sourceDetails: metadata,
        status: TransactionStatus.completed,
        timestamp: DateTime.now(),
        metadata: {'description': description},
      );

      await _firestore
          .collection('wallet_transactions')
          .doc(transaction.id)
          .set(transaction.toFirestore());

      return true;
    } catch (e) {
      if (e is InsufficientBalanceException) rethrow;
      throw Exception('Failed to deduct points: $e');
    }
  }

  /// Check if user has sufficient balance
  static Future<bool> checkBalance(String userId, int requiredAmount) async {
    try {
      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      final balance = userDoc.data()?['flixbitBalance'] as int? ?? 0;
      return balance >= requiredAmount;
    } catch (e) {
      throw Exception('Failed to check balance: $e');
    }
  }

  /// Get user's current balance
  static Future<int> getUserBalance(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      return userDoc.data()?['flixbitBalance'] as int? ?? 0;
    } catch (e) {
      throw Exception('Failed to get user balance: $e');
    }
  }

  /// Get user's transaction history
  static Future<List<WalletTransaction>> getTransactionHistory({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('wallet_transactions')
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => WalletTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get transaction history: $e');
    }
  }

  /// Charge tournament entry fee
  static Future<bool> chargeTournamentEntry({
    required String userId,
    required String tournamentId,
    required String tournamentName,
    required int entryFee,
  }) async {
    return await deductPoints(
      userId: userId,
      amount: entryFee,
      source: TransactionSource.tournamentEntry,
      description: 'Tournament entry fee: $tournamentName',
      metadata: {
        'tournamentId': tournamentId,
        'tournamentName': tournamentName,
      },
    );
  }

  /// Purchase qualification points
  static Future<void> purchaseQualificationPoints({
    required String userId,
    required String tournamentId,
    required int pointsNeeded,
  }) async {
    // Cost: 1 tournament point = 5 Flixbit points
    final cost = pointsNeeded * 5;

    await deductPoints(
      userId: userId,
      amount: cost,
      source: TransactionSource.tournamentEntry,
      description: 'Purchased $pointsNeeded qualification points',
      metadata: {
        'tournamentId': tournamentId,
        'pointsPurchased': pointsNeeded,
      },
    );
  }

  /// Refund entry fee (for tournament cancellation)
  static Future<void> refundTournamentEntry({
    required String userId,
    required String tournamentId,
    required int amount,
  }) async {
    try {
      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      final currentBalance = userDoc.data()?['flixbitBalance'] as int? ?? 0;
      final newBalance = currentBalance + amount;

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({
        'flixbitBalance': newBalance,
      });

      // Create refund transaction using WalletTransaction model
      final transactionId = _firestore
          .collection('wallet_transactions')
          .doc()
          .id;
      
      final transaction = WalletTransaction(
        id: transactionId,
        userId: userId,
        type: TransactionType.refund,
        amount: amount.toDouble(),
        balanceBefore: currentBalance.toDouble(),
        balanceAfter: newBalance.toDouble(),
        source: TransactionSource.refund,
        referenceId: tournamentId,
        sourceDetails: {'tournamentId': tournamentId},
        status: TransactionStatus.completed,
        timestamp: DateTime.now(),
        metadata: {'description': 'Tournament entry fee refund'},
      );

      await _firestore
          .collection('wallet_transactions')
          .doc(transaction.id)
          .set(transaction.toFirestore());
    } catch (e) {
      throw Exception('Failed to refund entry fee: $e');
    }
  }

  /// Check if transaction source is tournament-related
  static bool _isTournamentSource(TransactionSource source) {
    return [
      TransactionSource.tournamentPrediction,
      TransactionSource.tournamentQualification,
      TransactionSource.tournamentWin,
    ].contains(source);
  }

  /// Send notification about points transaction
  static Future<void> _sendPointsNotification({
    required String userId,
    required int amount,
    required bool isEarned,
    required String description,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .add({
        'userId': userId,
        'title': isEarned ? '🎉 Points Earned!' : '💳 Points Used',
        'body': isEarned
            ? 'You earned $amount Flixbit points! $description'
            : 'You spent $amount Flixbit points. $description',
        'type': 'points',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {
          'amount': amount,
          'isEarned': isEarned,
        },
      });
    } catch (e) {
      // Don't throw error if notification fails
      print('Failed to send notification: $e');
    }
  }
}

/// Custom exception for insufficient balance
class InsufficientBalanceException implements Exception {
  final String message;
  InsufficientBalanceException(this.message);

  @override
  String toString() => message;
}

