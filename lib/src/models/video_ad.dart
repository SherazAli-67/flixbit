enum ApprovalStatus {
  pending,
  approved,
  rejected,
  flagged,
  inactive,
}

enum ContestStatus {
  upcoming,
  votingOpen,
  votingClosed,
  winnersAnnounced,
  ended,
}

class VideoAd {
  final String id;
  final String title;
  final String? description;
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
  
  // New fields
  final String uploadedBy; // seller ID or admin ID
  final ApprovalStatus approvalStatus;
  final String? approvedBy; // admin ID who approved
  final DateTime? approvedAt;
  final String? rejectionReason;
  final double? sponsorshipAmount;
  final Map<String, dynamic>? targetAudience; // age, interests, etc.
  final Map<String, dynamic>? creatorRewards; // rewards for video creator
  final DateTime createdAt;
  final DateTime updatedAt;

  const VideoAd({
    required this.id,
    required this.title,
    this.description,
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
    required this.uploadedBy,
    this.approvalStatus = ApprovalStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.sponsorshipAmount,
    this.targetAudience,
    this.creatorRewards,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActiveNow {
    final now = DateTime.now();
    if (approvalStatus != ApprovalStatus.approved) return false;
    if (startAt != null && now.isBefore(startAt!)) return false;
    if (endAt != null && now.isAfter(endAt!)) return false;
    return true;
  }

  bool get isInVotingWindow {
    if (!contestEnabled) return false;
    final now = DateTime.now();
    if (voteWindowStart != null && now.isBefore(voteWindowStart!)) return false;
    if (voteWindowEnd != null && now.isAfter(voteWindowEnd!)) return false;
    return true;
  }

  ContestStatus get contestStatus {
    if (!contestEnabled) return ContestStatus.ended;
    
    final now = DateTime.now();
    
    if (voteWindowStart != null && now.isBefore(voteWindowStart!)) {
      return ContestStatus.upcoming;
    }
    
    if (voteWindowEnd != null && now.isAfter(voteWindowEnd!)) {
      return ContestStatus.votingClosed;
    }
    
    if (isInVotingWindow) {
      return ContestStatus.votingOpen;
    }
    
    return ContestStatus.ended;
  }

  // Factory method to create from Firestore
  factory VideoAd.fromFirestore(Map<String, dynamic> data, String id) {
    return VideoAd(
      id: id,
      title: data['title'] as String,
      description: data['description'] as String?,
      mediaUrl: data['mediaUrl'] as String,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      durationSeconds: data['durationSeconds'] as int,
      category: data['category'] as String?,
      region: data['region'] as String?,
      startAt: data['startAt'] != null ? (data['startAt'] as dynamic).toDate() : null,
      endAt: data['endAt'] != null ? (data['endAt'] as dynamic).toDate() : null,
      rewardPoints: data['rewardPoints'] as int,
      rewardCouponId: data['rewardCouponId'] as String?,
      minWatchSeconds: data['minWatchSeconds'] as int,
      contestEnabled: data['contestEnabled'] as bool? ?? false,
      voteWindowStart: data['voteWindowStart'] != null ? (data['voteWindowStart'] as dynamic).toDate() : null,
      voteWindowEnd: data['voteWindowEnd'] != null ? (data['voteWindowEnd'] as dynamic).toDate() : null,
      uploadedBy: data['uploadedBy'] as String,
      approvalStatus: ApprovalStatus.values.firstWhere(
        (e) => e.name == data['approvalStatus'],
        orElse: () => ApprovalStatus.pending,
      ),
      approvedBy: data['approvedBy'] as String?,
      approvedAt: data['approvedAt'] != null ? (data['approvedAt'] as dynamic).toDate() : null,
      rejectionReason: data['rejectionReason'] as String?,
      sponsorshipAmount: data['sponsorshipAmount'] as double?,
      targetAudience: data['targetAudience'] as Map<String, dynamic>?,
      creatorRewards: data['creatorRewards'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as dynamic).toDate(),
      updatedAt: (data['updatedAt'] as dynamic).toDate(),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'durationSeconds': durationSeconds,
      'category': category,
      'region': region,
      'startAt': startAt,
      'endAt': endAt,
      'rewardPoints': rewardPoints,
      'rewardCouponId': rewardCouponId,
      'minWatchSeconds': minWatchSeconds,
      'contestEnabled': contestEnabled,
      'voteWindowStart': voteWindowStart,
      'voteWindowEnd': voteWindowEnd,
      'uploadedBy': uploadedBy,
      'approvalStatus': approvalStatus.name,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt,
      'rejectionReason': rejectionReason,
      'sponsorshipAmount': sponsorshipAmount,
      'targetAudience': targetAudience,
      'creatorRewards': creatorRewards,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // CopyWith method for updates
  VideoAd copyWith({
    String? id,
    String? title,
    String? description,
    String? mediaUrl,
    String? thumbnailUrl,
    int? durationSeconds,
    String? category,
    String? region,
    DateTime? startAt,
    DateTime? endAt,
    int? rewardPoints,
    String? rewardCouponId,
    int? minWatchSeconds,
    bool? contestEnabled,
    DateTime? voteWindowStart,
    DateTime? voteWindowEnd,
    String? uploadedBy,
    ApprovalStatus? approvalStatus,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    double? sponsorshipAmount,
    Map<String, dynamic>? targetAudience,
    Map<String, dynamic>? creatorRewards,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VideoAd(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      category: category ?? this.category,
      region: region ?? this.region,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      rewardCouponId: rewardCouponId ?? this.rewardCouponId,
      minWatchSeconds: minWatchSeconds ?? this.minWatchSeconds,
      contestEnabled: contestEnabled ?? this.contestEnabled,
      voteWindowStart: voteWindowStart ?? this.voteWindowStart,
      voteWindowEnd: voteWindowEnd ?? this.voteWindowEnd,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      sponsorshipAmount: sponsorshipAmount ?? this.sponsorshipAmount,
      targetAudience: targetAudience ?? this.targetAudience,
      creatorRewards: creatorRewards ?? this.creatorRewards,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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




