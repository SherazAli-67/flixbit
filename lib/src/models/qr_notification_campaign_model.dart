import 'package:cloud_firestore/cloud_firestore.dart';

class QRNotificationCampaign {
  final String id;
  final String sellerId;
  final String title;
  final String message;
  final NotificationAudience audience;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final CampaignStatus status;
  final int targetCount;
  final int sentCount;
  final int deliveredCount;
  final int openedCount;
  final Map<String, dynamic>? filters;
  final String? actionRoute;
  final String? actionText;
  final DateTime? sentAt;
  final DateTime? completedAt;
  final String? errorMessage;

  QRNotificationCampaign({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.message,
    required this.audience,
    required this.createdAt,
    this.scheduledFor,
    this.status = CampaignStatus.draft,
    this.targetCount = 0,
    this.sentCount = 0,
    this.deliveredCount = 0,
    this.openedCount = 0,
    this.filters,
    this.actionRoute,
    this.actionText,
    this.sentAt,
    this.completedAt,
    this.errorMessage,
  });

  factory QRNotificationCampaign.fromJson(Map<String, dynamic> json) {
    return QRNotificationCampaign(
      id: json['id'] ?? '',
      sellerId: json['sellerId'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      audience: NotificationAudience.values.firstWhere(
        (e) => e.name == json['audience'],
        orElse: () => NotificationAudience.allFollowers,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      scheduledFor: json['scheduledFor'] != null
          ? DateTime.parse(json['scheduledFor'])
          : null,
      status: CampaignStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CampaignStatus.draft,
      ),
      targetCount: json['targetCount'] ?? 0,
      sentCount: json['sentCount'] ?? 0,
      deliveredCount: json['deliveredCount'] ?? 0,
      openedCount: json['openedCount'] ?? 0,
      filters: json['filters'],
      actionRoute: json['actionRoute'],
      actionText: json['actionText'],
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      errorMessage: json['errorMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sellerId': sellerId,
      'title': title,
      'message': message,
      'audience': audience.name,
      'createdAt': createdAt.toIso8601String(),
      'scheduledFor': scheduledFor?.toIso8601String(),
      'status': status.name,
      'targetCount': targetCount,
      'sentCount': sentCount,
      'deliveredCount': deliveredCount,
      'openedCount': openedCount,
      'filters': filters,
      'actionRoute': actionRoute,
      'actionText': actionText,
      'sentAt': sentAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'sellerId': sellerId,
      'title': title,
      'message': message,
      'audience': audience.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'scheduledFor': scheduledFor != null
          ? Timestamp.fromDate(scheduledFor!)
          : null,
      'status': status.name,
      'targetCount': targetCount,
      'sentCount': sentCount,
      'deliveredCount': deliveredCount,
      'openedCount': openedCount,
      'filters': filters,
      'actionRoute': actionRoute,
      'actionText': actionText,
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'errorMessage': errorMessage,
    };
  }

  factory QRNotificationCampaign.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QRNotificationCampaign.fromJson(data);
  }

  QRNotificationCampaign copyWith({
    String? id,
    String? sellerId,
    String? title,
    String? message,
    NotificationAudience? audience,
    DateTime? createdAt,
    DateTime? scheduledFor,
    CampaignStatus? status,
    int? targetCount,
    int? sentCount,
    int? deliveredCount,
    int? openedCount,
    Map<String, dynamic>? filters,
    String? actionRoute,
    String? actionText,
    DateTime? sentAt,
    DateTime? completedAt,
    String? errorMessage,
  }) {
    return QRNotificationCampaign(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      message: message ?? this.message,
      audience: audience ?? this.audience,
      createdAt: createdAt ?? this.createdAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      status: status ?? this.status,
      targetCount: targetCount ?? this.targetCount,
      sentCount: sentCount ?? this.sentCount,
      deliveredCount: deliveredCount ?? this.deliveredCount,
      openedCount: openedCount ?? this.openedCount,
      filters: filters ?? this.filters,
      actionRoute: actionRoute ?? this.actionRoute,
      actionText: actionText ?? this.actionText,
      sentAt: sentAt ?? this.sentAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // Helper methods
  double get deliveryRate {
    if (sentCount == 0) return 0.0;
    return (deliveredCount / sentCount) * 100;
  }

  double get openRate {
    if (deliveredCount == 0) return 0.0;
    return (openedCount / deliveredCount) * 100;
  }

  bool get isScheduled => status == CampaignStatus.scheduled;
  bool get isSent => status == CampaignStatus.sent;
  bool get isDraft => status == CampaignStatus.draft;
  bool get isFailed => status == CampaignStatus.failed;
  bool get isSending => status == CampaignStatus.sending;

  String get statusDisplayName {
    switch (status) {
      case CampaignStatus.draft:
        return 'Draft';
      case CampaignStatus.scheduled:
        return 'Scheduled';
      case CampaignStatus.sending:
        return 'Sending';
      case CampaignStatus.sent:
        return 'Sent';
      case CampaignStatus.failed:
        return 'Failed';
      case CampaignStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get audienceDisplayName {
    switch (audience) {
      case NotificationAudience.allFollowers:
        return 'All Followers';
      case NotificationAudience.qrScanFollowers:
        return 'QR Scan Followers';
      case NotificationAudience.offerFollowers:
        return 'Offer Followers';
      case NotificationAudience.manualFollowers:
        return 'Manual Followers';
      case NotificationAudience.dateRangeFollowers:
        return 'Date Range Followers';
      case NotificationAudience.custom:
        return 'Custom';
    }
  }
}

enum NotificationAudience {
  allFollowers,
  qrScanFollowers,
  offerFollowers,
  manualFollowers,
  dateRangeFollowers,
  custom,
}

enum CampaignStatus {
  draft,
  scheduled,
  sending,
  sent,
  failed,
  cancelled,
}

// Campaign filter types
class CampaignFilters {
  final String? followSource;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? notificationsEnabled;
  final List<String>? specificUserIds;

  CampaignFilters({
    this.followSource,
    this.startDate,
    this.endDate,
    this.notificationsEnabled,
    this.specificUserIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'followSource': followSource,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'notificationsEnabled': notificationsEnabled,
      'specificUserIds': specificUserIds,
    };
  }

  factory CampaignFilters.fromJson(Map<String, dynamic> json) {
    return CampaignFilters(
      followSource: json['followSource'],
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : null,
      notificationsEnabled: json['notificationsEnabled'],
      specificUserIds: json['specificUserIds'] != null
          ? List<String>.from(json['specificUserIds'])
          : null,
    );
  }
}
