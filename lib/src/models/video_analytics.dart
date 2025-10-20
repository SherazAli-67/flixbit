import 'package:cloud_firestore/cloud_firestore.dart';

class VideoAnalytics {
  final String id; // same as video ID
  final String videoId;
  final int totalViews;
  final int uniqueViewers;
  final int totalWatchTimeSeconds;
  final double averageWatchTimeSeconds;
  final double completionRate; // percentage who watched to end
  final int likesCount;
  final int dislikesCount;
  final int votesCount; // for contests
  final int sharesCount;
  final int commentsCount;
  final double engagementRate; // (likes + votes + shares) / views
  final Map<String, int> viewsByRegion; // region -> count
  final Map<String, int> viewsByDate; // date -> count
  final int rewardsDistributed; // total Flixbit points given
  final DateTime lastUpdated;

  const VideoAnalytics({
    required this.id,
    required this.videoId,
    this.totalViews = 0,
    this.uniqueViewers = 0,
    this.totalWatchTimeSeconds = 0,
    this.averageWatchTimeSeconds = 0.0,
    this.completionRate = 0.0,
    this.likesCount = 0,
    this.dislikesCount = 0,
    this.votesCount = 0,
    this.sharesCount = 0,
    this.commentsCount = 0,
    this.engagementRate = 0.0,
    this.viewsByRegion = const {},
    this.viewsByDate = const {},
    this.rewardsDistributed = 0,
    required this.lastUpdated,
  });

  // Factory method to create from Firestore
  factory VideoAnalytics.fromFirestore(Map<String, dynamic> data, String id) {
    return VideoAnalytics(
      id: id,
      videoId: data['videoId'] as String,
      totalViews: data['totalViews'] as int? ?? 0,
      uniqueViewers: data['uniqueViewers'] as int? ?? 0,
      totalWatchTimeSeconds: data['totalWatchTimeSeconds'] as int? ?? 0,
      averageWatchTimeSeconds: (data['averageWatchTimeSeconds'] as num?)?.toDouble() ?? 0.0,
      completionRate: (data['completionRate'] as num?)?.toDouble() ?? 0.0,
      likesCount: data['likesCount'] as int? ?? 0,
      dislikesCount: data['dislikesCount'] as int? ?? 0,
      votesCount: data['votesCount'] as int? ?? 0,
      sharesCount: data['sharesCount'] as int? ?? 0,
      commentsCount: data['commentsCount'] as int? ?? 0,
      engagementRate: (data['engagementRate'] as num?)?.toDouble() ?? 0.0,
      viewsByRegion: data['viewsByRegion'] != null
          ? Map<String, int>.from(data['viewsByRegion'] as Map)
          : {},
      viewsByDate: data['viewsByDate'] != null
          ? Map<String, int>.from(data['viewsByDate'] as Map)
          : {},
      rewardsDistributed: data['rewardsDistributed'] as int? ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'videoId': videoId,
      'totalViews': totalViews,
      'uniqueViewers': uniqueViewers,
      'totalWatchTimeSeconds': totalWatchTimeSeconds,
      'averageWatchTimeSeconds': averageWatchTimeSeconds,
      'completionRate': completionRate,
      'likesCount': likesCount,
      'dislikesCount': dislikesCount,
      'votesCount': votesCount,
      'sharesCount': sharesCount,
      'commentsCount': commentsCount,
      'engagementRate': engagementRate,
      'viewsByRegion': viewsByRegion,
      'viewsByDate': viewsByDate,
      'rewardsDistributed': rewardsDistributed,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  // CopyWith method
  VideoAnalytics copyWith({
    String? id,
    String? videoId,
    int? totalViews,
    int? uniqueViewers,
    int? totalWatchTimeSeconds,
    double? averageWatchTimeSeconds,
    double? completionRate,
    int? likesCount,
    int? dislikesCount,
    int? votesCount,
    int? sharesCount,
    int? commentsCount,
    double? engagementRate,
    Map<String, int>? viewsByRegion,
    Map<String, int>? viewsByDate,
    int? rewardsDistributed,
    DateTime? lastUpdated,
  }) {
    return VideoAnalytics(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      totalViews: totalViews ?? this.totalViews,
      uniqueViewers: uniqueViewers ?? this.uniqueViewers,
      totalWatchTimeSeconds: totalWatchTimeSeconds ?? this.totalWatchTimeSeconds,
      averageWatchTimeSeconds: averageWatchTimeSeconds ?? this.averageWatchTimeSeconds,
      completionRate: completionRate ?? this.completionRate,
      likesCount: likesCount ?? this.likesCount,
      dislikesCount: dislikesCount ?? this.dislikesCount,
      votesCount: votesCount ?? this.votesCount,
      sharesCount: sharesCount ?? this.sharesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      engagementRate: engagementRate ?? this.engagementRate,
      viewsByRegion: viewsByRegion ?? this.viewsByRegion,
      viewsByDate: viewsByDate ?? this.viewsByDate,
      rewardsDistributed: rewardsDistributed ?? this.rewardsDistributed,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Calculate engagement rate
  double calculateEngagementRate() {
    if (totalViews == 0) return 0.0;
    final totalEngagements = likesCount + votesCount + sharesCount;
    return (totalEngagements / totalViews) * 100;
  }

  // Calculate average watch time
  double calculateAverageWatchTime() {
    if (uniqueViewers == 0) return 0.0;
    return totalWatchTimeSeconds / uniqueViewers;
  }
}

class VideoUploadData {
  final String id;
  final String sellerId;
  final String fileName;
  final String filePath;
  final int fileSizeBytes;
  final String? thumbnailPath;
  final double uploadProgress; // 0.0 to 1.0
  final String status; // 'pending', 'uploading', 'processing', 'completed', 'failed'
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VideoUploadData({
    required this.id,
    required this.sellerId,
    required this.fileName,
    required this.filePath,
    required this.fileSizeBytes,
    this.thumbnailPath,
    this.uploadProgress = 0.0,
    this.status = 'pending',
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory method to create from Firestore
  factory VideoUploadData.fromFirestore(Map<String, dynamic> data, String id) {
    return VideoUploadData(
      id: id,
      sellerId: data['sellerId'] as String,
      fileName: data['fileName'] as String,
      filePath: data['filePath'] as String,
      fileSizeBytes: data['fileSizeBytes'] as int,
      thumbnailPath: data['thumbnailPath'] as String?,
      uploadProgress: (data['uploadProgress'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'pending',
      errorMessage: data['errorMessage'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'fileName': fileName,
      'filePath': filePath,
      'fileSizeBytes': fileSizeBytes,
      'thumbnailPath': thumbnailPath,
      'uploadProgress': uploadProgress,
      'status': status,
      'errorMessage': errorMessage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // CopyWith method
  VideoUploadData copyWith({
    String? id,
    String? sellerId,
    String? fileName,
    String? filePath,
    int? fileSizeBytes,
    String? thumbnailPath,
    double? uploadProgress,
    String? status,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VideoUploadData(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

