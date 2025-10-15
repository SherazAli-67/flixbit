import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum defining different types of transactions
enum TransactionType {
  earn,    // Points earned from activities
  spend,   // Points spent on features
  buy,     // Points purchased
  sell,    // Points sold
  refund,  // Points refunded
  gift,    // Points received as gift
  reward   // Points from rewards
}

/// Enum defining transaction status
enum TransactionStatus {
  pending,
  completed,
  failed,
  reversed
}

/// Enum defining different sources of transactions
enum TransactionSource {
  // Tournament related
  tournamentPrediction,
  tournamentQualification,
  tournamentWin,
  tournamentEntry,
  
  // Engagement
  videoAd,
  referral,
  review,
  qrScan,
  dailyLogin,
  
  // Commerce
  purchase,
  gift,
  offer,
  reward,
  
  // System
  refund,
  conversion,
  adminAdjustment
}

/// Model representing a wallet transaction
class WalletTransaction {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final TransactionSource source;
  final String? referenceId;
  final Map<String, dynamic>? sourceDetails;
  final TransactionStatus status;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  WalletTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.source,
    this.referenceId,
    this.sourceDetails,
    required this.status,
    required this.timestamp,
    this.metadata,
  });

  /// Create from Firestore document
  factory WalletTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletTransaction(
      id: doc.id,
      userId: data['user_id'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${data['transaction_type']}'),
      amount: (data['amount'] as num).toDouble(),
      balanceBefore: (data['balance_before'] as num).toDouble(),
      balanceAfter: (data['balance_after'] as num).toDouble(),
      source: TransactionSource.values.firstWhere(
        (e) => e.toString() == 'TransactionSource.${data['source']['type']}'),
      referenceId: data['source']['reference_id'],
      sourceDetails: data['source']['details'],
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString() == 'TransactionStatus.${data['status']}'),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      metadata: data['metadata'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'transaction_type': type.toString().split('.').last,
      'amount': amount,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'source': {
        'type': source.toString().split('.').last,
        'reference_id': referenceId,
        'details': sourceDetails,
      },
      'status': status.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }
}

/// Model representing a user's wallet balance
class WalletBalance {
  final String userId;
  final double flixbitPoints;
  final int tournamentPoints;
  final DateTime lastUpdated;
  final String currency;
  final String status;
  final String accountType;
  final Map<String, num> limits;

  WalletBalance({
    required this.userId,
    required this.flixbitPoints,
    required this.tournamentPoints,
    required this.lastUpdated,
    this.currency = 'FLIXBIT',
    this.status = 'active',
    this.accountType = 'user',
    required this.limits,
  });

  /// Create from Firestore document
  factory WalletBalance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletBalance(
      userId: doc.id,
      flixbitPoints: (data['balance'] as num).toDouble(),
      tournamentPoints: (data['tournament_points'] as num).toInt(),
      lastUpdated: data['last_updated'] != null ? (data['last_updated'] as Timestamp).toDate() : DateTime.now(),
      currency: data['currency'] ?? 'FLIXBIT',
      status: data['status'] ?? 'active',
      accountType: data['account_type'] ?? 'user',
      limits: Map<String, num>.from(data['limits'] ?? {}),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'balance': flixbitPoints,
      'tournament_points': tournamentPoints,
      'last_updated': Timestamp.fromDate(lastUpdated),
      'currency': currency,
      'status': status,
      'account_type': accountType,
      'limits': limits,
    };
  }

  /// Create a copy with updated fields
  WalletBalance copyWith({
    double? flixbitPoints,
    int? tournamentPoints,
    DateTime? lastUpdated,
    String? currency,
    String? status,
    String? accountType,
    Map<String, num>? limits,
  }) {
    return WalletBalance(
      userId: this.userId,
      flixbitPoints: flixbitPoints ?? this.flixbitPoints,
      tournamentPoints: tournamentPoints ?? this.tournamentPoints,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      accountType: accountType ?? this.accountType,
      limits: limits ?? this.limits,
    );
  }
}

/// Model for wallet settings configuration
class WalletSettings {
  final Map<String, num> pointValues;
  final Map<String, num> conversionRates;
  final Map<String, num> transactionLimits;
  final Map<String, num> platformFees;

  WalletSettings({
    required this.pointValues,
    required this.conversionRates,
    required this.transactionLimits,
    required this.platformFees,
  });

  /// Create from Firestore document
  factory WalletSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletSettings(
      pointValues: Map<String, num>.from(data['point_values'] ?? {}),
      conversionRates: Map<String, num>.from(data['conversion_rates'] ?? {}),
      transactionLimits: Map<String, num>.from(data['transaction_limits'] ?? {}),
      platformFees: Map<String, num>.from(data['platform_fees'] ?? {}),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'point_values': pointValues,
      'conversion_rates': conversionRates,
      'transaction_limits': transactionLimits,
      'platform_fees': platformFees,
    };
  }

  /// Default settings
  factory WalletSettings.defaults() {
    return WalletSettings(
      pointValues: {
        'tournament_prediction': 10,
        'qualification': 50,
        'tournament_win': 500,
        'video_ad': 5,
        'referral': 20,
        'review': 15,
        'qr_scan': 10,
        'daily_login': 5,
      },
      conversionRates: {
        'flixbit_to_usd': 0.01,  // 1 Flixbit = $0.01
        'tournament_to_flixbit': 5,  // 1 Tournament Point = 5 Flixbit
      },
      transactionLimits: {
        'min_purchase': 100,
        'max_purchase': 10000,
        'daily_earning_cap': 1000,
        'min_withdrawal': 500,
      },
      platformFees: {
        'purchase_fee_percent': 2.5,  // 2.5%
        'withdrawal_fee_flat': 50,    // 50 Flixbit
      },
    );
  }
}
