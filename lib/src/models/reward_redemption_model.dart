import 'package:cloud_firestore/cloud_firestore.dart';

class RewardRedemption {
  final String id;
  final String userId;
  final String rewardId;
  final int pointsSpent;
  final String redemptionCode;
  final RedemptionStatus status;
  final DateTime redeemedAt;
  final DateTime? claimedAt;
  final DateTime? deliveredAt;
  final DateTime? expiresAt;
  final String? qrCodeData;
  final DeliveryAddress? deliveryAddress;
  final String? trackingNumber;
  final String? notes;
  final Map<String, dynamic>? metadata;

  RewardRedemption({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.pointsSpent,
    required this.redemptionCode,
    this.status = RedemptionStatus.active,
    required this.redeemedAt,
    this.claimedAt,
    this.deliveredAt,
    this.expiresAt,
    this.qrCodeData,
    this.deliveryAddress,
    this.trackingNumber,
    this.notes,
    this.metadata,
  });

  factory RewardRedemption.fromJson(Map<String, dynamic> json) {
    return RewardRedemption(
      id: json['id'] as String,
      userId: json['userId'] as String,
      rewardId: json['rewardId'] as String,
      pointsSpent: json['pointsSpent'] as int,
      redemptionCode: json['redemptionCode'] as String,
      status: RedemptionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RedemptionStatus.active,
      ),
      redeemedAt: DateTime.parse(json['redeemedAt'] as String),
      claimedAt: json['claimedAt'] != null 
          ? DateTime.parse(json['claimedAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null 
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      qrCodeData: json['qrCodeData'] as String?,
      deliveryAddress: json['deliveryAddress'] != null
          ? DeliveryAddress.fromJson(json['deliveryAddress'] as Map<String, dynamic>)
          : null,
      trackingNumber: json['trackingNumber'] as String?,
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  factory RewardRedemption.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RewardRedemption.fromJson({...data, 'id': doc.id});
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'rewardId': rewardId,
      'pointsSpent': pointsSpent,
      'redemptionCode': redemptionCode,
      'status': status.name,
      'redeemedAt': redeemedAt.toIso8601String(),
      'claimedAt': claimedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'qrCodeData': qrCodeData,
      'deliveryAddress': deliveryAddress?.toJson(),
      'trackingNumber': trackingNumber,
      'notes': notes,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'rewardId': rewardId,
      'pointsSpent': pointsSpent,
      'redemptionCode': redemptionCode,
      'status': status.name,
      'redeemedAt': Timestamp.fromDate(redeemedAt),
      'claimedAt': claimedAt != null ? Timestamp.fromDate(claimedAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'qrCodeData': qrCodeData,
      'deliveryAddress': deliveryAddress?.toJson(),
      'trackingNumber': trackingNumber,
      'notes': notes,
      'metadata': metadata,
    };
  }

  RewardRedemption copyWith({
    String? id,
    String? userId,
    String? rewardId,
    int? pointsSpent,
    String? redemptionCode,
    RedemptionStatus? status,
    DateTime? redeemedAt,
    DateTime? claimedAt,
    DateTime? deliveredAt,
    DateTime? expiresAt,
    String? qrCodeData,
    DeliveryAddress? deliveryAddress,
    String? trackingNumber,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return RewardRedemption(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      rewardId: rewardId ?? this.rewardId,
      pointsSpent: pointsSpent ?? this.pointsSpent,
      redemptionCode: redemptionCode ?? this.redemptionCode,
      status: status ?? this.status,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      claimedAt: claimedAt ?? this.claimedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      expiresAt: expiresAt ?? this.expiresAt,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isActive => status == RedemptionStatus.active;
  bool get isUsed => status == RedemptionStatus.used;
  bool get isExpired => status == RedemptionStatus.expired || 
      (expiresAt != null && DateTime.now().isAfter(expiresAt!));
  bool get isShipped => status == RedemptionStatus.shipped;
  bool get isDelivered => status == RedemptionStatus.delivered;
  bool get isCancelled => status == RedemptionStatus.cancelled;
  
  String get statusText {
    switch (status) {
      case RedemptionStatus.pending:
        return 'Pending';
      case RedemptionStatus.active:
        return 'Active';
      case RedemptionStatus.used:
        return 'Used';
      case RedemptionStatus.expired:
        return 'Expired';
      case RedemptionStatus.cancelled:
        return 'Cancelled';
      case RedemptionStatus.shipped:
        return 'Shipped';
      case RedemptionStatus.delivered:
        return 'Delivered';
    }
  }

  int? get daysUntilExpiry {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return 0;
    return expiresAt!.difference(now).inDays;
  }
}

enum RedemptionStatus {
  pending,
  active,
  used,
  expired,
  cancelled,
  shipped,
  delivered,
}

class DeliveryAddress {
  final String fullName;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? phoneNumber;
  final String? instructions;

  DeliveryAddress({
    required this.fullName,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.phoneNumber,
    this.instructions,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      fullName: json['fullName'] as String,
      addressLine1: json['addressLine1'] as String,
      addressLine2: json['addressLine2'] as String?,
      city: json['city'] as String,
      state: json['state'] as String,
      postalCode: json['postalCode'] as String,
      country: json['country'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      instructions: json['instructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'phoneNumber': phoneNumber,
      'instructions': instructions,
    };
  }

  String get fullAddress {
    final parts = [
      addressLine1,
      if (addressLine2 != null) addressLine2,
      city,
      state,
      postalCode,
      country,
    ];
    return parts.join(', ');
  }
}

