import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/points_config.dart';
import '../models/video_ad.dart';
import '../models/wallet_models.dart';
import '../res/firebase_constants.dart';
import 'flixbit_points_manager.dart';
import 'wallet_service.dart';

class VideoAdsRepositoryImpl {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<VideoAd>> fetchAds({String? category, String? region}) async {
    try {
      var collection = _firestore.collection(FirebaseConstants.videoAdsCollection);
      var query = collection.where('isActive', isEqualTo: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      if (region != null) {
        query = query.where('region', isEqualTo: region);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return VideoAd(
              id: doc.id,
              title: data['title'],
              mediaUrl: data['mediaUrl'],
              thumbnailUrl: data['thumbnailUrl'],
              durationSeconds: data['durationSeconds'],
              category: data['category'],
              region: data['region'],
              startAt: (data['startAt'] as Timestamp?)?.toDate(),
              endAt: (data['endAt'] as Timestamp?)?.toDate(),
              rewardPoints: data['rewardPoints'] ?? PointsConfig.getPoints('video_ad'),
              rewardCouponId: data['rewardCouponId'],
              minWatchSeconds: data['minWatchSeconds'],
              contestEnabled: data['contestEnabled'] ?? false,
              voteWindowStart: (data['voteWindowStart'] as Timestamp?)?.toDate(),
              voteWindowEnd: (data['voteWindowEnd'] as Timestamp?)?.toDate(),
            );
          })
          .where((ad) => ad.isActiveNow)
          .toList();
    } catch (e) {
      debugPrint('Error fetching video ads: $e');
      rethrow;
    }
  }

  Stream<AdPlaybackRule> getPlaybackRule(String adId) {
    return _firestore
        .collection(FirebaseConstants.videoAdsCollection)
        .doc(adId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        throw Exception('Ad not found');
      }
      final data = doc.data() as Map<String, dynamic>;
      return AdPlaybackRule(data['minWatchSeconds'] as int);
    });
  }

  Future<void> recordProgress(String adId, int watchedSeconds) async {
    try {
      final userId = _getCurrentUserId();
      final engagementRef = _getEngagementRef(adId, userId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(engagementRef);
        final data = doc.exists ? doc.data() as Map<String, dynamic> : null;
        final currentSeconds = data?['watchedSeconds'] as int? ?? 0;

        if (watchedSeconds > currentSeconds) {
          transaction.set(
            engagementRef,
            {
              'adId': adId,
              'userId': userId,
              'watchedSeconds': watchedSeconds,
              'completed': false,
              'rewarded': false,
              'lastUpdated': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      });
    } catch (e) {
      debugPrint('Error recording progress: $e');
      rethrow;
    }
  }

  Future<void> submitRating(String adId, bool thumbsUp) async {
    try {
      final userId = _getCurrentUserId();
      final engagementRef = _getEngagementRef(adId, userId);

      await engagementRef.set({
        'ratedUp': thumbsUp,
        'ratedDown': !thumbsUp,
        'ratedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Award points for rating if not rated before
      final doc = await engagementRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['ratedUp'] == null && data['ratedDown'] == null) {
          await _awardRatingPoints(adId);
        }
      }
    } catch (e) {
      debugPrint('Error submitting rating: $e');
      rethrow;
    }
  }

  Future<RewardResult> claimReward(String adId) async {
    try {
      final userId = _getCurrentUserId();
      final engagementRef = _getEngagementRef(adId, userId);

      // Check if already rewarded
      final doc = await engagementRef.get();
      if (!doc.exists) {
        return const RewardResult(
          success: false,
          message: 'No watch history found',
          pointsAwarded: 0,
        );
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['rewarded'] as bool? ?? false) {
        return const RewardResult(
          success: false,
          message: 'Already claimed reward',
          pointsAwarded: 0,
        );
      }

      // Get ad details
      final adDoc = await _firestore
          .collection(FirebaseConstants.videoAdsCollection)
          .doc(adId)
          .get();

      if (!adDoc.exists) {
        return const RewardResult(
          success: false,
          message: 'Ad not found',
          pointsAwarded: 0,
        );
      }

      final adData = adDoc.data() as Map<String, dynamic>;
      final ad = VideoAd(
        id: adDoc.id,
        title: adData['title'] as String,
        mediaUrl: adData['mediaUrl'] as String,
        durationSeconds: adData['durationSeconds'] as int,
        rewardPoints: (adData['rewardPoints'] as int?) ?? PointsConfig.getPoints('video_ad'),
        minWatchSeconds: adData['minWatchSeconds'] as int,
      );

      // Check watch time
      final watchedSeconds = data['watchedSeconds'] as int? ?? 0;
      if (watchedSeconds < ad.minWatchSeconds) {
        return RewardResult(
          success: false,
          message: 'Watch at least ${ad.minWatchSeconds}s to claim reward',
          pointsAwarded: 0,
        );
      }

      // Check daily limit
      final Map<String, num> dailyStats = await WalletService.getDailySummary(userId);
      final videoPoints = (dailyStats['videoAd'] ?? 0).toInt();
      final dailyLimit = PointsConfig.dailyLimits['video_ad'] ?? 50;

      if (videoPoints >= dailyLimit) {
        return const RewardResult(
          success: false,
          message: 'Daily video points limit reached',
          pointsAwarded: 0,
        );
      }

      // Award points
      await FlixbitPointsManager.awardPoints(
        userId: userId,
        pointsEarned: ad.rewardPoints,
        source: TransactionSource.videoAd,
        description: 'Watched video: ${ad.title}',
        metadata: {
          'adId': adId,
          'watchedSeconds': watchedSeconds,
          'minRequired': ad.minWatchSeconds,
        },
      );

      // Mark as rewarded
      await engagementRef.update({
        'rewarded': true,
        'rewardedAt': FieldValue.serverTimestamp(),
        'completed': true,
      });

      return RewardResult(
        success: true,
        message: 'Reward claimed successfully',
        pointsAwarded: ad.rewardPoints,
        couponId: adData['rewardCouponId'] as String?,
      );
    } catch (e) {
      debugPrint('Error claiming reward: $e');
      rethrow;
    }
  }

  Future<void> submitVote(String adId, bool thumbsUp) async {
    try {
      final userId = _getCurrentUserId();
      final voteRef = _firestore
          .collection(FirebaseConstants.videoAdVotesCollection)
          .doc('${adId}_$userId');

      await voteRef.set({
        'adId': adId,
        'userId': userId,
        'thumbsUp': thumbsUp,
        'votedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error submitting vote: $e');
      rethrow;
    }
  }

  // Helper methods
  String _getCurrentUserId() {
    // TODO: Get from auth service
    return 'currentUser';
  }

  DocumentReference _getEngagementRef(String adId, String userId) {
    return _firestore
        .collection(FirebaseConstants.videoAdEngagementsCollection)
        .doc('${adId}_$userId');
  }

  Future<void> _awardRatingPoints(String adId) async {
    try {
      final userId = _getCurrentUserId();
      final ratingPoints = PointsConfig.getPoints('video_ad_rating');

      await FlixbitPointsManager.awardPoints(
        userId: userId,
        pointsEarned: ratingPoints,
        source: TransactionSource.videoAd,
        description: 'Rated video ad',
        metadata: {
          'adId': adId,
          'type': 'rating',
        },
      );
    } catch (e) {
      debugPrint('Error awarding rating points: $e');
      // Don't rethrow - rating points are bonus
    }
  }
}
