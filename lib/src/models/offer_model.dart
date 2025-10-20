import 'package:cloud_firestore/cloud_firestore.dart';

class Offer {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final String? imageUrl;
  final String? videoUrl;
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
  
  // Approval & Admin fields
  final ApprovalStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String? adminNotes;
  
  // Location targeting
  final GeoPoint? targetLocation;
  final double? targetRadiusKm;
  
  // QR & Analytics
  final String qrCodeData;
  final int viewCount;

  Offer({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    this.imageUrl,
    this.videoUrl,
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
    this.status = ApprovalStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.adminNotes,
    this.targetLocation,
    this.targetRadiusKm,
    required this.qrCodeData,
    this.viewCount = 0,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] ?? '',
      sellerId: json['sellerId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      videoUrl: json['videoUrl'],
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
      status: ApprovalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ApprovalStatus.pending,
      ),
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      rejectionReason: json['rejectionReason'],
      adminNotes: json['adminNotes'],
      targetLocation: json['targetLocation'] != null ? json['targetLocation'] as GeoPoint : null,
      targetRadiusKm: json['targetRadiusKm']?.toDouble(),
      qrCodeData: json['qrCodeData'] ?? '',
      viewCount: json['viewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
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
      'status': status.name,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'adminNotes': adminNotes,
      'targetLocation': targetLocation,
      'targetRadiusKm': targetRadiusKm,
      'qrCodeData': qrCodeData,
      'viewCount': viewCount,
    };
  }

  Offer copyWith({
    String? id,
    String? sellerId,
    String? title,
    String? description,
    String? imageUrl,
    String? videoUrl,
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
    ApprovalStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    String? adminNotes,
    GeoPoint? targetLocation,
    double? targetRadiusKm,
    String? qrCodeData,
    int? viewCount,
  }) {
    return Offer(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
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
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      adminNotes: adminNotes ?? this.adminNotes,
      targetLocation: targetLocation ?? this.targetLocation,
      targetRadiusKm: targetRadiusKm ?? this.targetRadiusKm,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      viewCount: viewCount ?? this.viewCount,
    );
  }

  // Helper methods
  bool get isValid => DateTime.now().isAfter(validFrom) && DateTime.now().isBefore(validUntil);
  bool get isExpired => DateTime.now().isAfter(validUntil);
  bool get isNotStarted => DateTime.now().isBefore(validFrom);
  bool get isFullyRedeemed => maxRedemptions != null && currentRedemptions >= maxRedemptions!;
  bool get canBeRedeemed => isValid && isActive && !isFullyRedeemed && status == ApprovalStatus.approved;
  bool get isApproved => status == ApprovalStatus.approved;
  bool get isPending => status == ApprovalStatus.pending;
  bool get isRejected => status == ApprovalStatus.rejected;
  
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

enum ApprovalStatus {
  pending,
  approved,
  rejected,
  expired,
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

