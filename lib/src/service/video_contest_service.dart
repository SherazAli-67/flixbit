import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/video_contest.dart';
import '../models/contest_winner.dart';
import '../models/video_ad.dart';
import '../res/firebase_constants.dart';
import 'video_analytics_service.dart';

class VideoContestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final VideoAnalyticsService _analyticsService = VideoAnalyticsService();

  /// Fetch all active contests
  Future<List<VideoContest>> fetchActiveContests({
    String? category,
    String? region,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(FirebaseConstants.videoContestsCollection)
          .where('isActive', isEqualTo: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      if (region != null) {
        query = query.where('region', isEqualTo: region);
      }

      final snapshot = await query.orderBy('startDate', descending: true).get();

      return snapshot.docs
          .map((doc) => VideoContest.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching active contests: $e');
      rethrow;
    }
  }

  /// Fetch contest by ID
  Future<VideoContest?> fetchContestById(String contestId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.videoContestsCollection)
          .doc(contestId)
          .get();

      if (!doc.exists) return null;

      return VideoContest.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Error fetching contest: $e');
      return null;
    }
  }

  /// Fetch videos participating in a contest
  Future<List<VideoAd>> fetchContestVideos(String contestId) async {
    try {
      final contest = await fetchContestById(contestId);
      if (contest == null) return [];

      if (contest.participatingVideoIds.isEmpty) return [];

      // Fetch all videos in chunks (Firestore 'in' query limit is 10)
      final List<VideoAd> videos = [];
      final videoIds = contest.participatingVideoIds;

      for (int i = 0; i < videoIds.length; i += 10) {
        final chunk = videoIds.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection(FirebaseConstants.videoAdsCollection)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        videos.addAll(
          snapshot.docs.map((doc) => VideoAd.fromFirestore(doc.data(), doc.id)),
        );
      }

      return videos;
    } catch (e) {
      debugPrint('Error fetching contest videos: $e');
      rethrow;
    }
  }

  /// Submit vote for a video in a contest
  Future<bool> submitVote({
    required String contestId,
    required String videoId,
    required String userId,
    required bool thumbsUp,
  }) async {
    try {
      // Check if user already voted
      final existingVote = await getUserVote(contestId, userId);
      if (existingVote != null) {
        throw Exception('You have already voted in this contest');
      }

      // Check if contest is in voting window
      final contest = await fetchContestById(contestId);
      if (contest == null) {
        throw Exception('Contest not found');
      }

      if (!contest.isVotingOpen) {
        throw Exception('Voting is not open for this contest');
      }

      // Create vote document
      final voteRef = _firestore
          .collection(FirebaseConstants.videoAdVotesCollection)
          .doc('${contestId}_$userId');

      await voteRef.set({
        'contestId': contestId,
        'videoId': videoId,
        'userId': userId,
        'thumbsUp': thumbsUp,
        'votedAt': FieldValue.serverTimestamp(),
      });

      // Track engagement in analytics
      await _analyticsService.trackEngagement(
        videoId: videoId,
        userId: userId,
        actionType: 'vote',
      );

      // Update contest total votes
      await _firestore
          .collection(FirebaseConstants.videoContestsCollection)
          .doc(contestId)
          .update({
        'totalVotes': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      debugPrint('Error submitting vote: $e');
      rethrow;
    }
  }

  /// Get user's vote in a contest
  Future<String?> getUserVote(String contestId, String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.videoAdVotesCollection)
          .doc('${contestId}_$userId')
          .get();

      if (!doc.exists) return null;

      return doc.data()?['videoId'] as String?;
    } catch (e) {
      debugPrint('Error getting user vote: $e');
      return null;
    }
  }

  /// Get leaderboard for a contest
  Future<List<ContestLeaderboardEntry>> getLeaderboard(String contestId) async {
    try {
      // Get all votes for this contest
      final votesSnapshot = await _firestore
          .collection(FirebaseConstants.videoAdVotesCollection)
          .where('contestId', isEqualTo: contestId)
          .get();

      // Count votes per video
      final Map<String, int> voteCounts = {};
      for (final doc in votesSnapshot.docs) {
        final videoId = doc.data()['videoId'] as String;
        voteCounts[videoId] = (voteCounts[videoId] ?? 0) + 1;
      }

      // Sort by vote count
      final sortedEntries = voteCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Create leaderboard entries
      final List<ContestLeaderboardEntry> leaderboard = [];
      for (int i = 0; i < sortedEntries.length; i++) {
        final videoId = sortedEntries[i].key;
        final voteCount = sortedEntries[i].value;

        // Fetch video details
        final videoDoc = await _firestore
            .collection(FirebaseConstants.videoAdsCollection)
            .doc(videoId)
            .get();

        if (videoDoc.exists) {
          final videoData = videoDoc.data()!;
          leaderboard.add(
            ContestLeaderboardEntry(
              videoId: videoId,
              videoTitle: videoData['title'] as String,
              uploadedBy: videoData['uploadedBy'] as String,
              voteCount: voteCount,
              rank: i + 1,
            ),
          );
        }
      }

      return leaderboard;
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      rethrow;
    }
  }

  /// Fetch contest winners
  Future<List<ContestWinner>> fetchContestWinners(String contestId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.contestWinnersCollection)
          .where('contestId', isEqualTo: contestId)
          .orderBy('rank')
          .get();

      return snapshot.docs
          .map((doc) => ContestWinner.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching contest winners: $e');
      rethrow;
    }
  }

  /// Get vote count for a specific video
  Future<int> getVideoVoteCount(String contestId, String videoId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.videoAdVotesCollection)
          .where('contestId', isEqualTo: contestId)
          .where('videoId', isEqualTo: videoId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting video vote count: $e');
      return 0;
    }
  }

  /// Stream for real-time contest updates
  Stream<VideoContest> watchContest(String contestId) {
    return _firestore
        .collection(FirebaseConstants.videoContestsCollection)
        .doc(contestId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        throw Exception('Contest not found');
      }
      return VideoContest.fromFirestore(doc.data()!, doc.id);
    });
  }

  /// Stream for real-time leaderboard updates
  Stream<List<ContestLeaderboardEntry>> watchLeaderboard(String contestId) {
    return _firestore
        .collection(FirebaseConstants.videoAdVotesCollection)
        .where('contestId', isEqualTo: contestId)
        .snapshots()
        .asyncMap((snapshot) async {
      // Count votes per video
      final Map<String, int> voteCounts = {};
      for (final doc in snapshot.docs) {
        final videoId = doc.data()['videoId'] as String;
        voteCounts[videoId] = (voteCounts[videoId] ?? 0) + 1;
      }

      // Sort by vote count
      final sortedEntries = voteCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Create leaderboard entries
      final List<ContestLeaderboardEntry> leaderboard = [];
      for (int i = 0; i < sortedEntries.length; i++) {
        final videoId = sortedEntries[i].key;
        final voteCount = sortedEntries[i].value;

        try {
          final videoDoc = await _firestore
              .collection(FirebaseConstants.videoAdsCollection)
              .doc(videoId)
              .get();

          if (videoDoc.exists) {
            final videoData = videoDoc.data()!;
            leaderboard.add(
              ContestLeaderboardEntry(
                videoId: videoId,
                videoTitle: videoData['title'] as String,
                uploadedBy: videoData['uploadedBy'] as String,
                voteCount: voteCount,
                rank: i + 1,
              ),
            );
          }
        } catch (e) {
          debugPrint('Error fetching video for leaderboard: $e');
        }
      }

      return leaderboard;
    });
  }
}

