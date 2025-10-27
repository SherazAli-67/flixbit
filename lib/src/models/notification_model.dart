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
      case NotificationType.welcome:
        return 'Welcome';
      case NotificationType.thankYou:
        return 'Thank You';
      case NotificationType.offerReminder:
        return 'Offer Reminder';
      case NotificationType.reEngagement:
        return 'Re-engagement';
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
      case NotificationType.welcome:
        return '👋';
      case NotificationType.thankYou:
        return '🙏';
      case NotificationType.offerReminder:
        return '⏰';
      case NotificationType.reEngagement:
        return '💌';
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
  // QR System notification types
  welcome,
  thankYou,
  offerReminder,
  reEngagement,
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
  // QR System notification preferences
  final bool qrWelcomeEnabled;
  final bool qrThankYouEnabled;
  final bool qrOfferReminderEnabled;
  final bool qrReEngagementEnabled;
  final Map<String, bool> perSellerPreferences; // sellerId -> enabled
  final bool quietHoursEnabled;
  final String? quietHoursStart; // HH:mm format
  final String? quietHoursEnd; // HH:mm format
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
    this.qrWelcomeEnabled = true,
    this.qrThankYouEnabled = true,
    this.qrOfferReminderEnabled = true,
    this.qrReEngagementEnabled = true,
    this.perSellerPreferences = const {},
    this.quietHoursEnabled = false,
    this.quietHoursStart,
    this.quietHoursEnd,
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
      qrWelcomeEnabled: json['qrWelcomeEnabled'] as bool? ?? true,
      qrThankYouEnabled: json['qrThankYouEnabled'] as bool? ?? true,
      qrOfferReminderEnabled: json['qrOfferReminderEnabled'] as bool? ?? true,
      qrReEngagementEnabled: json['qrReEngagementEnabled'] as bool? ?? true,
      perSellerPreferences: Map<String, bool>.from(json['perSellerPreferences'] ?? {}),
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? false,
      quietHoursStart: json['quietHoursStart'] as String?,
      quietHoursEnd: json['quietHoursEnd'] as String?,
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
      'qrWelcomeEnabled': qrWelcomeEnabled,
      'qrThankYouEnabled': qrThankYouEnabled,
      'qrOfferReminderEnabled': qrOfferReminderEnabled,
      'qrReEngagementEnabled': qrReEngagementEnabled,
      'perSellerPreferences': perSellerPreferences,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
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
      'qrWelcomeEnabled': qrWelcomeEnabled,
      'qrThankYouEnabled': qrThankYouEnabled,
      'qrOfferReminderEnabled': qrOfferReminderEnabled,
      'qrReEngagementEnabled': qrReEngagementEnabled,
      'perSellerPreferences': perSellerPreferences,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

