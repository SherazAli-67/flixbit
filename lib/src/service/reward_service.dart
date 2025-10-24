import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/reward_model.dart';
import '../models/reward_redemption_model.dart';
import '../models/wallet_models.dart';
import '../res/firebase_constants.dart';
import 'flixbit_points_manager.dart';

class RewardService {
  // Singleton pattern
  static final RewardService _instance = RewardService._internal();
  factory RewardService() => _instance;
  RewardService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USER OPERATIONS ====================

  /// Get active rewards with optional filtering
  Stream<List<Reward>> getActiveRewards({
    RewardCategory? category,
    RewardType? rewardType,
    String? sortBy, // 'pointsCost', 'createdAt', 'featured'
    int limit = 50,
  }) {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(FirebaseConstants.rewardsCollection)
          .where('isActive', isEqualTo: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }

      if (rewardType != null) {
        query = query.where('rewardType', isEqualTo: rewardType.name);
      }

      // Apply sorting
      switch (sortBy) {
        case 'pointsCost':
          query = query.orderBy('pointsCost', descending: false);
          break;
        case 'createdAt':
          query = query.orderBy('createdAt', descending: true);
          break;
        case 'featured':
          query = query.orderBy('isFeatured', descending: true)
              .orderBy('createdAt', descending: true);
          break;
        default:
          query = query.orderBy('isFeatured', descending: true)
              .orderBy('createdAt', descending: true);
      }

      query = query.limit(limit);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => Reward.fromFirestore(doc))
            .where((reward) => reward.canBeRedeemed)
            .toList();
      });
    } catch (e) {
      debugPrint('Error getting active rewards: $e');
      return Stream.value([]);
    }
  }

  /// Get reward by ID
  Future<Reward?> getRewardById(String rewardId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.rewardsCollection)
          .doc(rewardId)
          .get();

      if (!doc.exists) return null;
      return Reward.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting reward by ID: $e');
      return null;
    }
  }

  /// Get affordable rewards for user based on their balance
  Future<List<Reward>> getAffordableRewards(String userId, {int? maxPoints}) async {
    try {
      // Get user's current balance
      final userBalance = await FlixbitPointsManager.getUserBalance(userId);
      final budget = maxPoints ?? userBalance;

      final snapshot = await _firestore
          .collection(FirebaseConstants.rewardsCollection)
          .where('isActive', isEqualTo: true)
          .where('pointsCost', isLessThanOrEqualTo: budget)
          .orderBy('pointsCost', descending: false)
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => Reward.fromFirestore(doc))
          .where((reward) => reward.canBeRedeemed)
          .toList();
    } catch (e) {
      debugPrint('Error getting affordable rewards: $e');
      return [];
    }
  }

  /// Redeem a reward
  Future<RewardRedemption?> redeemReward({
    required String userId,
    required String rewardId,
    DeliveryAddress? deliveryAddress,
  }) async {
    try {
      // STEP 1: Get reward details
      final reward = await getRewardById(rewardId);
      if (reward == null) {
        throw Exception('Reward not found');
      }

      // STEP 2: Check basic availability
      if (!reward.canBeRedeemed) {
        throw Exception('Reward is not available: ${reward.stockStatus}');
      }

      // STEP 3: Check user balance
      final userBalance = await FlixbitPointsManager.getUserBalance(userId);
      if (userBalance < reward.pointsCost) {
        throw Exception('Insufficient points. Required: ${reward.pointsCost}, Available: $userBalance');
      }

      // STEP 4: Check user redemption limit
      if (reward.maxRedemptionsPerUser != null) {
        final userRedemptions = await _getUserRedemptionCount(userId, rewardId);
        if (userRedemptions >= reward.maxRedemptionsPerUser!) {
          throw Exception('You have reached the maximum redemption limit for this reward');
        }
      }

      // STEP 5: Reserve stock (ATOMIC)
      final reserved = await reserveStock(rewardId, userId);
      if (!reserved) {
        throw Exception('Unable to reserve reward. It may be out of stock.');
      }

      try {
        // STEP 6: Deduct points (ATOMIC)
        final deducted = await FlixbitPointsManager.deductPoints(
          userId: userId,
          amount: reward.pointsCost,
          source: TransactionSource.reward,
          description: 'Redeemed: ${reward.title}',
          metadata: {
            'rewardId': rewardId,
            'rewardType': reward.rewardType.name,
            'category': reward.category.name,
          },
        );

        if (!deducted) {
          // Rollback: Release stock if points deduction failed
          await releaseStock(rewardId, userId);
          throw Exception('Failed to deduct points');
        }

        // STEP 7: Create redemption record
        final redemptionRef = _firestore
            .collection(FirebaseConstants.rewardRedemptionsCollection)
            .doc();

        final redemptionCode = _generateRedemptionCode(reward.category);
        final expiresAt = reward.rewardType == RewardType.digital
            ? DateTime.now().add(Duration(days: 30))
            : null;

        final redemption = RewardRedemption(
          id: redemptionRef.id,
          userId: userId,
          rewardId: rewardId,
          pointsSpent: reward.pointsCost,
          redemptionCode: redemptionCode,
          redeemedAt: DateTime.now(),
          expiresAt: expiresAt,
          status: RedemptionStatus.active,
          qrCodeData: _generateQRCode(redemptionRef.id),
          deliveryAddress: deliveryAddress,
        );

        await redemptionRef.set(redemption.toFirestore());

        // STEP 8: Mark reservation as completed
        await _markReservationCompleted(userId, rewardId, redemption.id);

        /*
         * CLOUD FUNCTION TRIGGER: onRewardRedemption
         * 
         * Firestore Trigger: onCreate on /reward_redemptions/{redemptionId}
         * 
         * Function Logic:
         * 1. Read redemption document to get userId and rewardId
         * 2. Fetch reward details from /rewards/{rewardId}
         * 3. Get user's FCM token(s) from /users/{userId}
         * 4. Send FCM push notification:
         *    Title: "🎉 Reward Redeemed!"
         *    Body: "You've redeemed [reward.title] for [pointsSpent] points"
         *    Data: {
         *      type: "reward_redemption",
         *      redemptionId: redemptionId,
         *      rewardId: rewardId,
         *      redemptionCode: redemption.redemptionCode,
         *      route: "/my-rewards"
         *    }
         * 5. Create notification document in /notifications collection
         * 6. Handle multi-device: Send to all user's FCM tokens
         * 7. Error handling: Log failed sends, clean up invalid tokens
         */

        // STEP 9: Send notification (local fallback)
        await _sendRedemptionNotification(userId, reward, redemption);

        debugPrint('Reward redeemed successfully: ${reward.title} by user: $userId');
        return redemption;

      } catch (e) {
        // Rollback: Release stock if anything fails after reservation
        await releaseStock(rewardId, userId);
        rethrow;
      }

    } catch (e) {
      debugPrint('Error redeeming reward: $e');
      rethrow;
    }
  }

  /// Get user's redemption history
  Stream<List<RewardRedemption>> getUserRedemptions(String userId) {
    return _firestore
        .collection(FirebaseConstants.rewardRedemptionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('redeemedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RewardRedemption.fromFirestore(doc))
            .toList());
  }

  /// Use a reward (mark as used)
  Future<bool> useReward(String redemptionId) async {
    try {
      final redemptionRef = _firestore
          .collection(FirebaseConstants.rewardRedemptionsCollection)
          .doc(redemptionId);

      return await _firestore.runTransaction<bool>((transaction) async {
        final doc = await transaction.get(redemptionRef);
        
        if (!doc.exists) {
          throw Exception('Redemption not found');
        }

        final redemption = RewardRedemption.fromFirestore(doc);
        
        if (redemption.status != RedemptionStatus.active) {
          throw Exception('Reward is not active. Status: ${redemption.statusText}');
        }

        if (redemption.isExpired) {
          throw Exception('Reward has expired');
        }

        // Update status to used
        transaction.update(redemptionRef, {
          'status': RedemptionStatus.used.name,
          'claimedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      debugPrint('Error using reward: $e');
      return false;
    }
  }

  /// Check reward availability
  Future<bool> checkRewardAvailability(String rewardId) async {
    try {
      final reward = await getRewardById(rewardId);
      return reward?.canBeRedeemed ?? false;
    } catch (e) {
      debugPrint('Error checking reward availability: $e');
      return false;
    }
  }

  // ==================== INVENTORY MANAGEMENT ====================

  /// Check stock availability (read-only)
  Future<bool> checkStock(String rewardId) async {
    try {
      final rewardDoc = await _firestore
          .collection(FirebaseConstants.rewardsCollection)
          .doc(rewardId)
          .get();
      
      if (!rewardDoc.exists) return false;
      
      final reward = Reward.fromFirestore(rewardDoc);
      return reward.canBeRedeemed;
    } catch (e) {
      debugPrint('Error checking stock: $e');
      return false;
    }
  }

  /// Reserve stock for user (ATOMIC)
  Future<bool> reserveStock(String rewardId, String userId) async {
    try {
      final rewardRef = _firestore.collection(FirebaseConstants.rewardsCollection).doc(rewardId);
      
      // Run as atomic transaction
      return await _firestore.runTransaction<bool>((transaction) async {
        // Read current state
        final rewardDoc = await transaction.get(rewardRef);
        
        if (!rewardDoc.exists) {
          throw Exception('Reward not found');
        }
        
        final currentStock = rewardDoc.data()!['stockQuantity'] as int;
        final redemptionCount = rewardDoc.data()!['redemptionCount'] as int? ?? 0;
        final isActive = rewardDoc.data()!['isActive'] as bool? ?? true;
        
        // Check if stock available and active
        if (!isActive || currentStock <= 0) {
          throw Exception('Out of stock or inactive');
        }
        
        // Atomically decrement stock and increment redemption count
        transaction.update(rewardRef, {
          'stockQuantity': currentStock - 1,
          'redemptionCount': redemptionCount + 1,
          'lastRedemptionAt': FieldValue.serverTimestamp(),
        });
        
        // Create reservation record
        final reservationRef = _firestore
            .collection(FirebaseConstants.rewardReservationsCollection)
            .doc('${userId}_${rewardId}_${DateTime.now().millisecondsSinceEpoch}');
        
        transaction.set(reservationRef, {
          'userId': userId,
          'rewardId': rewardId,
          'reservedAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(
            DateTime.now().add(Duration(minutes: 5))
          ), // 5 min reservation window
          'status': 'reserved',
        });
        
        return true;
      });
    } catch (e) {
      debugPrint('Error reserving stock: $e');
      return false;
    }
  }

  /// Release stock if redemption fails (ATOMIC)
  Future<void> releaseStock(String rewardId, String userId) async {
    try {
      final rewardRef = _firestore.collection(FirebaseConstants.rewardsCollection).doc(rewardId);
      
      // Run as atomic transaction
      await _firestore.runTransaction((transaction) async {
        final rewardDoc = await transaction.get(rewardRef);
        
        if (!rewardDoc.exists) return;
        
        final currentStock = rewardDoc.data()!['stockQuantity'] as int;
        final redemptionCount = rewardDoc.data()!['redemptionCount'] as int? ?? 0;
        
        // Atomically increment stock back
        transaction.update(rewardRef, {
          'stockQuantity': currentStock + 1,
          'redemptionCount': math.max(0, redemptionCount - 1),
        });
        
        // Delete reservation record
        final reservationQuery = await _firestore
            .collection(FirebaseConstants.rewardReservationsCollection)
            .where('userId', isEqualTo: userId)
            .where('rewardId', isEqualTo: rewardId)
            .where('status', isEqualTo: 'reserved')
            .orderBy('reservedAt', descending: true)
            .limit(1)
            .get();
        
        if (reservationQuery.docs.isNotEmpty) {
          transaction.update(reservationQuery.docs.first.reference, {
            'status': 'released',
            'releasedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      
      debugPrint('Stock released for reward: $rewardId');
    } catch (e) {
      debugPrint('Error releasing stock: $e');
      rethrow;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Get user's redemption count for a specific reward
  Future<int> _getUserRedemptionCount(String userId, String rewardId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.rewardRedemptionsCollection)
          .where('userId', isEqualTo: userId)
          .where('rewardId', isEqualTo: rewardId)
          .where('status', whereIn: [
            RedemptionStatus.active.name,
            RedemptionStatus.used.name,
            RedemptionStatus.shipped.name,
            RedemptionStatus.delivered.name,
          ])
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting user redemption count: $e');
      return 0;
    }
  }

  /// Mark reservation as completed
  Future<void> _markReservationCompleted(String userId, String rewardId, String redemptionId) async {
    try {
      final reservationQuery = await _firestore
          .collection(FirebaseConstants.rewardReservationsCollection)
          .where('userId', isEqualTo: userId)
          .where('rewardId', isEqualTo: rewardId)
          .where('status', isEqualTo: 'reserved')
          .orderBy('reservedAt', descending: true)
          .limit(1)
          .get();

      if (reservationQuery.docs.isNotEmpty) {
        await reservationQuery.docs.first.reference.update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'redemptionId': redemptionId,
        });
      }
    } catch (e) {
      debugPrint('Error marking reservation as completed: $e');
    }
  }

  /// Generate unique redemption code
  String _generateRedemptionCode(RewardCategory category) {
    final prefix = category.name.substring(0, 3).toUpperCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    final random = math.Random().nextInt(999).toString().padLeft(3, '0');
    return '$prefix-$timestamp-$random';
  }

  /// Generate QR code data
  String _generateQRCode(String redemptionId) {
    return 'flixbit:reward:$redemptionId:${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Send redemption notification
  Future<void> _sendRedemptionNotification(
    String userId,
    Reward reward,
    RewardRedemption redemption,
  ) async {
    try {
      await _firestore.collection(FirebaseConstants.notificationsCollection).add({
        'userId': userId,
        'title': '🎉 Reward Redeemed!',
        'body': 'You redeemed "${reward.title}" for ${redemption.pointsSpent} points. Code: ${redemption.redemptionCode}',
        'type': 'reward_redemption',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {
          'rewardId': reward.id,
          'redemptionId': redemption.id,
          'redemptionCode': redemption.redemptionCode,
          'pointsSpent': redemption.pointsSpent,
        },
      });
    } catch (e) {
      debugPrint('Error sending redemption notification: $e');
    }
  }

  // ==================== ADMIN OPERATIONS (for future) ====================

  /// Create a new reward (admin only)
  Future<String> createReward(Reward reward) async {
    try {
      final rewardRef = _firestore.collection(FirebaseConstants.rewardsCollection).doc();
      final rewardWithId = reward.copyWith(id: rewardRef.id);
      
      await rewardRef.set(rewardWithId.toFirestore());
      return rewardRef.id;
    } catch (e) {
      debugPrint('Error creating reward: $e');
      rethrow;
    }
  }

  /// Update reward stock
  Future<void> updateStock(String rewardId, int newStock) async {
    try {
      await _firestore
          .collection(FirebaseConstants.rewardsCollection)
          .doc(rewardId)
          .update({
        'stockQuantity': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating stock: $e');
      rethrow;
    }
  }

  /// Mark physical reward as shipped
  Future<void> markAsShipped(String redemptionId, String trackingNumber) async {
    try {
      /*
       * CLOUD FUNCTION TRIGGER: onRewardShipped
       * 
       * Firestore Trigger: onUpdate on /reward_redemptions/{redemptionId}
       * Condition: status changes to 'shipped'
       * 
       * Function Logic:
       * 1. Detect status change from any status to 'shipped'
       * 2. Get user's FCM token(s) from /users/{userId}
       * 3. Send FCM push notification:
       *    Title: "📦 Reward Shipped!"
       *    Body: "Your [reward.title] is on the way! Track: [trackingNumber]"
       *    Data: {
       *      type: "reward_shipped",
       *      redemptionId: redemptionId,
       *      trackingNumber: trackingNumber,
       *      route: "/my-rewards"
       *    }
       * 4. Create notification document in /notifications collection
       * 
       * Similar trigger for 'delivered' status:
       *    Title: "✅ Reward Delivered!"
       *    Body: "Your [reward.title] has been delivered. Enjoy!"
       */

      await _firestore
          .collection(FirebaseConstants.rewardRedemptionsCollection)
          .doc(redemptionId)
          .update({
        'status': RedemptionStatus.shipped.name,
        'trackingNumber': trackingNumber,
        'shippedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking as shipped: $e');
      rethrow;
    }
  }
}
