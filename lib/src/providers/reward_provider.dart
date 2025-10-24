import 'package:flutter/foundation.dart';
import '../models/reward_model.dart';
import '../models/reward_redemption_model.dart';
import '../service/reward_service.dart';
import '../service/flixbit_points_manager.dart';

class RewardProvider with ChangeNotifier {
  final RewardService _rewardService = RewardService();

  // State variables
  List<Reward> _availableRewards = [];
  List<RewardRedemption> _userRedemptions = [];
  RewardCategory? _selectedCategory;
  String _sortBy = 'featured';
  bool _isLoading = false;
  String? _error;
  String? _userId;
  int _userBalance = 0;

  // Getters
  List<Reward> get availableRewards => _availableRewards;
  List<RewardRedemption> get userRedemptions => _userRedemptions;
  RewardCategory? get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get userBalance => _userBalance;

  // Filtered rewards based on user balance
  List<Reward> get affordableRewards => _availableRewards
      .where((reward) => reward.pointsCost <= _userBalance)
      .toList();

  // Active redemptions (not expired or used)
  List<RewardRedemption> get activeRedemptions => _userRedemptions
      .where((redemption) => redemption.isActive && !redemption.isExpired)
      .toList();

  // Expired redemptions
  List<RewardRedemption> get expiredRedemptions => _userRedemptions
      .where((redemption) => redemption.isExpired)
      .toList();

  // Used redemptions
  List<RewardRedemption> get usedRedemptions => _userRedemptions
      .where((redemption) => redemption.isUsed)
      .toList();

  /// Initialize provider with user ID
  Future<void> initialize(String userId) async {
    _userId = userId;
    await _loadUserBalance();
    await loadAvailableRewards();
    await loadUserRedemptions();
  }

  /// Load user's current Flixbit balance
  Future<void> _loadUserBalance() async {
    if (_userId == null) return;
    
    try {
      _userBalance = await FlixbitPointsManager.getUserBalance(_userId!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user balance: $e');
    }
  }

  /// Load available rewards
  Future<void> loadAvailableRewards() async {
    if (_userId == null) return;

    _setLoading(true);
    _clearError();

    try {
      _availableRewards = await _rewardService.getAffordableRewards(_userId!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load rewards: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Load user's redemption history
  Future<void> loadUserRedemptions() async {
    if (_userId == null) return;

    try {
      _userRedemptions = await _rewardService.getUserRedemptions(_userId!).first;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user redemptions: $e');
    }
  }

  /// Set category filter
  void setCategoryFilter(RewardCategory? category) {
    _selectedCategory = category;
    notifyListeners();
    _filterRewards();
  }

  /// Set sort option
  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
    _filterRewards();
  }

  /// Filter rewards based on current filters
  Future<void> _filterRewards() async {
    if (_userId == null) return;

    _setLoading(true);

    try {
      // Get filtered rewards from service
      final rewards = await _rewardService.getAffordableRewards(_userId!);
      
      // Apply local filters
      List<Reward> filteredRewards = rewards;

      // Category filter
      if (_selectedCategory != null) {
        filteredRewards = filteredRewards
            .where((reward) => reward.category == _selectedCategory)
            .toList();
      }

      // Sort
      switch (_sortBy) {
        case 'pointsCost':
          filteredRewards.sort((a, b) => a.pointsCost.compareTo(b.pointsCost));
          break;
        case 'createdAt':
          filteredRewards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'featured':
        default:
          filteredRewards.sort((a, b) {
            if (a.isFeatured && !b.isFeatured) return -1;
            if (!a.isFeatured && b.isFeatured) return 1;
            return b.createdAt.compareTo(a.createdAt);
          });
          break;
      }

      _availableRewards = filteredRewards;
      notifyListeners();
    } catch (e) {
      _setError('Failed to filter rewards: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Redeem a reward
  Future<RewardRedemption?> redeemReward({
    required String rewardId,
    DeliveryAddress? deliveryAddress,
  }) async {
    if (_userId == null) return null;

    _setLoading(true);
    _clearError();

    try {
      final redemption = await _rewardService.redeemReward(
        userId: _userId!,
        rewardId: rewardId,
        deliveryAddress: deliveryAddress,
      );

      if (redemption != null) {
        // Update user balance
        await _loadUserBalance();
        
        // Reload redemptions
        await loadUserRedemptions();
        
        // Reload available rewards (stock might have changed)
        await loadAvailableRewards();
        
        notifyListeners();
      }

      return redemption;
    } catch (e) {
      _setError('Failed to redeem reward: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Use a reward (mark as used)
  Future<bool> useReward(String redemptionId) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _rewardService.useReward(redemptionId);
      
      if (success) {
        // Reload redemptions to update status
        await loadUserRedemptions();
        notifyListeners();
      }

      return success;
    } catch (e) {
      _setError('Failed to use reward: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    if (_userId == null) return;
    
    await Future.wait([
      _loadUserBalance(),
      loadAvailableRewards(),
      loadUserRedemptions(),
    ]);
  }

  /// Get reward by ID
  Future<Reward?> getRewardById(String rewardId) async {
    try {
      return await _rewardService.getRewardById(rewardId);
    } catch (e) {
      debugPrint('Error getting reward by ID: $e');
      return null;
    }
  }

  /// Check if user can afford a reward
  bool canAffordReward(Reward reward) {
    return _userBalance >= reward.pointsCost;
  }

  /// Get user's redemption count for a specific reward
  int getUserRedemptionCount(String rewardId) {
    return _userRedemptions
        .where((redemption) => 
            redemption.rewardId == rewardId && 
            !redemption.isExpired && 
            !redemption.isCancelled)
        .length;
  }

  /// Check if user has reached redemption limit for a reward
  bool hasReachedRedemptionLimit(Reward reward) {
    if (reward.maxRedemptionsPerUser == null) return false;
    
    final userCount = getUserRedemptionCount(reward.id);
    return userCount >= reward.maxRedemptionsPerUser!;
  }

  /// Get available categories from current rewards
  List<RewardCategory> get availableCategories {
    final categories = _availableRewards
        .map((reward) => reward.category)
        .toSet()
        .toList();
    
    categories.sort((a, b) => a.name.compareTo(b.name));
    return categories;
  }

  /// Clear all filters
  void clearFilters() {
    _selectedCategory = null;
    _sortBy = 'featured';
    notifyListeners();
    _filterRewards();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

