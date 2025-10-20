import 'package:cloud_firestore/cloud_firestore.dart';

class ContestWinner {
  final String id;
  final String contestId;
  final String contestTitle;
  final String videoId;
  final String videoTitle;
  final String sellerId; // video creator/uploader
  final String sellerName;
  final int rank; // 1st, 2nd, 3rd place
  final int voteCount;
  final int rewardPoints;
  final String? rewardCouponId;
  final Map<String, dynamic>? additionalRewards;
  final bool rewardDistributed;
  final DateTime? rewardDistributedAt;
  final DateTime announcedAt;
  final bool notified; // whether winner was notified
  final DateTime? notifiedAt;

  const ContestWinner({
    required this.id,
    required this.contestId,
    required this.contestTitle,
    required this.videoId,
    required this.videoTitle,
    required this.sellerId,
    required this.sellerName,
    required this.rank,
    required this.voteCount,
    required this.rewardPoints,
    this.rewardCouponId,
    this.additionalRewards,
    this.rewardDistributed = false,
    this.rewardDistributedAt,
    required this.announcedAt,
    this.notified = false,
    this.notifiedAt,
  });

  // Factory method to create from Firestore
  factory ContestWinner.fromFirestore(Map<String, dynamic> data, String id) {
    return ContestWinner(
      id: id,
      contestId: data['contestId'] as String,
      contestTitle: data['contestTitle'] as String,
      videoId: data['videoId'] as String,
      videoTitle: data['videoTitle'] as String,
      sellerId: data['sellerId'] as String,
      sellerName: data['sellerName'] as String,
      rank: data['rank'] as int,
      voteCount: data['voteCount'] as int,
      rewardPoints: data['rewardPoints'] as int,
      rewardCouponId: data['rewardCouponId'] as String?,
      additionalRewards: data['additionalRewards'] as Map<String, dynamic>?,
      rewardDistributed: data['rewardDistributed'] as bool? ?? false,
      rewardDistributedAt: data['rewardDistributedAt'] != null
          ? (data['rewardDistributedAt'] as Timestamp).toDate()
          : null,
      announcedAt: (data['announcedAt'] as Timestamp).toDate(),
      notified: data['notified'] as bool? ?? false,
      notifiedAt: data['notifiedAt'] != null
          ? (data['notifiedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'contestId': contestId,
      'contestTitle': contestTitle,
      'videoId': videoId,
      'videoTitle': videoTitle,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'rank': rank,
      'voteCount': voteCount,
      'rewardPoints': rewardPoints,
      'rewardCouponId': rewardCouponId,
      'additionalRewards': additionalRewards,
      'rewardDistributed': rewardDistributed,
      'rewardDistributedAt': rewardDistributedAt != null
          ? Timestamp.fromDate(rewardDistributedAt!)
          : null,
      'announcedAt': Timestamp.fromDate(announcedAt),
      'notified': notified,
      'notifiedAt': notifiedAt != null ? Timestamp.fromDate(notifiedAt!) : null,
    };
  }

  // CopyWith method
  ContestWinner copyWith({
    String? id,
    String? contestId,
    String? contestTitle,
    String? videoId,
    String? videoTitle,
    String? sellerId,
    String? sellerName,
    int? rank,
    int? voteCount,
    int? rewardPoints,
    String? rewardCouponId,
    Map<String, dynamic>? additionalRewards,
    bool? rewardDistributed,
    DateTime? rewardDistributedAt,
    DateTime? announcedAt,
    bool? notified,
    DateTime? notifiedAt,
  }) {
    return ContestWinner(
      id: id ?? this.id,
      contestId: contestId ?? this.contestId,
      contestTitle: contestTitle ?? this.contestTitle,
      videoId: videoId ?? this.videoId,
      videoTitle: videoTitle ?? this.videoTitle,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      rank: rank ?? this.rank,
      voteCount: voteCount ?? this.voteCount,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      rewardCouponId: rewardCouponId ?? this.rewardCouponId,
      additionalRewards: additionalRewards ?? this.additionalRewards,
      rewardDistributed: rewardDistributed ?? this.rewardDistributed,
      rewardDistributedAt: rewardDistributedAt ?? this.rewardDistributedAt,
      announcedAt: announcedAt ?? this.announcedAt,
      notified: notified ?? this.notified,
      notifiedAt: notifiedAt ?? this.notifiedAt,
    );
  }
}

