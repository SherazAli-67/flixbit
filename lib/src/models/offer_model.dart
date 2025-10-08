class Offer {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final String? imageUrl;
  final OfferType type;
  final double? discountPercentage;
  final double? discountAmount;
  final String? discountCode;
  final DateTime validFrom;
  final DateTime validUntil;
  final int? maxRedemptions;
  final int currentRedemptions;
  final bool isActive;
  final DateTime createdAt;
  final List<String> termsAndConditions;
  final String? category;
  final double? minPurchaseAmount;
  final bool requiresReview;
  final int reviewPointsReward;

  Offer({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.type,
    this.discountPercentage,
    this.discountAmount,
    this.discountCode,
    required this.validFrom,
    required this.validUntil,
    this.maxRedemptions,
    this.currentRedemptions = 0,
    required this.isActive,
    required this.createdAt,
    this.termsAndConditions = const [],
    this.category,
    this.minPurchaseAmount,
    this.requiresReview = false,
    this.reviewPointsReward = 0,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] ?? '',
      sellerId: json['sellerId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      type: OfferType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => OfferType.discount,
      ),
      discountPercentage: json['discountPercentage']?.toDouble(),
      discountAmount: json['discountAmount']?.toDouble(),
      discountCode: json['discountCode'],
      validFrom: DateTime.parse(json['validFrom']),
      validUntil: DateTime.parse(json['validUntil']),
      maxRedemptions: json['maxRedemptions'],
      currentRedemptions: json['currentRedemptions'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      termsAndConditions: List<String>.from(json['termsAndConditions'] ?? []),
      category: json['category'],
      minPurchaseAmount: json['minPurchaseAmount']?.toDouble(),
      requiresReview: json['requiresReview'] ?? false,
      reviewPointsReward: json['reviewPointsReward'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'type': type.name,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
      'discountCode': discountCode,
      'validFrom': validFrom.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'maxRedemptions': maxRedemptions,
      'currentRedemptions': currentRedemptions,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'termsAndConditions': termsAndConditions,
      'category': category,
      'minPurchaseAmount': minPurchaseAmount,
      'requiresReview': requiresReview,
      'reviewPointsReward': reviewPointsReward,
    };
  }

  Offer copyWith({
    String? id,
    String? sellerId,
    String? title,
    String? description,
    String? imageUrl,
    OfferType? type,
    double? discountPercentage,
    double? discountAmount,
    String? discountCode,
    DateTime? validFrom,
    DateTime? validUntil,
    int? maxRedemptions,
    int? currentRedemptions,
    bool? isActive,
    DateTime? createdAt,
    List<String>? termsAndConditions,
    String? category,
    double? minPurchaseAmount,
    bool? requiresReview,
    int? reviewPointsReward,
  }) {
    return Offer(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountAmount: discountAmount ?? this.discountAmount,
      discountCode: discountCode ?? this.discountCode,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      maxRedemptions: maxRedemptions ?? this.maxRedemptions,
      currentRedemptions: currentRedemptions ?? this.currentRedemptions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      category: category ?? this.category,
      minPurchaseAmount: minPurchaseAmount ?? this.minPurchaseAmount,
      requiresReview: requiresReview ?? this.requiresReview,
      reviewPointsReward: reviewPointsReward ?? this.reviewPointsReward,
    );
  }

  // Helper methods
  bool get isValid => DateTime.now().isAfter(validFrom) && DateTime.now().isBefore(validUntil);
  bool get isExpired => DateTime.now().isAfter(validUntil);
  bool get isNotStarted => DateTime.now().isBefore(validFrom);
  bool get isFullyRedeemed => maxRedemptions != null && currentRedemptions >= maxRedemptions!;
  bool get canBeRedeemed => isValid && isActive && !isFullyRedeemed;
  
  String get displayDiscount {
    if (discountPercentage != null) {
      return '${discountPercentage!.toStringAsFixed(0)}% OFF';
    } else if (discountAmount != null) {
      return '\$${discountAmount!.toStringAsFixed(2)} OFF';
    }
    return 'Special Offer';
  }

  String get validityStatus {
    if (isNotStarted) return 'Starts ${_formatDate(validFrom)}';
    if (isExpired) return 'Expired';
    if (isFullyRedeemed) return 'Fully Redeemed';
    return 'Valid until ${_formatDate(validUntil)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

enum OfferType {
  discount,
  freeItem,
  buyOneGetOne,
  cashback,
  points,
  voucher,
}

class OfferRedemption {
  final String id;
  final String userId;
  final String offerId;
  final String sellerId;
  final DateTime redeemedAt;
  final bool isUsed;
  final DateTime? usedAt;
  final String? reviewId; // Link to review if user left one
  final int pointsEarned;
  final String? qrCodeData; // For verification

  OfferRedemption({
    required this.id,
    required this.userId,
    required this.offerId,
    required this.sellerId,
    required this.redeemedAt,
    this.isUsed = false,
    this.usedAt,
    this.reviewId,
    this.pointsEarned = 0,
    this.qrCodeData,
  });

  factory OfferRedemption.fromJson(Map<String, dynamic> json) {
    return OfferRedemption(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      offerId: json['offerId'] ?? '',
      sellerId: json['sellerId'] ?? '',
      redeemedAt: DateTime.parse(json['redeemedAt']),
      isUsed: json['isUsed'] ?? false,
      usedAt: json['usedAt'] != null ? DateTime.parse(json['usedAt']) : null,
      reviewId: json['reviewId'],
      pointsEarned: json['pointsEarned'] ?? 0,
      qrCodeData: json['qrCodeData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'offerId': offerId,
      'sellerId': sellerId,
      'redeemedAt': redeemedAt.toIso8601String(),
      'isUsed': isUsed,
      'usedAt': usedAt?.toIso8601String(),
      'reviewId': reviewId,
      'pointsEarned': pointsEarned,
      'qrCodeData': qrCodeData,
    };
  }
}

