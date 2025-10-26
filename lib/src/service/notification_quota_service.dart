import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../res/firebase_constants.dart';

class NotificationQuotaService {
  // Singleton pattern
  static final NotificationQuotaService _instance = NotificationQuotaService._internal();
  factory NotificationQuotaService() => _instance;
  NotificationQuotaService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Default quota settings
  static const int defaultFreeQuota = 100; // notifications per month
  static const int defaultMaxPerDay = 1; // max notifications per user per day

  /// Get seller's quota information
  Future<QuotaInfo> getSellerQuota(String sellerId) async {
    try {
      final quotaDoc = await _firestore
          .collection(FirebaseConstants.notificationQuotaCollection)
          .doc(sellerId)
          .get();

      if (!quotaDoc.exists) {
        // Create default quota for new seller
        return await _createDefaultQuota(sellerId);
      }

      final data = quotaDoc.data()!;
      return QuotaInfo.fromJson(data);
    } catch (e) {
      debugPrint('Error getting seller quota: $e');
      return QuotaInfo.empty(sellerId);
    }
  }

  /// Check if seller has quota available for sending notifications
  Future<bool> hasQuotaAvailable(String sellerId, int count) async {
    try {
      final quotaInfo = await getSellerQuota(sellerId);
      return quotaInfo.remainingQuota >= count;
    } catch (e) {
      debugPrint('Error checking quota availability: $e');
      return false;
    }
  }

  /// Consume quota when sending notifications
  Future<void> consumeQuota(String sellerId, int count) async {
    try {
      final quotaRef = _firestore
          .collection(FirebaseConstants.notificationQuotaCollection)
          .doc(sellerId);

      await _firestore.runTransaction((transaction) async {
        final quotaDoc = await transaction.get(quotaRef);
        
        if (!quotaDoc.exists) {
          // Create default quota if doesn't exist
          final defaultQuota = await _createDefaultQuota(sellerId);
          transaction.set(quotaRef, defaultQuota.toJson());
        }

        final currentData = quotaDoc.data()!;
        final currentUsed = currentData['usedQuota'] ?? 0;
        final currentPurchased = currentData['purchasedQuota'] ?? 0;
        
        int newUsedQuota = currentUsed + count;
        int newPurchasedQuota = currentPurchased;
        
        // Deduct from purchased quota first, then free quota
        if (newUsedQuota > defaultFreeQuota) {
          final excess = newUsedQuota - defaultFreeQuota;
          if (excess <= currentPurchased) {
            newPurchasedQuota = currentPurchased - excess;
            newUsedQuota = defaultFreeQuota;
          } else {
            throw Exception('Insufficient quota available');
          }
        }

        transaction.update(quotaRef, {
          'usedQuota': newUsedQuota,
          'purchasedQuota': newPurchasedQuota,
          'remainingQuota': (defaultFreeQuota - newUsedQuota) + newPurchasedQuota,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Log quota transaction
        await _logQuotaTransaction(sellerId, count, 'used');
      });

      debugPrint('Quota consumed: $count notifications for seller $sellerId');
    } catch (e) {
      debugPrint('Error consuming quota: $e');
      rethrow;
    }
  }

  /// Purchase additional quota
  Future<void> purchaseQuota(String sellerId, int count, double amount) async {
    try {
      final quotaRef = _firestore
          .collection(FirebaseConstants.notificationQuotaCollection)
          .doc(sellerId);

      await _firestore.runTransaction((transaction) async {
        final quotaDoc = await transaction.get(quotaRef);
        
        if (!quotaDoc.exists) {
          // Create default quota if doesn't exist
          final defaultQuota = await _createDefaultQuota(sellerId);
          transaction.set(quotaRef, defaultQuota.toJson());
        }

        final currentData = quotaDoc.data()!;
        final currentPurchased = currentData['purchasedQuota'] ?? 0;
        final currentUsed = currentData['usedQuota'] ?? 0;
        final currentFree = defaultFreeQuota;

        transaction.update(quotaRef, {
          'purchasedQuota': currentPurchased + count,
          'remainingQuota': (currentFree - currentUsed) + (currentPurchased + count),
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Log quota transaction
        await _logQuotaTransaction(sellerId, count, 'purchased', purchaseAmount: amount);
      });

      debugPrint('Quota purchased: $count notifications for seller $sellerId');
    } catch (e) {
      debugPrint('Error purchasing quota: $e');
      rethrow;
    }
  }

  /// Get quota transaction history
  Future<List<QuotaTransaction>> getQuotaHistory(String sellerId) async {
    try {
      final transactionsSnapshot = await _firestore
          .collection(FirebaseConstants.notificationQuotaTransactionsCollection)
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return transactionsSnapshot.docs
          .map((doc) => QuotaTransaction.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting quota history: $e');
      return [];
    }
  }

  /// Reset monthly quota (called by admin or scheduled job)
  Future<void> resetMonthlyQuota(String sellerId) async {
    try {
      final quotaRef = _firestore
          .collection(FirebaseConstants.notificationQuotaCollection)
          .doc(sellerId);

      await _firestore.runTransaction((transaction) async {
        final quotaDoc = await transaction.get(quotaRef);
        
        if (!quotaDoc.exists) {
          return; // No quota to reset
        }

        final currentData = quotaDoc.data()!;
        final currentPurchased = currentData['purchasedQuota'] ?? 0;

        transaction.update(quotaRef, {
          'usedQuota': 0,
          'remainingQuota': defaultFreeQuota + currentPurchased,
          'resetDate': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Log quota reset
        await _logQuotaTransaction(sellerId, defaultFreeQuota, 'reset');
      });

      debugPrint('Monthly quota reset for seller $sellerId');
    } catch (e) {
      debugPrint('Error resetting monthly quota: $e');
      rethrow;
    }
  }

  /// Get quota usage percentage
  Future<double> getQuotaUsagePercentage(String sellerId) async {
    try {
      final quotaInfo = await getSellerQuota(sellerId);
      if (quotaInfo.totalQuota == 0) return 0.0;
      
      return (quotaInfo.usedQuota / quotaInfo.totalQuota) * 100;
    } catch (e) {
      debugPrint('Error getting quota usage percentage: $e');
      return 0.0;
    }
  }

  /// Check if quota is near limit (80% usage)
  Future<bool> isQuotaNearLimit(String sellerId) async {
    try {
      final usagePercentage = await getQuotaUsagePercentage(sellerId);
      return usagePercentage >= 80.0;
    } catch (e) {
      debugPrint('Error checking quota near limit: $e');
      return false;
    }
  }

  /// Create default quota for new seller
  Future<QuotaInfo> _createDefaultQuota(String sellerId) async {
    try {
      final now = DateTime.now();
      final resetDate = DateTime(now.year, now.month + 1, 1); // Next month 1st

      final defaultQuota = QuotaInfo(
        sellerId: sellerId,
        freeQuota: defaultFreeQuota,
        usedQuota: 0,
        purchasedQuota: 0,
        totalQuota: defaultFreeQuota,
        remainingQuota: defaultFreeQuota,
        resetDate: resetDate,
        lastUpdated: now,
        usagePercentage: 0.0,
      );

      await _firestore
          .collection(FirebaseConstants.notificationQuotaCollection)
          .doc(sellerId)
          .set(defaultQuota.toJson());

      debugPrint('Default quota created for seller $sellerId');
      return defaultQuota;
    } catch (e) {
      debugPrint('Error creating default quota: $e');
      return QuotaInfo.empty(sellerId);
    }
  }

  /// Log quota transaction
  Future<void> _logQuotaTransaction(
    String sellerId,
    int notificationCount,
    String type, {
    double? purchaseAmount,
    String? campaignId,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.notificationQuotaTransactionsCollection)
          .add({
        'sellerId': sellerId,
        'amount': notificationCount,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'campaignId': campaignId,
        'description': _getTransactionDescription(type, notificationCount),
        'purchaseAmount': purchaseAmount,
      });
    } catch (e) {
      debugPrint('Error logging quota transaction: $e');
    }
  }

  /// Get transaction description
  String _getTransactionDescription(String type, int amount) {
    switch (type) {
      case 'used':
        return 'Used $amount notifications';
      case 'purchased':
        return 'Purchased $amount notifications';
      case 'reset':
        return 'Monthly quota reset (+$amount)';
      default:
        return 'Quota transaction: $amount';
    }
  }

  /// Get quota statistics for admin dashboard
  Future<Map<String, dynamic>> getQuotaStatistics() async {
    try {
      final quotaSnapshot = await _firestore
          .collection(FirebaseConstants.notificationQuotaCollection)
          .get();

      int totalSellers = 0;
      int totalUsed = 0;
      int totalPurchased = 0;
      int sellersNearLimit = 0;

      for (final doc in quotaSnapshot.docs) {
        final data = doc.data();
        totalSellers++;
        totalUsed += (data['usedQuota'] as num? ?? 0).toInt();
        totalPurchased += (data['purchasedQuota'] as num? ?? 0).toInt();
        
        final usagePercentage = data['usagePercentage'] ?? 0.0;
        if (usagePercentage >= 80.0) {
          sellersNearLimit++;
        }
      }

      return {
        'totalSellers': totalSellers,
        'totalUsedQuota': totalUsed,
        'totalPurchasedQuota': totalPurchased,
        'sellersNearLimit': sellersNearLimit,
        'averageUsage': totalSellers > 0 ? (totalUsed / totalSellers) : 0,
      };
    } catch (e) {
      debugPrint('Error getting quota statistics: $e');
      return {};
    }
  }
}

/// Quota information model
class QuotaInfo {
  final String sellerId;
  final int freeQuota;
  final int usedQuota;
  final int purchasedQuota;
  final int totalQuota;
  final int remainingQuota;
  final DateTime resetDate;
  final DateTime lastUpdated;
  final double usagePercentage;

  QuotaInfo({
    required this.sellerId,
    required this.freeQuota,
    required this.usedQuota,
    required this.purchasedQuota,
    required this.totalQuota,
    required this.remainingQuota,
    required this.resetDate,
    required this.lastUpdated,
    required this.usagePercentage,
  });

  factory QuotaInfo.fromJson(Map<String, dynamic> json) {
    return QuotaInfo(
      sellerId: json['sellerId'] ?? '',
      freeQuota: (json['freeQuota'] ?? 0).toInt(),
      usedQuota: (json['usedQuota'] ?? 0).toInt(),
      purchasedQuota: (json['purchasedQuota'] ?? 0).toInt(),
      totalQuota: (json['totalQuota'] ?? 0).toInt(),
      remainingQuota: (json['remainingQuota'] ?? 0).toInt(),
      resetDate: json['resetDate'] != null
          ? DateTime.parse(json['resetDate'])
          : DateTime.now(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
      usagePercentage: (json['usagePercentage'] ?? 0.0).toDouble(),
    );
  }

  factory QuotaInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuotaInfo.fromJson(data);
  }

  factory QuotaInfo.empty(String sellerId) {
    final now = DateTime.now();
    return QuotaInfo(
      sellerId: sellerId,
      freeQuota: NotificationQuotaService.defaultFreeQuota,
      usedQuota: 0,
      purchasedQuota: 0,
      totalQuota: NotificationQuotaService.defaultFreeQuota,
      remainingQuota: NotificationQuotaService.defaultFreeQuota,
      resetDate: DateTime(now.year, now.month + 1, 1),
      lastUpdated: now,
      usagePercentage: 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sellerId': sellerId,
      'freeQuota': freeQuota,
      'usedQuota': usedQuota,
      'purchasedQuota': purchasedQuota,
      'totalQuota': totalQuota,
      'remainingQuota': remainingQuota,
      'resetDate': resetDate.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'usagePercentage': usagePercentage,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'freeQuota': freeQuota,
      'usedQuota': usedQuota,
      'purchasedQuota': purchasedQuota,
      'totalQuota': totalQuota,
      'remainingQuota': remainingQuota,
      'resetDate': Timestamp.fromDate(resetDate),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'usagePercentage': usagePercentage,
    };
  }

  QuotaInfo copyWith({
    String? sellerId,
    int? freeQuota,
    int? usedQuota,
    int? purchasedQuota,
    int? totalQuota,
    int? remainingQuota,
    DateTime? resetDate,
    DateTime? lastUpdated,
    double? usagePercentage,
  }) {
    return QuotaInfo(
      sellerId: sellerId ?? this.sellerId,
      freeQuota: freeQuota ?? this.freeQuota,
      usedQuota: usedQuota ?? this.usedQuota,
      purchasedQuota: purchasedQuota ?? this.purchasedQuota,
      totalQuota: totalQuota ?? this.totalQuota,
      remainingQuota: remainingQuota ?? this.remainingQuota,
      resetDate: resetDate ?? this.resetDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      usagePercentage: usagePercentage ?? this.usagePercentage,
    );
  }

  // Helper getters
  bool get isNearLimit => usagePercentage >= 80.0;
  bool get isAtLimit => usagePercentage >= 100.0;
  bool get hasRemainingQuota => remainingQuota > 0;
  
  String get usageDisplayText => '${usagePercentage.toStringAsFixed(1)}%';
  String get remainingDisplayText => '$remainingQuota notifications';
  
  String get resetDateDisplayText {
    final now = DateTime.now();
    final daysUntilReset = resetDate.difference(now).inDays;
    if (daysUntilReset <= 0) {
      return 'Resets today';
    } else if (daysUntilReset == 1) {
      return 'Resets tomorrow';
    } else {
      return 'Resets in $daysUntilReset days';
    }
  }
}

/// Quota transaction model
class QuotaTransaction {
  final String id;
  final String sellerId;
  final int amount;
  final String type;
  final DateTime timestamp;
  final String? campaignId;
  final String description;
  final double? purchaseAmount;

  QuotaTransaction({
    required this.id,
    required this.sellerId,
    required this.amount,
    required this.type,
    required this.timestamp,
    this.campaignId,
    required this.description,
    this.purchaseAmount,
  });

  factory QuotaTransaction.fromJson(Map<String, dynamic> json) {
    return QuotaTransaction(
      id: json['id'] ?? '',
      sellerId: json['sellerId'] ?? '',
      amount: (json['amount'] ?? 0).toInt(),
      type: json['type'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      campaignId: json['campaignId'],
      description: json['description'] ?? '',
      purchaseAmount: json['purchaseAmount']?.toDouble(),
    );
  }

  factory QuotaTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuotaTransaction.fromJson(data);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sellerId': sellerId,
      'amount': amount,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'campaignId': campaignId,
      'description': description,
      'purchaseAmount': purchaseAmount,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'sellerId': sellerId,
      'amount': amount,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'campaignId': campaignId,
      'description': description,
      'purchaseAmount': purchaseAmount,
    };
  }

  // Helper getters
  bool get isUsed => type == 'used';
  bool get isPurchased => type == 'purchased';
  bool get isReset => type == 'reset';
  
  String get typeDisplayText {
    switch (type) {
      case 'used':
        return 'Used';
      case 'purchased':
        return 'Purchased';
      case 'reset':
        return 'Reset';
      default:
        return 'Transaction';
    }
  }
  
  String get amountDisplayText {
    if (isUsed) {
      return '-$amount';
    } else if (isPurchased) {
      return '+$amount';
    } else if (isReset) {
      return '+$amount';
    } else {
      return '$amount';
    }
  }
}
