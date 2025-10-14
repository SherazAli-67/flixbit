import 'package:flutter/foundation.dart';
import '../models/wallet_models.dart';
import '../service/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _walletService = WalletService();
  
  WalletBalance? _balance;
  List<WalletTransaction> _transactions = [];
  WalletSettings? _settings;
  bool _isLoading = false;
  String? _error;

  // Getters
  WalletBalance? get balance => _balance;
  List<WalletTransaction> get transactions => _transactions;
  WalletSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize wallet for current user
  Future<void> initializeWallet(String userId) async {
    try {
      _setLoading(true);
      await _walletService.initializeWallet(userId);
      await _loadWalletData(userId);
    } catch (e) {
      _setError('Failed to initialize wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load wallet data
  Future<void> _loadWalletData(String userId) async {
    try {
      // Load settings
      _settings = await _walletService.getWalletSettings();
      
      // Subscribe to balance updates
      _walletService.getWalletBalance(userId).listen(
        (balance) {
          _balance = balance;
          notifyListeners();
        },
        onError: (e) => _setError('Failed to load balance: $e'),
      );

      // Load initial transactions
      await refreshTransactions(userId);
    } catch (e) {
      _setError('Failed to load wallet data: $e');
    }
  }

  // Refresh transactions
  Future<void> refreshTransactions(String userId) async {
    try {
      _setLoading(true);
      final stream = _walletService.getTransactionHistory(userId);
      await for (final transactions in stream) {
        _transactions = transactions;
        notifyListeners();
        break; // Only get the first update
      }
    } catch (e) {
      _setError('Failed to refresh transactions: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create a new transaction
  Future<WalletTransaction> createTransaction({
    required String userId,
    required TransactionType type,
    required double amount,
    required TransactionSource source,
    String? referenceId,
    Map<String, dynamic>? sourceDetails,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _setLoading(true);
      final transaction = await _walletService.createTransaction(
        userId: userId,
        type: type,
        amount: amount,
        source: source,
        referenceId: referenceId,
        sourceDetails: sourceDetails,
        metadata: metadata,
      );
      
      // Refresh transactions after creating new one
      await refreshTransactions(userId);
      return transaction;
    } catch (e) {
      _setError('Failed to create transaction: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Get filtered transactions
  List<WalletTransaction> getFilteredTransactions({
    TransactionType? type,
    TransactionSource? source,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _transactions.where((tx) {
      if (type != null && tx.type != type) return false;
      if (source != null && tx.source != source) return false;
      if (startDate != null && tx.timestamp.isBefore(startDate)) return false;
      if (endDate != null && tx.timestamp.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  // Get daily transaction summary
  Future<Map<String, num>> getDailySummary(String userId) async {
    try {
      return await _walletService.getDailyTransactionSummary(userId);
    } catch (e) {
      _setError('Failed to get daily summary: $e');
      rethrow;
    }
  }

  // Convert tournament points to Flixbit points
  Future<void> convertTournamentPoints(String userId, int points) async {
    try {
      _setLoading(true);
      await _walletService.convertTournamentPoints(userId, points);
      await refreshTransactions(userId);
    } catch (e) {
      _setError('Failed to convert points: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
