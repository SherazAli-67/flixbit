import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/video_analytics.dart';
import '../res/firebase_constants.dart';

class VideoAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Track a video view (prevents duplicate views per user per day)
  Future<void> trackView({
    required String videoId,
    required String userId,
    String? region,
  }) async {
    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final viewLogId = '${videoId}_${userId}_$dateKey';

      // Check if already viewed today
      final viewLogRef = _firestore
          .collection(FirebaseConstants.videoAdsCollection)
          .doc(videoId)
          .collection('view_logs')
          .doc(viewLogId);

      final viewLog = await viewLogRef.get();

      if (!viewLog.exists) {
        // Record the view
        await viewLogRef.set({
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
          'region': region,
          'dateKey': dateKey,
        });

        // Update analytics counters
        final analyticsRef = _firestore
            .collection(FirebaseConstants.videoAnalyticsCollection)
            .doc(videoId);

        await _firestore.runTransaction((transaction) async {
          final analyticsDoc = await transaction.get(analyticsRef);

          if (analyticsDoc.exists) {
            final data = analyticsDoc.data()!;
            final viewsByRegion = Map<String, int>.from(data['viewsByRegion'] ?? {});
            final viewsByDate = Map<String, int>.from(data['viewsByDate'] ?? {});

            // Update region count
            if (region != null) {
              viewsByRegion[region] = (viewsByRegion[region] ?? 0) + 1;
            }

            // Update date count
            viewsByDate[dateKey] = (viewsByDate[dateKey] ?? 0) + 1;

            transaction.update(analyticsRef, {
              'totalViews': FieldValue.increment(1),
              'uniqueViewers': FieldValue.increment(1),
              'viewsByRegion': viewsByRegion,
              'viewsByDate': viewsByDate,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error tracking view: $e');
    }
  }

  /// Track watch time for a video
  Future<void> trackWatchTime({
    required String videoId,
    required String userId,
    required int watchedSeconds,
  }) async {
    try {
      final analyticsRef = _firestore
          .collection(FirebaseConstants.videoAnalyticsCollection)
          .doc(videoId);

      final analyticsDoc = await analyticsRef.get();

      if (analyticsDoc.exists) {
        final data = analyticsDoc.data()!;
        final totalWatchTime = (data['totalWatchTimeSeconds'] as int?) ?? 0;
        final uniqueViewers = (data['uniqueViewers'] as int?) ?? 1;

        // Calculate new average
        final newTotalWatchTime = totalWatchTime + watchedSeconds;
        final newAverageWatchTime = newTotalWatchTime / uniqueViewers;

        await analyticsRef.update({
          'totalWatchTimeSeconds': newTotalWatchTime,
          'averageWatchTimeSeconds': newAverageWatchTime,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error tracking watch time: $e');
    }
  }

  /// Track video completion
  Future<void> trackCompletion({
    required String videoId,
    required String userId,
  }) async {
    try {
      final analyticsRef = _firestore
          .collection(FirebaseConstants.videoAnalyticsCollection)
          .doc(videoId);

      final analyticsDoc = await analyticsRef.get();

      if (analyticsDoc.exists) {
        final data = analyticsDoc.data()!;
        final totalViews = (data['totalViews'] as int?) ?? 1;
        final completions = ((data['completionRate'] as double?) ?? 0.0) * totalViews / 100;

        // Calculate new completion rate
        final newCompletions = completions + 1;
        final newCompletionRate = (newCompletions / totalViews) * 100;

        await analyticsRef.update({
          'completionRate': newCompletionRate,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error tracking completion: $e');
    }
  }

  /// Track engagement actions (like, dislike, vote, share)
  Future<void> trackEngagement({
    required String videoId,
    required String userId,
    required String actionType, // 'like', 'dislike', 'vote', 'share'
  }) async {
    try {
      final analyticsRef = _firestore
          .collection(FirebaseConstants.videoAnalyticsCollection)
          .doc(videoId);

      Map<String, dynamic> updates = {
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      switch (actionType) {
        case 'like':
          updates['likesCount'] = FieldValue.increment(1);
          break;
        case 'dislike':
          updates['dislikesCount'] = FieldValue.increment(1);
          break;
        case 'vote':
          updates['votesCount'] = FieldValue.increment(1);
          break;
        case 'share':
          updates['sharesCount'] = FieldValue.increment(1);
          break;
      }

      await analyticsRef.update(updates);

      // Recalculate engagement rate
      await _updateEngagementRate(videoId);
    } catch (e) {
      debugPrint('Error tracking engagement: $e');
    }
  }

  /// Update engagement rate calculation
  Future<void> _updateEngagementRate(String videoId) async {
    try {
      final analyticsDoc = await _firestore
          .collection(FirebaseConstants.videoAnalyticsCollection)
          .doc(videoId)
          .get();

      if (analyticsDoc.exists) {
        final data = analyticsDoc.data()!;
        final totalViews = (data['totalViews'] as int?) ?? 1;
        final likes = (data['likesCount'] as int?) ?? 0;
        final votes = (data['votesCount'] as int?) ?? 0;
        final shares = (data['sharesCount'] as int?) ?? 0;

        final totalEngagements = likes + votes + shares;
        final engagementRate = totalViews > 0 ? (totalEngagements / totalViews) * 100 : 0.0;

        await analyticsDoc.reference.update({
          'engagementRate': engagementRate,
        });
      }
    } catch (e) {
      debugPrint('Error updating engagement rate: $e');
    }
  }

  /// Get video analytics
  Future<VideoAnalytics?> getVideoAnalytics(String videoId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.videoAnalyticsCollection)
          .doc(videoId)
          .get();

      if (!doc.exists) return null;

      return VideoAnalytics.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Error getting video analytics: $e');
      return null;
    }
  }

  /// Get all analytics for a seller's videos
  Future<List<VideoAnalytics>> getSellerAnalytics(String sellerId) async {
    try {
      // First, get all video IDs for this seller
      final videosSnapshot = await _firestore
          .collection(FirebaseConstants.videoAdsCollection)
          .where('uploadedBy', isEqualTo: sellerId)
          .get();

      final videoIds = videosSnapshot.docs.map((doc) => doc.id).toList();

      if (videoIds.isEmpty) return [];

      // Then fetch analytics for those videos
      final List<VideoAnalytics> analyticsList = [];

      // Fetch in chunks of 10 (Firestore 'in' query limit)
      for (int i = 0; i < videoIds.length; i += 10) {
        final chunk = videoIds.skip(i).take(10).toList();
        final analyticsSnapshot = await _firestore
            .collection(FirebaseConstants.videoAnalyticsCollection)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        analyticsList.addAll(
          analyticsSnapshot.docs.map(
            (doc) => VideoAnalytics.fromFirestore(doc.data(), doc.id),
          ),
        );
      }

      return analyticsList;
    } catch (e) {
      debugPrint('Error getting seller analytics: $e');
      return [];
    }
  }

  /// Get top performing videos for a seller
  Future<List<VideoAnalytics>> getTopVideos(String sellerId, {int limit = 5}) async {
    try {
      final allAnalytics = await getSellerAnalytics(sellerId);

      // Sort by total views
      allAnalytics.sort((a, b) => b.totalViews.compareTo(a.totalViews));

      return allAnalytics.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting top videos: $e');
      return [];
    }
  }

  /// Get recent videos for a seller
  Future<List<VideoAnalytics>> getRecentVideos(String sellerId, {int limit = 10}) async {
    try {
      final allAnalytics = await getSellerAnalytics(sellerId);

      // Sort by last updated
      allAnalytics.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

      return allAnalytics.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting recent videos: $e');
      return [];
    }
  }

  /// Calculate aggregate stats for a seller
  Future<Map<String, dynamic>> getAggregateStats(String sellerId) async {
    try {
      final analytics = await getSellerAnalytics(sellerId);

      int totalViews = 0;
      int totalWatchTime = 0;
      int totalRewards = 0;
      double avgEngagement = 0.0;

      for (final analytic in analytics) {
        totalViews += analytic.totalViews;
        totalWatchTime += analytic.totalWatchTimeSeconds;
        totalRewards += analytic.rewardsDistributed;
        avgEngagement += analytic.engagementRate;
      }

      if (analytics.isNotEmpty) {
        avgEngagement /= analytics.length;
      }

      return {
        'totalViews': totalViews,
        'totalWatchTime': totalWatchTime,
        'totalRewards': totalRewards,
        'avgEngagement': avgEngagement,
        'videoCount': analytics.length,
      };
    } catch (e) {
      debugPrint('Error calculating aggregate stats: $e');
      return {};
    }
  }

  /// Watch video analytics in real-time
  Stream<VideoAnalytics?> watchVideoAnalytics(String videoId) {
    return _firestore
        .collection(FirebaseConstants.videoAnalyticsCollection)
        .doc(videoId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return VideoAnalytics.fromFirestore(doc.data()!, doc.id);
    });
  }

  /// Watch seller analytics in real-time
  Stream<List<VideoAnalytics>> watchSellerAnalytics(String sellerId) async* {
    // Get video IDs first
    final videosSnapshot = await _firestore
        .collection(FirebaseConstants.videoAdsCollection)
        .where('uploadedBy', isEqualTo: sellerId)
        .get();

    final videoIds = videosSnapshot.docs.map((doc) => doc.id).toList();

    if (videoIds.isEmpty) {
      yield [];
      return;
    }

    // Watch analytics for those videos
    yield* _firestore
        .collection(FirebaseConstants.videoAnalyticsCollection)
        .where(FieldPath.documentId, whereIn: videoIds.take(10).toList())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => VideoAnalytics.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Update aggregate metrics for a video (recalculate everything)
  Future<void> updateAggregateMetrics(String videoId) async {
    try {
      await _updateEngagementRate(videoId);
    } catch (e) {
      debugPrint('Error updating aggregate metrics: $e');
    }
  }
}

