import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/points_config.dart';
import '../models/flixbit_transaction_model.dart';
import '../res/firebase_constants.dart';
import 'flixbit_points_manager.dart';
import 'wallet_service.dart';

class ReferralService {
  // Singleton pattern
  static final ReferralService _instance = ReferralService._internal();
  factory ReferralService() => _instance;
  ReferralService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WalletService _walletService = WalletService();

  /// Generate referral code for user
  Future<String> generateReferralCode(String userId) async {
    try {
      // Get user's name or username
      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userName = userDoc.data()?['name'] as String? ?? '';
      final code = _generateCode(userName);

      // Save referral code
      await _firestore
          .collection('referral_codes')
          .doc(userId)
          .set({
            'code': code,
            'userId': userId,
            'createdAt': FieldValue.serverTimestamp(),
            'totalReferrals': 0,
            'activeReferrals': 0,
            'pointsEarned': 0,
          });

      return code;
    } catch (e) {
      debugPrint('Error generating referral code: $e');
      rethrow;
    }
  }

  /// Get user's referral code
  Future<String?> getReferralCode(String userId) async {
    try {
      final doc = await _firestore
          .collection('referral_codes')
          .doc(userId)
          .get();

      return doc.data()?['code'] as String?;
    } catch (e) {
      debugPrint('Error getting referral code: $e');
      return null;
    }
  }

  /// Apply referral code during signup
  Future<void> applyReferralCode(String code, String newUserId) async {
    try {
      // Find referrer
      final referralQuery = await _firestore
          .collection('referral_codes')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (referralQuery.docs.isEmpty) {
        throw Exception('Invalid referral code');
      }

      final referrerId = referralQuery.docs.first.data()['userId'] as String;

      // Check if user already used a referral code
      final existingRef = await _firestore
          .collection('referrals')
          .where('referredId', isEqualTo: newUserId)
          .limit(1)
          .get();

      if (existingRef.docs.isNotEmpty) {
        throw Exception('You have already used a referral code');
      }

      // Create referral record
      final referralRef = _firestore.collection('referrals').doc();
      await referralRef.set({
        'id': referralRef.id,
        'referrerId': referrerId,
        'referredId': newUserId,
        'code': code,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'qualifiedAt': null,
        'pointsAwarded': false,
      });

      // Update referrer's stats
      await _firestore
          .collection('referral_codes')
          .doc(referrerId)
          .update({
            'totalReferrals': FieldValue.increment(1),
          });
    } catch (e) {
      debugPrint('Error applying referral code: $e');
      rethrow;
    }
  }

  /// Award points for successful referral
  Future<void> awardReferralPoints(String referralId) async {
    try {
      final referralDoc = await _firestore
          .collection('referrals')
          .doc(referralId)
          .get();

      if (!referralDoc.exists) {
        throw Exception('Referral not found');
      }

      final data = referralDoc.data()!;
      if (data['pointsAwarded'] == true) {
        throw Exception('Points already awarded for this referral');
      }

      final referrerId = data['referrerId'] as String;
      final referredId = data['referredId'] as String;

      // Award points to referrer
      await FlixbitPointsManager.awardPoints(
        userId: referrerId,
        pointsEarned: PointsConfig.getPoints('referral'),
        source: TransactionSource.referral,
        description: 'Referral bonus',
        metadata: {
          'referralId': referralId,
          'referredId': referredId,
        },
      );

      // Award welcome bonus to referred user
      await FlixbitPointsManager.awardPoints(
        userId: referredId,
        pointsEarned: PointsConfig.getPoints('referral_welcome'),
        source: TransactionSource.referral,
        description: 'Welcome bonus',
        metadata: {
          'referralId': referralId,
          'referrerId': referrerId,
        },
      );

      // Update referral status
      await referralDoc.reference.update({
        'pointsAwarded': true,
        'status': 'completed',
        'qualifiedAt': FieldValue.serverTimestamp(),
      });

      // Update referrer's stats
      await _firestore
          .collection('referral_codes')
          .doc(referrerId)
          .update({
            'activeReferrals': FieldValue.increment(1),
            'pointsEarned': FieldValue.increment(PointsConfig.getPoints('referral')),
          });
    } catch (e) {
      debugPrint('Error awarding referral points: $e');
      rethrow;
    }
  }

  /// Get user's referral statistics
  Stream<Map<String, dynamic>> getReferralStats(String userId) {
    return _firestore
        .collection('referral_codes')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }

  /// Get user's referral history
  Stream<List<Map<String, dynamic>>> getReferralHistory(String userId) {
    return _firestore
        .collection('referrals')
        .where('referrerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList());
  }

  /// Get referred users
  Future<List<Map<String, dynamic>>> getReferredUsers(String userId) async {
    try {
      final referrals = await _firestore
          .collection('referrals')
          .where('referrerId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      final userIds = referrals.docs
          .map((doc) => doc.data()['referredId'] as String)
          .toList();

      if (userIds.isEmpty) return [];

      final users = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .where(FieldPath.documentId, whereIn: userIds)
          .get();

      return users.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc.data()['name'] ?? '',
                'avatar': doc.data()['avatar'],
                'referralId': referrals.docs
                    .firstWhere((r) => r.data()['referredId'] == doc.id)
                    .id,
              })
          .toList();
    } catch (e) {
      debugPrint('Error getting referred users: $e');
      return [];
    }
  }

  /// Generate unique referral code
  String _generateCode(String userName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp % 10000;
    final prefix = userName.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    final code = '${prefix.substring(0, prefix.length.clamp(2, 4))}$random';
    return code;
  }
}
