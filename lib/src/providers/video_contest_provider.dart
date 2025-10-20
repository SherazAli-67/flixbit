import 'package:flutter/foundation.dart';

import '../models/video_contest.dart';
import '../models/contest_winner.dart';
import '../models/video_ad.dart';
import '../service/video_contest_service.dart';

class VideoContestProvider extends ChangeNotifier {
  final VideoContestService _contestService = VideoContestService();

  List<VideoContest> _contests = [];
  bool _loading = false;
  String? _error;

  List<VideoContest> get contests => _contests;
  bool get loading => _loading;
  String? get error => _error;

  /// Fetch active contests
  Future<void> fetchActiveContests({String? category, String? region}) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      _contests = await _contestService.fetchActiveContests(
        category: category,
        region: region,
      );

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  /// Clear contests
  void clear() {
    _contests = [];
    _error = null;
    notifyListeners();
  }
}

class ContestDetailProvider extends ChangeNotifier {
  final VideoContestService _contestService = VideoContestService();

  VideoContest? _contest;
  List<VideoAd> _videos = [];
  List<ContestLeaderboardEntry> _leaderboard = [];
  String? _userVotedVideoId;
  bool _loading = false;
  bool _votingInProgress = false;
  String? _error;

  VideoContest? get contest => _contest;
  List<VideoAd> get videos => _videos;
  List<ContestLeaderboardEntry> get leaderboard => _leaderboard;
  String? get userVotedVideoId => _userVotedVideoId;
  bool get loading => _loading;
  bool get votingInProgress => _votingInProgress;
  String? get error => _error;
  bool get hasVoted => _userVotedVideoId != null;

  /// Load contest details
  Future<void> loadContest(String contestId, String userId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      // Fetch contest
      _contest = await _contestService.fetchContestById(contestId);

      if (_contest == null) {
        throw Exception('Contest not found');
      }

      // Fetch contest videos
      _videos = await _contestService.fetchContestVideos(contestId);

      // Fetch leaderboard
      _leaderboard = await _contestService.getLeaderboard(contestId);

      // Check if user has voted
      _userVotedVideoId = await _contestService.getUserVote(contestId, userId);

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  /// Submit vote
  Future<bool> submitVote({
    required String contestId,
    required String videoId,
    required String userId,
  }) async {
    try {
      _votingInProgress = true;
      _error = null;
      notifyListeners();

      await _contestService.submitVote(
        contestId: contestId,
        videoId: videoId,
        userId: userId,
        thumbsUp: true,
      );

      _userVotedVideoId = videoId;
      
      // Refresh leaderboard
      _leaderboard = await _contestService.getLeaderboard(contestId);

      _votingInProgress = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      _votingInProgress = false;
      notifyListeners();
      return false;
    }
  }

  /// Refresh leaderboard
  Future<void> refreshLeaderboard(String contestId) async {
    try {
      _leaderboard = await _contestService.getLeaderboard(contestId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing leaderboard: $e');
    }
  }
}

class ContestWinnersProvider extends ChangeNotifier {
  final VideoContestService _contestService = VideoContestService();

  List<ContestWinner> _winners = [];
  bool _loading = false;
  String? _error;

  List<ContestWinner> get winners => _winners;
  bool get loading => _loading;
  String? get error => _error;

  /// Fetch contest winners
  Future<void> fetchWinners(String contestId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      _winners = await _contestService.fetchContestWinners(contestId);

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  /// Clear winners
  void clear() {
    _winners = [];
    _error = null;
    notifyListeners();
  }
}

