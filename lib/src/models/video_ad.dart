class VideoAd {
  final String id;
  final String title;
  final String mediaUrl;
  final String? thumbnailUrl;
  final int durationSeconds;
  final String? category;
  final String? region;
  final DateTime? startAt;
  final DateTime? endAt;
  final int rewardPoints;
  final String? rewardCouponId;
  final int minWatchSeconds;
  final bool contestEnabled;
  final DateTime? voteWindowStart;
  final DateTime? voteWindowEnd;

  const VideoAd({
    required this.id,
    required this.title,
    required this.mediaUrl,
    this.thumbnailUrl,
    required this.durationSeconds,
    this.category,
    this.region,
    this.startAt,
    this.endAt,
    required this.rewardPoints,
    this.rewardCouponId,
    required this.minWatchSeconds,
    this.contestEnabled = false,
    this.voteWindowStart,
    this.voteWindowEnd,
  });

  bool get isActiveNow {
    final now = DateTime.now();
    if (startAt != null && now.isBefore(startAt!)) return false;
    if (endAt != null && now.isAfter(endAt!)) return false;
    return true;
  }
}

class AdEngagement {
  final String adId;
  final String userId;
  final int watchedSeconds;
  final bool completed;
  final bool rewarded;
  final DateTime? rewardedAt;
  final bool? ratedUp;
  final bool? ratedDown;

  const AdEngagement({
    required this.adId,
    required this.userId,
    required this.watchedSeconds,
    required this.completed,
    required this.rewarded,
    this.rewardedAt,
    this.ratedUp,
    this.ratedDown,
  });
}

class RewardResult {
  final bool success;
  final String message;
  final int pointsAwarded;
  final String? couponId;

  const RewardResult({
    required this.success,
    required this.message,
    required this.pointsAwarded,
    this.couponId,
  });
}

class AdPlaybackRule {
  final int minWatchSeconds;
  const AdPlaybackRule(this.minWatchSeconds);
}




