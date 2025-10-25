import 'package:cloud_firestore/cloud_firestore.dart';

class Reward {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final RewardType rewardType;
  final int pointsCost;
  final int stockQuantity;
  final int redemptionCount;
  final RewardCategory category;
  final bool isActive;
  final DateTime? expiryDate;
  final DeliveryInfo? deliveryInfo;
  final List<String> termsAndConditions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy; // Admin/Seller ID
  final bool isFeatured;
  final int? maxRedemptionsPerUser;
  final Map<String, dynamic>? metadata;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.rewardType,
    required this.pointsCost,
    required this.stockQuantity,
    this.redemptionCount = 0,
    required this.category,
    this.isActive = true,
    this.expiryDate,
    this.deliveryInfo,
    this.termsAndConditions = const [],
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.isFeatured = false,
    this.maxRedemptionsPerUser,
    this.metadata,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      rewardType: RewardType.values.firstWhere(
        (e) => e.name == json['rewardType'],
        orElse: () => RewardType.digital,
      ),
      pointsCost: json['pointsCost'] as int,
      stockQuantity: json['stockQuantity'] as int,
      redemptionCount: json['redemptionCount'] as int? ?? 0,
      category: RewardCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => RewardCategory.voucher,
      ),
      isActive: json['isActive'] as bool? ?? true,
      expiryDate: _parseDateTime(json['expiryDate']),
      deliveryInfo: json['deliveryInfo'] != null
          ? DeliveryInfo.fromJson(json['deliveryInfo'] as Map<String, dynamic>)
          : null,
      termsAndConditions: List<String>.from(json['termsAndConditions'] ?? []),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
      createdBy: json['createdBy'] as String?,
      isFeatured: json['isFeatured'] as bool? ?? false,
      maxRedemptionsPerUser: json['maxRedemptionsPerUser'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // Helper method to parse DateTime from either Timestamp or String
  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    
    if (dateValue is Timestamp) {
      return dateValue.toDate();
    } else if (dateValue is String) {
      return DateTime.parse(dateValue);
    } else if (dateValue is DateTime) {
      return dateValue;
    }
    
    return null;
  }

  factory Reward.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reward.fromJson({...data, 'id': doc.id});
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'rewardType': rewardType.name,
      'pointsCost': pointsCost,
      'stockQuantity': stockQuantity,
      'redemptionCount': redemptionCount,
      'category': category.name,
      'isActive': isActive,
      'expiryDate': expiryDate?.toIso8601String(),
      'deliveryInfo': deliveryInfo?.toJson(),
      'termsAndConditions': termsAndConditions,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'isFeatured': isFeatured,
      'maxRedemptionsPerUser': maxRedemptionsPerUser,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'rewardType': rewardType.name,
      'pointsCost': pointsCost,
      'stockQuantity': stockQuantity,
      'redemptionCount': redemptionCount,
      'category': category.name,
      'isActive': isActive,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'deliveryInfo': deliveryInfo?.toJson(),
      'termsAndConditions': termsAndConditions,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'isFeatured': isFeatured,
      'maxRedemptionsPerUser': maxRedemptionsPerUser,
      'metadata': metadata,
    };
  }

  Reward copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    RewardType? rewardType,
    int? pointsCost,
    int? stockQuantity,
    int? redemptionCount,
    RewardCategory? category,
    bool? isActive,
    DateTime? expiryDate,
    DeliveryInfo? deliveryInfo,
    List<String>? termsAndConditions,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool? isFeatured,
    int? maxRedemptionsPerUser,
    Map<String, dynamic>? metadata,
  }) {
    return Reward(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      rewardType: rewardType ?? this.rewardType,
      pointsCost: pointsCost ?? this.pointsCost,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      redemptionCount: redemptionCount ?? this.redemptionCount,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      expiryDate: expiryDate ?? this.expiryDate,
      deliveryInfo: deliveryInfo ?? this.deliveryInfo,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      isFeatured: isFeatured ?? this.isFeatured,
      maxRedemptionsPerUser: maxRedemptionsPerUser ?? this.maxRedemptionsPerUser,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isInStock => stockQuantity > 0;
  bool get isExpired => expiryDate != null && DateTime.now().isAfter(expiryDate!);
  bool get canBeRedeemed => isActive && isInStock && !isExpired;
  String get stockStatus {
    if (!isActive) return 'Inactive';
    if (isExpired) return 'Expired';
    if (stockQuantity == 0) return 'Out of Stock';
    if (stockQuantity <= 5) return 'Low Stock';
    return 'In Stock';
  }
}

enum RewardType {
  digital,
  physical,

}

enum RewardCategory {
  voucher,
  coupon,
  merchandise,
  electronics,
  giftCard,
  experience,
  food,
  entertainment,
  travel,
  fashion,
  health,
  sports,
}

class DeliveryInfo {
  final bool requiresAddress;
  final double? shippingCost;
  final int? estimatedDays;
  final List<String> availableCountries;
  final String? shippingProvider;
  final Map<String, dynamic>? shippingOptions;

  DeliveryInfo({
    this.requiresAddress = false,
    this.shippingCost,
    this.estimatedDays,
    this.availableCountries = const [],
    this.shippingProvider,
    this.shippingOptions,
  });

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryInfo(
      requiresAddress: json['requiresAddress'] as bool? ?? false,
      shippingCost: json['shippingCost']?.toDouble(),
      estimatedDays: json['estimatedDays'] as int?,
      availableCountries: List<String>.from(json['availableCountries'] ?? []),
      shippingProvider: json['shippingProvider'] as String?,
      shippingOptions: json['shippingOptions'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requiresAddress': requiresAddress,
      'shippingCost': shippingCost,
      'estimatedDays': estimatedDays,
      'availableCountries': availableCountries,
      'shippingProvider': shippingProvider,
      'shippingOptions': shippingOptions,
    };
  }
}

