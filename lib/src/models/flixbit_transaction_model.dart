class FlixbitTransaction {
  final String id;
  final String userId;
  final TransactionType type;
  final int amount;
  final int balanceBefore;
  final int balanceAfter;
  final TransactionSource source;
  final String description;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  FlixbitTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.source,
    required this.description,
    this.metadata,
    required this.timestamp,
  });

  factory FlixbitTransaction.fromJson(Map<String, dynamic> json) {
    return FlixbitTransaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.earned,
      ),
      amount: json['amount'] as int,
      balanceBefore: json['balanceBefore'] as int,
      balanceAfter: json['balanceAfter'] as int,
      source: TransactionSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => TransactionSource.other,
      ),
      description: json['description'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'source': source.name,
      'description': description,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

enum TransactionType {
  earned,
  spent,
  redeemed,
  refunded,
  transferred,
  purchased,
}

enum TransactionSource {
  tournamentPrediction,
  tournamentWin,
  tournamentQualification,
  tournamentEntry,
  videoAd,
  referralSignup,
  referralPrediction,
  sellerReview,
  offerReview,
  qrScan,
  dailyLogin,
  weeklyStreak,
  wheelOfFortune,
  rewardRedemption,
  giftSent,
  giftReceived,
  purchaseQualification,
  inAppPurchase,
  other,
}

