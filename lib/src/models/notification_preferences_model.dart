import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationPreferences {
  // final String userId;
  final bool pushNotificationsEnabled;
  final bool rewardNotificationsEnabled;
  final bool tournamentNotificationsEnabled;
  final bool offerNotificationsEnabled;
  final bool pointsNotificationsEnabled;
  final bool expiryWarningEnabled;
  final int expiryWarningDays;
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

  NotificationPreferences({
    // required this.userId,
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

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      // userId: json['userId'] as String,
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
      updatedAt:  DateTime.now()
      // DateTime.parse(json['updatedAt'] as String

      // ),
    );
  }

  factory NotificationPreferences.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationPreferences.fromJson({...data, 'userId': doc.id});
  }

  Map<String, dynamic> toJson() {
    return {
      // 'userId': userId,
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

  NotificationPreferences copyWith({
    String? userId,
    bool? pushNotificationsEnabled,
    bool? rewardNotificationsEnabled,
    bool? tournamentNotificationsEnabled,
    bool? offerNotificationsEnabled,
    bool? pointsNotificationsEnabled,
    bool? expiryWarningEnabled,
    int? expiryWarningDays,
    bool? qrWelcomeEnabled,
    bool? qrThankYouEnabled,
    bool? qrOfferReminderEnabled,
    bool? qrReEngagementEnabled,
    Map<String, bool>? perSellerPreferences,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    DateTime? updatedAt,
  }) {
    return NotificationPreferences(
      // userId: userId ?? this.userId,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      rewardNotificationsEnabled: rewardNotificationsEnabled ?? this.rewardNotificationsEnabled,
      tournamentNotificationsEnabled: tournamentNotificationsEnabled ?? this.tournamentNotificationsEnabled,
      offerNotificationsEnabled: offerNotificationsEnabled ?? this.offerNotificationsEnabled,
      pointsNotificationsEnabled: pointsNotificationsEnabled ?? this.pointsNotificationsEnabled,
      expiryWarningEnabled: expiryWarningEnabled ?? this.expiryWarningEnabled,
      expiryWarningDays: expiryWarningDays ?? this.expiryWarningDays,
      qrWelcomeEnabled: qrWelcomeEnabled ?? this.qrWelcomeEnabled,
      qrThankYouEnabled: qrThankYouEnabled ?? this.qrThankYouEnabled,
      qrOfferReminderEnabled: qrOfferReminderEnabled ?? this.qrOfferReminderEnabled,
      qrReEngagementEnabled: qrReEngagementEnabled ?? this.qrReEngagementEnabled,
      perSellerPreferences: perSellerPreferences ?? this.perSellerPreferences,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool isNotificationTypeEnabled(String type) {
    switch (type) {
      case 'welcome':
        return qrWelcomeEnabled;
      case 'thank_you':
        return qrThankYouEnabled;
      case 'offer_reminder':
        return qrOfferReminderEnabled;
      case 're_engagement':
        return qrReEngagementEnabled;
      case 'reward_redemption':
        return rewardNotificationsEnabled;
      case 'tournament_win':
        return tournamentNotificationsEnabled;
      case 'offer_available':
        return offerNotificationsEnabled;
      case 'points_earned':
        return pointsNotificationsEnabled;
      default:
        return true;
    }
  }

  bool isSellerNotificationEnabled(String sellerId) {
    return perSellerPreferences[sellerId] ?? true;
  }


}
