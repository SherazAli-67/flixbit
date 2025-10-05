import 'package:flixbit/src/models/wheel_result_model.dart';

class Gift {
  final String id;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String recipientId;
  final double amount; // Original gift amount
  final DateTime sentAt;
  final DateTime expiresAt;
  final GiftStatus status;
  final double? wonAmount; // Amount after spinning
  final DateTime? claimedAt;
  final WheelResult? wheelResult;

  Gift({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.recipientId,
    required this.amount,
    required this.sentAt,
    required this.expiresAt,
    required this.status,
    this.wonAmount,
    this.claimedAt,
    this.wheelResult,
  });

  // Calculate days remaining until expiry
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 0;
    return expiresAt.difference(now).inDays;
  }

  // Check if gift is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  // JSON serialization
  factory Gift.fromJson(Map<String, dynamic> json) {
    return Gift(
      id: json['id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      senderEmail: json['sender_email'] ?? '',
      recipientId: json['recipient_id'],
      amount: json['amount'].toDouble(),
      sentAt: DateTime.parse(json['sent_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      status: GiftStatus.values.firstWhere(
            (e) => e.toString() == 'GiftStatus.${json['status']}',
      ),
      wonAmount: json['won_amount']?.toDouble(),
      claimedAt: json['claimed_at'] != null
          ? DateTime.parse(json['claimed_at'])
          : null,
      wheelResult: json['wheel_result'] != null
          ? WheelResult.fromJson(json['wheel_result'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_email': senderEmail,
      'recipient_id': recipientId,
      'amount': amount,
      'sent_at': sentAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'won_amount': wonAmount,
      'claimed_at': claimedAt?.toIso8601String(),
      'wheel_result': wheelResult?.toJson(),
    };
  }

  Gift copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderEmail,
    String? recipientId,
    double? amount,
    DateTime? sentAt,
    DateTime? expiresAt,
    GiftStatus? status,
    double? wonAmount,
    DateTime? claimedAt,
    WheelResult? wheelResult,
  }) {
    return Gift(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      recipientId: recipientId ?? this.recipientId,
      amount: amount ?? this.amount,
      sentAt: sentAt ?? this.sentAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      wonAmount: wonAmount ?? this.wonAmount,
      claimedAt: claimedAt ?? this.claimedAt,
      wheelResult: wheelResult ?? this.wheelResult,
    );
  }
}

enum GiftStatus {
  pending,    // Waiting to be claimed
  claimed,    // Spun and claimed
  expired,    // Not claimed within 30 days (refunded to sender)
  directClaim // User chose to add cash directly without spinning
}