// lib/services/gift_service.dart

import 'dart:math';
import 'package:flutter/cupertino.dart';

import '../config/wheel_config.dart';
import '../models/gift_model.dart';
import '../models/wheel_result_model.dart';

class GiftService {
  // Singleton pattern
  static final GiftService _instance = GiftService._internal();
  factory GiftService() => _instance;
  GiftService._internal();

  // Hard-coded mock data storage
  final List<Gift> _mockGifts = [];
  final Map<String, double> _mockWalletBalances = {
    'currentUser': 100.0,
    'user123': 250.0,
    'user456': 180.0,
  };

  // Initialize with some mock gifts
  void _initializeMockData() {
    if (_mockGifts.isEmpty) {
      _mockGifts.addAll([
        Gift(
          id: 'gift001',
          senderId: 'user123',
          senderName: 'John Doe',
          senderEmail: 'john.doe@example.com',
          recipientId: 'currentUser',
          amount: 50.0,
          sentAt: DateTime.now().subtract(Duration(days: 2)),
          expiresAt: DateTime.now().add(Duration(days: 28)),
          status: GiftStatus.pending,
        ),
        Gift(
          id: 'gift002',
          senderId: 'user456',
          senderName: 'Jane Smith',
          senderEmail: 'jane.smith@example.com',
          recipientId: 'currentUser',
          amount: 75.0,
          sentAt: DateTime.now().subtract(Duration(days: 5)),
          expiresAt: DateTime.now().add(Duration(days: 25)),
          status: GiftStatus.pending,
        ),
        Gift(
          id: 'gift003',
          senderId: 'user789',
          senderName: 'Mike Johnson',
          senderEmail: '+1-555-0123',
          recipientId: 'currentUser',
          amount: 100.0,
          sentAt: DateTime.now().subtract(Duration(hours: 3)),
          expiresAt: DateTime.now().add(Duration(days: 29)),
          status: GiftStatus.pending,
        ),
      ]);
    }
  }

  /// Fetch all pending gifts for current user
  Future<List<Gift>> getPendingGifts(String userId) async {
    try {
      _initializeMockData();

      // Simulate network delay
      await Future.delayed(Duration(milliseconds: 800));

      // Return only pending gifts for this user
      return _mockGifts
          .where((gift) =>
      gift.recipientId == userId &&
          gift.status == GiftStatus.pending &&
          !gift.isExpired)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch gifts: $e');
    }
  }

  /// Get a single gift by ID
  Future<Gift?> getGiftById(String giftId) async {
    await Future.delayed(Duration(milliseconds: 300));

    try {
      return _mockGifts.firstWhere((gift) => gift.id == giftId);
    } catch (e) {
      return null;
    }
  }

  /// Spin the wheel and get result
  Future<WheelResult> spinWheel(String giftId, double giftAmount) async {
    try {
      // Simulate network delay
      await Future.delayed(Duration(milliseconds: 1200));

      // Generate random result based on probabilities
      final segments = WheelConfig.defaultSegments;
      final totalWeight = segments.fold<int>(0, (sum, seg) => sum + seg.probability);
      final random = Random().nextInt(totalWeight);

      int cumulativeWeight = 0;
      int selectedIndex = 0;

      for (int i = 0; i < segments.length; i++) {
        cumulativeWeight += segments[i].probability;
        if (random < cumulativeWeight) {
          selectedIndex = i;
          break;
        }
      }

      final selectedSegment = segments[selectedIndex];
      final finalAmount = giftAmount * selectedSegment.multiplier;

      final result = WheelResult(
        segmentIndex: selectedIndex,
        multiplier: selectedSegment.multiplier,
        finalAmount: double.parse(finalAmount.toStringAsFixed(2)),
      );

      // Update the gift in mock storage
      final giftIndex = _mockGifts.indexWhere((g) => g.id == giftId);
      if (giftIndex != -1) {
        _mockGifts[giftIndex] = _mockGifts[giftIndex].copyWith(
          wheelResult: result,
          wonAmount: result.finalAmount,
        );
      }

      print('🎰 Wheel Result: Segment ${selectedIndex}, ${selectedSegment.label}, \$${result.finalAmount}');

      return result;
    } catch (e) {
      throw Exception('Failed to spin wheel: $e');
    }
  }

  /// Claim the gift and credit to wallet
  Future<bool> claimGift(String giftId, double amount) async {
    try {
      // Simulate network delay
      await Future.delayed(Duration(milliseconds: 1000));

      // Find the gift
      final giftIndex = _mockGifts.indexWhere((g) => g.id == giftId);
      if (giftIndex == -1) {
        throw Exception('Gift not found');
      }

      final gift = _mockGifts[giftIndex];

      // Update gift status
      _mockGifts[giftIndex] = gift.copyWith(
        status: GiftStatus.claimed,
        claimedAt: DateTime.now(),
      );

      // Credit to wallet
      _mockWalletBalances[gift.recipientId] =
          (_mockWalletBalances[gift.recipientId] ?? 0) + amount;

      final newBalance = _mockWalletBalances[gift.recipientId]!;

      print('💰 Gift claimed! \$${amount} added to wallet. New balance: \$${newBalance}');

      return true;
    } catch (e) {
      throw Exception('Failed to claim gift: $e');
    }
  }

  /// Add cash directly without spinning
  Future<bool> addCashDirectly(String giftId, double amount) async {
    try {
      // Simulate network delay
      await Future.delayed(Duration(milliseconds: 1000));

      // Find the gift
      final giftIndex = _mockGifts.indexWhere((g) => g.id == giftId);
      if (giftIndex == -1) {
        throw Exception('Gift not found');
      }

      final gift = _mockGifts[giftIndex];

      // Update gift status
      _mockGifts[giftIndex] = gift.copyWith(
        status: GiftStatus.directClaim,
        claimedAt: DateTime.now(),
        wonAmount: amount,
      );

      // Credit exact amount to wallet
      _mockWalletBalances[gift.recipientId] =
          (_mockWalletBalances[gift.recipientId] ?? 0) + amount;

      final newBalance = _mockWalletBalances[gift.recipientId]!;

      print('💵 Cash added directly! \$${amount} added to wallet. New balance: \$${newBalance}');

      return true;
    } catch (e) {
      throw Exception('Failed to add cash: $e');
    }
  }

  /// Send a gift to another user
  Future<Gift> sendGift({
    required String senderId,
    required String senderName,
    required String senderEmail,
    required String recipientId,
    required double amount,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(Duration(milliseconds: 1500));

      // Check if sender has enough balance
      final senderBalance = _mockWalletBalances[senderId] ?? 0;
      if (senderBalance < amount) {
        throw Exception('Insufficient balance. You have \$${senderBalance}');
      }

      // Deduct from sender's wallet
      _mockWalletBalances[senderId] = senderBalance - amount;

      // Create new gift
      final newGift = Gift(
        id: 'gift${DateTime.now().millisecondsSinceEpoch}',
        senderId: senderId,
        senderName: senderName,
        senderEmail: senderEmail,
        recipientId: recipientId,
        amount: amount,
        sentAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: 30)),
        status: GiftStatus.pending,
      );

      _mockGifts.add(newGift);

      debugPrint('🎁 Gift sent! \$${amount} from ${senderName} to ${recipientId}');
      debugPrint('   Sender new balance: \$${_mockWalletBalances[senderId]}');

      return newGift;
    } catch (e) {
      throw Exception('Failed to send gift: $e');
    }
  }

  /// Check for expired gifts and process refunds
  Future<int> processExpiredGifts() async {
    try {
      await Future.delayed(Duration(milliseconds: 500));

      int refundedCount = 0;
      final now = DateTime.now();

      for (int i = 0; i < _mockGifts.length; i++) {
        final gift = _mockGifts[i];

        if (gift.status == GiftStatus.pending && gift.isExpired) {
          // Refund to sender
          _mockWalletBalances[gift.senderId] =
              (_mockWalletBalances[gift.senderId] ?? 0) + gift.amount;

          // Update gift status
          _mockGifts[i] = gift.copyWith(status: GiftStatus.expired);

          refundedCount++;

          debugPrint('⏰ Expired gift refunded: \$${gift.amount} back to ${gift.senderName}');
        }
      }

      if (refundedCount > 0) {
        debugPrint('✅ Processed ${refundedCount} expired gifts');
      }

      return refundedCount;
    } catch (e) {
      throw Exception('Failed to process expired gifts: $e');
    }
  }

  /// Get gift history (sent and received)
  Future<Map<String, List<Gift>>> getGiftHistory(String userId) async {
    try {
      await Future.delayed(Duration(milliseconds: 800));

      final sentGifts = _mockGifts
          .where((gift) => gift.senderId == userId)
          .toList();

      final receivedGifts = _mockGifts
          .where((gift) => gift.recipientId == userId)
          .toList();

      return {
        'sent': sentGifts,
        'received': receivedGifts,
      };
    } catch (e) {
      throw Exception('Failed to fetch gift history: $e');
    }
  }

  /// Get wallet balance for a user
  Future<double> getWalletBalance(String userId) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _mockWalletBalances[userId] ?? 0.0;
  }

  /// Add funds to wallet (for testing)
  Future<bool> addFundsToWallet(String userId, double amount) async {
    await Future.delayed(Duration(milliseconds: 500));

    _mockWalletBalances[userId] =
        (_mockWalletBalances[userId] ?? 0) + amount;

    debugPrint('💳 Added \$${amount} to ${userId} wallet. New balance: \$${_mockWalletBalances[userId]}');

    return true;
  }

  /// Get statistics for dashboard
  Future<Map<String, dynamic>> getGiftStatistics(String userId) async {
    await Future.delayed(Duration(milliseconds: 600));

    final userGifts = _mockGifts.where((g) => g.recipientId == userId).toList();

    final totalReceived = userGifts.length;
    final totalClaimed = userGifts.where((g) =>
    g.status == GiftStatus.claimed || g.status == GiftStatus.directClaim).length;
    final totalPending = userGifts.where((g) =>
    g.status == GiftStatus.pending).length;
    final totalExpired = userGifts.where((g) =>
    g.status == GiftStatus.expired).length;

    final totalValue = userGifts
        .where((g) => g.status == GiftStatus.claimed || g.status == GiftStatus.directClaim)
        .fold<double>(0, (sum, g) => sum + (g.wonAmount ?? 0));

    return {
      'total_received': totalReceived,
      'total_claimed': totalClaimed,
      'total_pending': totalPending,
      'total_expired': totalExpired,
      'total_value_claimed': totalValue,
      'wallet_balance': _mockWalletBalances[userId] ?? 0,
    };
  }

  /// Clear all mock data (for testing/reset)
  void clearMockData() {
    _mockGifts.clear();
    _mockWalletBalances.clear();
    _mockWalletBalances['currentUser'] = 100.0;
    print('🗑️ All mock data cleared');
  }

  /// Get all gifts (for debugging)
  List<Gift> getAllGifts() {
    return List.unmodifiable(_mockGifts);
  }

  /// Print current state (for debugging)
  void printCurrentState() {
    debugPrint('\n═══════════════════════════════════════');
    debugPrint('📊 GIFT SERVICE CURRENT STATE');
    debugPrint('═══════════════════════════════════════');
    debugPrint('Total gifts: ${_mockGifts.length}');
    debugPrint('\nGifts:');
    for (var gift in _mockGifts) {
      debugPrint('  • ${gift.id}: \$${gift.amount} (${gift.status.toString().split('.').last})');
    }
    debugPrint('\nWallet Balances:');
    _mockWalletBalances.forEach((userId, balance) {
      debugPrint('  • ${userId}: \$${balance}');
    });
    debugPrint('═══════════════════════════════════════\n');
  }
}