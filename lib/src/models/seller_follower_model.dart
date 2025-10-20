class SellerFollower {
  final String id;
  final String userId;
  final String sellerId;
  final DateTime followedAt;
  final String followSource; // qr_scan, offer_redemption, manual
  final bool notificationsEnabled;
  final Map<String, dynamic>? metadata;

  SellerFollower({
    required this.id,
    required this.userId,
    required this.sellerId,
    required this.followedAt,
    required this.followSource,
    this.notificationsEnabled = true,
    this.metadata,
  });

  factory SellerFollower.fromJson(Map<String, dynamic> json) {
    return SellerFollower(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      sellerId: json['sellerId'] ?? '',
      followedAt: DateTime.parse(json['followedAt']),
      followSource: json['followSource'] ?? 'manual',
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'sellerId': sellerId,
      'followedAt': followedAt.toIso8601String(),
      'followSource': followSource,
      'notificationsEnabled': notificationsEnabled,
      'metadata': metadata,
    };
  }

  SellerFollower copyWith({
    String? id,
    String? userId,
    String? sellerId,
    DateTime? followedAt,
    String? followSource,
    bool? notificationsEnabled,
    Map<String, dynamic>? metadata,
  }) {
    return SellerFollower(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sellerId: sellerId ?? this.sellerId,
      followedAt: followedAt ?? this.followedAt,
      followSource: followSource ?? this.followSource,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      metadata: metadata ?? this.metadata,
    );
  }
}

// Follow source constants
class FollowSource {
  static const String qrScan = 'qr_scan';
  static const String offerRedemption = 'offer_redemption';
  static const String manual = 'manual';
  static const String referral = 'referral';
  static const String tournament = 'tournament';
}

