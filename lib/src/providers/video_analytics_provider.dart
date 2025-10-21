import 'package:flutter/foundation.dart';

import '../models/video_analytics.dart';
import '../service/video_analytics_service.dart';

class VideoAnalyticsProvider extends ChangeNotifier {
  final VideoAnalyticsService _analyticsService = VideoAnalyticsService();

  VideoAnalytics? _currentVideoAnalytics;
  List<VideoAnalytics> _sellerVideosAnalytics = [];
  bool _loading = false;
  String? _error;

  VideoAnalytics? get currentVideoAnalytics => _currentVideoAnalytics;
  List<VideoAnalytics> get sellerVideosAnalytics => _sellerVideosAnalytics;
  bool get loading => _loading;
  String? get error => _error;

  /// Load analytics for a specific video
  Future<void> loadVideoAnalytics(String videoId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      _currentVideoAnalytics = await _analyticsService.getVideoAnalytics(videoId);

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  /// Load all analytics for a seller
  Future<void> loadSellerAnalytics(String sellerId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      _sellerVideosAnalytics = await _analyticsService.getSellerAnalytics(sellerId);

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  /// Refresh analytics
  Future<void> refreshAnalytics(String sellerId) async {
    await loadSellerAnalytics(sellerId);
  }

  /// Get top performer
  VideoAnalytics? getTopPerformer() {
    if (_sellerVideosAnalytics.isEmpty) return null;

    return _sellerVideosAnalytics.reduce(
      (current, next) => current.totalViews > next.totalViews ? current : next,
    );
  }

  /// Get total stats across all videos
  Map<String, dynamic> getTotalStats() {
    if (_sellerVideosAnalytics.isEmpty) {
      return {
        'totalViews': 0,
        'totalWatchTime': 0,
        'avgEngagement': 0.0,
        'totalRewards': 0,
      };
    }

    int totalViews = 0;
    int totalWatchTime = 0;
    int totalRewards = 0;
    double avgEngagement = 0.0;

    for (final analytics in _sellerVideosAnalytics) {
      totalViews += analytics.totalViews;
      totalWatchTime += analytics.totalWatchTimeSeconds;
      totalRewards += analytics.rewardsDistributed;
      avgEngagement += analytics.engagementRate;
    }

    avgEngagement /= _sellerVideosAnalytics.length;

    return {
      'totalViews': totalViews,
      'totalWatchTime': totalWatchTime,
      'avgEngagement': avgEngagement,
      'totalRewards': totalRewards,
      'videoCount': _sellerVideosAnalytics.length,
    };
  }

  /// Clear analytics
  void clear() {
    _currentVideoAnalytics = null;
    _sellerVideosAnalytics = [];
    _error = null;
    notifyListeners();
  }
}

class SellerDashboardAnalyticsProvider extends ChangeNotifier {
  final VideoAnalyticsService _analyticsService = VideoAnalyticsService();

  Map<String, dynamic> _aggregateStats = {};
  List<VideoAnalytics> _topVideos = [];
  Map<String, int> _viewsByRegion = {};
  Map<String, int> _viewsByCategory = {};
  bool _loading = false;
  String? _error;

  Map<String, dynamic> get aggregateStats => _aggregateStats;
  List<VideoAnalytics> get topVideos => _topVideos;
  Map<String, int> get viewsByRegion => _viewsByRegion;
  Map<String, int> get viewsByCategory => _viewsByCategory;
  bool get loading => _loading;
  String? get error => _error;

  /// Load complete dashboard for a seller
  Future<void> loadDashboard(String sellerId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      // Load aggregate stats
      _aggregateStats = await _analyticsService.getAggregateStats(sellerId);

      // Load top videos
      _topVideos = await _analyticsService.getTopVideos(sellerId, limit: 5);

      // Calculate regional breakdown
      final allAnalytics = await _analyticsService.getSellerAnalytics(sellerId);
      _viewsByRegion = {};
      _viewsByCategory = {};

      for (final analytics in allAnalytics) {
        // Aggregate views by region
        analytics.viewsByRegion.forEach((region, count) {
          _viewsByRegion[region] = (_viewsByRegion[region] ?? 0) + count;
        });
      }

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  /// Get stats for a specific time range
  Future<Map<String, dynamic>> getTimeRangeStats(
    String sellerId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final allAnalytics = await _analyticsService.getSellerAnalytics(sellerId);

      int totalViews = 0;
      int totalWatchTime = 0;

      for (final analytics in allAnalytics) {
        // Filter by date range
        analytics.viewsByDate.forEach((dateStr, count) {
          final date = DateTime.parse(dateStr);
          if (date.isAfter(startDate) && date.isBefore(endDate)) {
            totalViews += count;
          }
        });
      }

      return {
        'totalViews': totalViews,
        'totalWatchTime': totalWatchTime,
        'startDate': startDate,
        'endDate': endDate,
      };
    } catch (e) {
      debugPrint('Error getting time range stats: $e');
      return {};
    }
  }

  /// Export report (placeholder - returns CSV string)
  String exportReport(String format) {
    if (format == 'csv') {
      final buffer = StringBuffer();
      buffer.writeln('Video ID,Total Views,Watch Time (s),Engagement Rate,Rewards');

      for (final video in _topVideos) {
        buffer.writeln(
          '${video.videoId},${video.totalViews},${video.totalWatchTimeSeconds},'
          '${video.engagementRate.toStringAsFixed(2)},${video.rewardsDistributed}',
        );
      }

      return buffer.toString();
    }

    return '';
  }

  /// Clear dashboard
  void clear() {
    _aggregateStats = {};
    _topVideos = [];
    _viewsByRegion = {};
    _viewsByCategory = {};
    _error = null;
    notifyListeners();
  }
}

