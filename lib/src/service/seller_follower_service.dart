import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/seller_model.dart';
import '../models/seller_follower_model.dart';
import '../res/firebase_constants.dart';

class SellerFollowerService {
  // Singleton pattern
  static final SellerFollowerService _instance = SellerFollowerService._internal();
  factory SellerFollowerService() => _instance;
  SellerFollowerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Follow a seller
  Future<void> followSeller({
    required String userId,
    required String sellerId,
    required String source,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Check if already following
      final existingFollow = await _getFollowerRecord(userId, sellerId);
      
      if (existingFollow != null) {
        debugPrint('User $userId already follows seller $sellerId');
        return;
      }

      // Create follower record
      final followerRef = _firestore.collection(FirebaseConstants.sellerFollowersCollection).doc();
      final follower = SellerFollower(
        id: followerRef.id,
        userId: userId,
        sellerId: sellerId,
        followedAt: DateTime.now(),
        followSource: source,
        notificationsEnabled: true,
        metadata: metadata,
      );

      await followerRef.set(follower.toJson());

      // Update seller's follower count
      await _updateFollowerCount(sellerId);

      debugPrint('User $userId now follows seller $sellerId via $source');
    } catch (e) {
      debugPrint('Error following seller: $e');
      rethrow;
    }
  }

  /// Unfollow a seller
  Future<void> unfollowSeller(String userId, String sellerId) async {
    try {
      final followerDoc = await _getFollowerRecord(userId, sellerId);
      
      if (followerDoc == null) {
        debugPrint('User $userId does not follow seller $sellerId');
        return;
      }

      // Delete follower record
      await _firestore
          .collection(FirebaseConstants.sellerFollowersCollection)
          .doc(followerDoc.id)
          .delete();

      // Update seller's follower count
      await _updateFollowerCount(sellerId);

      debugPrint('User $userId unfollowed seller $sellerId');
    } catch (e) {
      debugPrint('Error unfollowing seller: $e');
      rethrow;
    }
  }

  /// Toggle follow/unfollow
  Future<bool> toggleFollow(String userId, String sellerId, String source) async {
    final isCurrentlyFollowing = await isFollowing(userId, sellerId);
    
    if (isCurrentlyFollowing) {
      await unfollowSeller(userId, sellerId);
      return false;
    } else {
      await followSeller(userId: userId, sellerId: sellerId, source: source);
      return true;
    }
  }

  /// Check if user is following a seller
  Future<bool> isFollowing(String userId, String sellerId) async {
    try {
      final follower = await _getFollowerRecord(userId, sellerId);
      return follower != null;
    } catch (e) {
      debugPrint('Error checking follow status: $e');
      return false;
    }
  }

  /// Get follower record
  Future<SellerFollower?> _getFollowerRecord(String userId, String sellerId) async {
    try {
      final query = await _firestore
          .collection(FirebaseConstants.sellerFollowersCollection)
          .where('userId', isEqualTo: userId)
          .where('sellerId', isEqualTo: sellerId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      return SellerFollower.fromJson(query.docs.first.data());
    } catch (e) {
      debugPrint('Error getting follower record: $e');
      return null;
    }
  }

  /// Get list of sellers that a user follows
  Stream<List<Seller>> getFollowedSellers(String userId) {
    return _firestore
        .collection(FirebaseConstants.sellerFollowersCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('followedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return <Seller>[];

      // Get seller IDs
      final sellerIds = snapshot.docs
          .map((doc) => doc.data()['sellerId'] as String)
          .toList();

      // Fetch seller details
      final sellers = <Seller>[];
      for (final sellerId in sellerIds) {
        try {
          final sellerDoc = await _firestore
              .collection(FirebaseConstants.sellersCollection)
              .doc(sellerId)
              .get();

          if (sellerDoc.exists) {
            sellers.add(Seller.fromJson(sellerDoc.data()!));
          }
        } catch (e) {
          debugPrint('Error fetching seller $sellerId: $e');
        }
      }

      return sellers;
    });
  }

  /// Get list of users following a seller
  Stream<List<SellerFollower>> getSellerFollowers(String sellerId) {
    return _firestore
        .collection(FirebaseConstants.sellerFollowersCollection)
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('followedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SellerFollower.fromJson(doc.data()))
            .toList());
  }

  /// Update seller's follower count
  Future<void> _updateFollowerCount(String sellerId) async {
    try {
      final count = await _firestore
          .collection(FirebaseConstants.sellerFollowersCollection)
          .where('sellerId', isEqualTo: sellerId)
          .count()
          .get();

      await _firestore
          .collection(FirebaseConstants.sellersCollection)
          .doc(sellerId)
          .update({
        'followersCount': count.count ?? 0,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating follower count: $e');
      // Don't rethrow - count update is not critical
    }
  }

  /// Get follower count for a seller
  Future<int> getFollowerCount(String sellerId) async {
    try {
      final count = await _firestore
          .collection(FirebaseConstants.sellerFollowersCollection)
          .where('sellerId', isEqualTo: sellerId)
          .count()
          .get();

      return count.count ?? 0;
    } catch (e) {
      debugPrint('Error getting follower count: $e');
      return 0;
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreference({
    required String userId,
    required String sellerId,
    required bool enabled,
  }) async {
    try {
      final follower = await _getFollowerRecord(userId, sellerId);
      
      if (follower == null) {
        throw Exception('Not following this seller');
      }

      await _firestore
          .collection(FirebaseConstants.sellerFollowersCollection)
          .doc(follower.id)
          .update({'notificationsEnabled': enabled});

      debugPrint('Updated notification preference for seller $sellerId: $enabled');
    } catch (e) {
      debugPrint('Error updating notification preference: $e');
      rethrow;
    }
  }

  /// Get followers by source
  Future<List<SellerFollower>> getFollowersBySource(String sellerId, String source) async {
    try {
      final query = await _firestore
          .collection(FirebaseConstants.sellerFollowersCollection)
          .where('sellerId', isEqualTo: sellerId)
          .where('followSource', isEqualTo: source)
          .get();

      return query.docs
          .map((doc) => SellerFollower.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting followers by source: $e');
      return [];
    }
  }

  /// Get follower analytics
  Future<Map<String, dynamic>> getFollowerAnalytics(String sellerId) async {
    try {
      final followers = await _firestore
          .collection(FirebaseConstants.sellerFollowersCollection)
          .where('sellerId', isEqualTo: sellerId)
          .get();

      final bySource = <String, int>{};
      final byMonth = <String, int>{};
      int withNotifications = 0;

      for (final doc in followers.docs) {
        final follower = SellerFollower.fromJson(doc.data());

        // Count by source
        bySource[follower.followSource] = (bySource[follower.followSource] ?? 0) + 1;

        // Count by month
        final month = '${follower.followedAt.year}-${follower.followedAt.month.toString().padLeft(2, '0')}';
        byMonth[month] = (byMonth[month] ?? 0) + 1;

        // Count notifications enabled
        if (follower.notificationsEnabled) {
          withNotifications++;
        }
      }

      return {
        'totalFollowers': followers.size,
        'bySource': bySource,
        'byMonth': byMonth,
        'withNotifications': withNotifications,
        'notificationRate': followers.size > 0 
            ? (withNotifications / followers.size * 100).toStringAsFixed(1) + '%'
            : '0%',
      };
    } catch (e) {
      debugPrint('Error getting follower analytics: $e');
      return {};
    }
  }
}

