class Review {
  final String id;
  final String userId;
  final String sellerId;
  final String? offerId;
  final int rating; // 1-5 stars
  final String? comment;
  final List<String>? imageUrls;
  final String? videoUrl;
  final ReviewType type;
  final ReviewStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? sellerReply;
  final DateTime? sellerReplyDate;
  final bool isVerified;
  final String? verificationMethod; // 'qr_scan', 'offer_redemption', 'video_watch', etc.
  final int pointsEarned;

  Review({
    required this.id,
    required this.userId,
    required this.sellerId,
    this.offerId,
    required this.rating,
    this.comment,
    this.imageUrls,
    this.videoUrl,
    required this.type,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.sellerReply,
    this.sellerReplyDate,
    required this.isVerified,
    this.verificationMethod,
    required this.pointsEarned,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      sellerId: json['sellerId'] ?? '',
      offerId: json['offerId'],
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      imageUrls: json['imageUrls'] != null ? List<String>.from(json['imageUrls']) : null,
      videoUrl: json['videoUrl'],
      type: ReviewType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReviewType.seller,
      ),
      status: ReviewStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReviewStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      sellerReply: json['sellerReply'],
      sellerReplyDate: json['sellerReplyDate'] != null ? DateTime.parse(json['sellerReplyDate']) : null,
      isVerified: json['isVerified'] ?? false,
      verificationMethod: json['verificationMethod'],
      pointsEarned: json['pointsEarned'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'sellerId': sellerId,
      'offerId': offerId,
      'rating': rating,
      'comment': comment,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'type': type.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'sellerReply': sellerReply,
      'sellerReplyDate': sellerReplyDate?.toIso8601String(),
      'isVerified': isVerified,
      'verificationMethod': verificationMethod,
      'pointsEarned': pointsEarned,
    };
  }

  Review copyWith({
    String? id,
    String? userId,
    String? sellerId,
    String? offerId,
    int? rating,
    String? comment,
    List<String>? imageUrls,
    String? videoUrl,
    ReviewType? type,
    ReviewStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? sellerReply,
    DateTime? sellerReplyDate,
    bool? isVerified,
    String? verificationMethod,
    int? pointsEarned,
  }) {
    return Review(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sellerId: sellerId ?? this.sellerId,
      offerId: offerId ?? this.offerId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sellerReply: sellerReply ?? this.sellerReply,
      sellerReplyDate: sellerReplyDate ?? this.sellerReplyDate,
      isVerified: isVerified ?? this.isVerified,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      pointsEarned: pointsEarned ?? this.pointsEarned,
    );
  }
}

enum ReviewType {
  seller,
  offer,
  videoAd,
  referral,
}

enum ReviewStatus {
  pending,
  approved,
  rejected,
  flagged,
}

class ReviewSummary {
  final String sellerId;
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // rating -> count
  final List<String> badges;
  final DateTime lastUpdated;

  ReviewSummary({
    required this.sellerId,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.badges,
    required this.lastUpdated,
  });

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    return ReviewSummary(
      sellerId: json['sellerId'] ?? '',
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      ratingDistribution: Map<int, int>.from(json['ratingDistribution'] ?? {}),
      badges: List<String>.from(json['badges'] ?? []),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sellerId': sellerId,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'ratingDistribution': ratingDistribution,
      'badges': badges,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
