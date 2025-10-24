import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final String? imageUrl;
  final String? actionRoute;
  final String? actionText;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
    this.imageUrl,
    this.actionRoute,
    this.actionText,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.other,
      ),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      imageUrl: json['imageUrl'] as String?,
      actionRoute: json['actionRoute'] as String?,
      actionText: json['actionText'] as String?,
    );
  }

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification.fromJson({...data, 'id': doc.id});
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl,
      'actionRoute': actionRoute,
      'actionText': actionText,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
      'actionRoute': actionRoute,
      'actionText': actionText,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    String? imageUrl,
    String? actionRoute,
    String? actionText,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      actionRoute: actionRoute ?? this.actionRoute,
      actionText: actionText ?? this.actionText,
    );
  }

  // Helper methods
  String get typeDisplayName {
    switch (type) {
      case NotificationType.rewardRedemption:
        return 'Reward Redeemed';
      case NotificationType.rewardExpiring:
        return 'Reward Expiring';
      case NotificationType.rewardShipped:
        return 'Reward Shipped';
      case NotificationType.rewardDelivered:
        return 'Reward Delivered';
      case NotificationType.tournamentWin:
        return 'Tournament Win';
      case NotificationType.offerAvailable:
        return 'New Offer';
      case NotificationType.pointsEarned:
        return 'Points Earned';
      case NotificationType.other:
        return 'Notification';
    }
  }

  String get typeIcon {
    switch (type) {
      case NotificationType.rewardRedemption:
        return '🎉';
      case NotificationType.rewardExpiring:
        return '⏰';
      case NotificationType.rewardShipped:
        return '📦';
      case NotificationType.rewardDelivered:
        return '✅';
      case NotificationType.tournamentWin:
        return '🏆';
      case NotificationType.offerAvailable:
        return '🎁';
      case NotificationType.pointsEarned:
        return '💰';
      case NotificationType.other:
        return '📢';
    }
  }
}

enum NotificationType {
  rewardRedemption,
  rewardExpiring,
  rewardShipped,
  rewardDelivered,
  tournamentWin,
  offerAvailable,
  pointsEarned,
  other,
}

class NotificationSettings {
  final String userId;
  final bool pushNotificationsEnabled;
  final bool rewardNotificationsEnabled;
  final bool tournamentNotificationsEnabled;
  final bool offerNotificationsEnabled;
  final bool pointsNotificationsEnabled;
  final bool expiryWarningEnabled;
  final int expiryWarningDays; // Days before expiry to warn
  final DateTime updatedAt;

  NotificationSettings({
    required this.userId,
    this.pushNotificationsEnabled = true,
    this.rewardNotificationsEnabled = true,
    this.tournamentNotificationsEnabled = true,
    this.offerNotificationsEnabled = true,
    this.pointsNotificationsEnabled = true,
    this.expiryWarningEnabled = true,
    this.expiryWarningDays = 3,
    required this.updatedAt,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      userId: json['userId'] as String,
      pushNotificationsEnabled: json['pushNotificationsEnabled'] as bool? ?? true,
      rewardNotificationsEnabled: json['rewardNotificationsEnabled'] as bool? ?? true,
      tournamentNotificationsEnabled: json['tournamentNotificationsEnabled'] as bool? ?? true,
      offerNotificationsEnabled: json['offerNotificationsEnabled'] as bool? ?? true,
      pointsNotificationsEnabled: json['pointsNotificationsEnabled'] as bool? ?? true,
      expiryWarningEnabled: json['expiryWarningEnabled'] as bool? ?? true,
      expiryWarningDays: json['expiryWarningDays'] as int? ?? 3,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'rewardNotificationsEnabled': rewardNotificationsEnabled,
      'tournamentNotificationsEnabled': tournamentNotificationsEnabled,
      'offerNotificationsEnabled': offerNotificationsEnabled,
      'pointsNotificationsEnabled': pointsNotificationsEnabled,
      'expiryWarningEnabled': expiryWarningEnabled,
      'expiryWarningDays': expiryWarningDays,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'rewardNotificationsEnabled': rewardNotificationsEnabled,
      'tournamentNotificationsEnabled': tournamentNotificationsEnabled,
      'offerNotificationsEnabled': offerNotificationsEnabled,
      'pointsNotificationsEnabled': pointsNotificationsEnabled,
      'expiryWarningEnabled': expiryWarningEnabled,
      'expiryWarningDays': expiryWarningDays,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

