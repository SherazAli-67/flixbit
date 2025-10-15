import 'package:flutter/foundation.dart';
import '../models/wallet_models.dart';
import '../service/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load wallet balance
      _balance = await WalletService.getWallet(userId);
      
      // Load transaction history
      _transactions = await WalletService.getTransactionHistory(
        userId: userId,
        limit: 100,
      );
      
      // Load settings
      _settings = await WalletService.getSettings();
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to initialize wallet: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh transactions
  Future<void> refreshTransactions(String userId) async {
    try {
      _balance = await WalletService.getWallet(userId);
      _transactions = await WalletService.getTransactionHistory(
        userId: userId,
        limit: 100,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to refresh transactions: $e');
      notifyListeners();
    }
  }

  // Purchase Flixbit points
  Future<void> purchasePoints({
    required String userId,
    required int points,
    required double amountUSD,
    required String paymentMethod,
    required String paymentId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await WalletService.purchasePoints(
        userId: userId,
        points: points,
        amountUSD: amountUSD,
        paymentMethod: paymentMethod,
        paymentId: paymentId,
      );
      
      // Refresh data after purchase
      await refreshTransactions(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sell Flixbit points
  Future<void> sellPoints({
    required String userId,
    required int points,
    required String payoutMethod,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await WalletService.sellPoints(
        userId: userId,
        points: points,
        payoutMethod: payoutMethod,
      );
      
      // Refresh data after sale
      await refreshTransactions(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get filtered transactions
  List<WalletTransaction> getFilteredTransactions({
    TransactionType? type,
    TransactionSource? source,
  }) {
    return _transactions.where((tx) {
      if (type != null && tx.type != type) return false;
      if (source != null && tx.source != source) return false;
      return true;
    }).toList();
  }

  // Get daily transaction summary
  Future<Map<String, num>> getDailySummary(String userId) async {
    try {
      return await WalletService.getDailySummary(userId);
    } catch (e) {
      debugPrint('Failed to get daily summary: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Convert tournament points to Flixbit points (not used in single currency system)
  // This method is kept for compatibility but tournament points are now just analytics
  Future<void> convertTournamentPoints(String userId, int points) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // In the new system, tournament points are just tracking
      // This method would be a no-op or could be removed
      // For now, show a message that conversion is not needed
      throw Exception('Tournament points are already Flixbit points. No conversion needed.');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
