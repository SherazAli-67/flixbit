import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/offer_model.dart';
import '../service/offer_service.dart';

class OffersProvider extends ChangeNotifier {
  final OfferService _offerService = OfferService();

  // Offers lists
  List<Offer> _offers = [];
  List<Offer> _nearbyOffers = [];
  List<Offer> _followedOffers = [];
  List<OfferRedemption> _redemptions = [];

  // State
  bool _loading = false;
  String? _error;

  // Filters
  String? _selectedCategory;
  String? _searchQuery;

  // Stream subscriptions
  StreamSubscription? _offersSubscription;
  StreamSubscription? _nearbySubscription;
  StreamSubscription? _followedSubscription;
  StreamSubscription? _redemptionsSubscription;

  // Getters
  List<Offer> get offers => _offers;
  List<Offer> get nearbyOffers => _nearbyOffers;
  List<Offer> get followedOffers => _followedOffers;
  List<OfferRedemption> get redemptions => _redemptions;
  bool get loading => _loading;
  String? get error => _error;
  String? get selectedCategory => _selectedCategory;
  String? get searchQuery => _searchQuery;

  /// Get filtered offers
  List<Offer> get filteredOffers {
    var filtered = _offers;

    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered.where((offer) => offer.category == _selectedCategory).toList();
    }

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filtered = filtered.where((offer) {
        return offer.title.toLowerCase().contains(query) ||
            offer.description.toLowerCase().contains(query) ||
            (offer.category?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  // ==================== LOAD OFFERS ====================

  /// Load all active offers
  Future<void> loadActiveOffers({String? category, String? sellerId}) async {
    try {
      _setLoading(true);
      _clearError();

      await _offersSubscription?.cancel();

      _offersSubscription = _offerService
          .getActiveOffers(category: category, sellerId: sellerId)
          .listen(
            (offers) {
              _offers = offers;
              _setLoading(false);
              notifyListeners();
            },
            onError: (e) {
              _setError('Failed to load offers: $e');
              _setLoading(false);
            },
          );
    } catch (e) {
      _setError('Failed to load offers: $e');
      _setLoading(false);
    }
  }

  /// Load nearby offers based on location
  Future<void> loadNearbyOffers(GeoPoint userLocation, double radiusKm) async {
    try {
      _setLoading(true);
      _clearError();

      await _nearbySubscription?.cancel();

      _nearbySubscription = _offerService
          .getNearbyOffers(userLocation, radiusKm)
          .listen(
            (offers) {
              _nearbyOffers = offers;
              _setLoading(false);
              notifyListeners();
            },
            onError: (e) {
              _setError('Failed to load nearby offers: $e');
              _setLoading(false);
            },
          );
    } catch (e) {
      _setError('Failed to load nearby offers: $e');
      _setLoading(false);
    }
  }

  /// Load offers from followed sellers
  Future<void> loadFollowedSellersOffers(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      await _followedSubscription?.cancel();

      _followedSubscription = _offerService
          .getFollowedSellersOffers(userId)
          .listen(
            (offers) {
              _followedOffers = offers;
              _setLoading(false);
              notifyListeners();
            },
            onError: (e) {

              debugPrint("Failed to load offers: $e");
              _setError('Failed to load followed sellers offers: $e');
              _setLoading(false);
            },
          );
    } catch (e) {
      _setError('Failed to load followed sellers offers: $e');
      _setLoading(false);
    }
  }

  /// Load user's redemption history
  Future<void> loadUserRedemptions(String userId) async {
    try {
      await _redemptionsSubscription?.cancel();

      _redemptionsSubscription = _offerService
          .getUserRedemptions(userId)
          .listen(
            (redemptions) {
              _redemptions = redemptions;
              notifyListeners();
            },
            onError: (e) {
              debugPrint('Failed to load redemptions: $e');
            },
          );
    } catch (e) {
      debugPrint('Failed to load redemptions: $e');
    }
  }

  // ==================== REDEEM OFFER ====================

  /// Redeem an offer
  Future<OfferRedemption?> redeemOffer({
    required String userId,
    required String offerId,
    required String method,
    String? qrCodeData,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final redemption = await _offerService.redeemOffer(
        userId: userId,
        offerId: offerId,
        method: method,
        qrCodeData: qrCodeData,
      );

      _setLoading(false);
      notifyListeners();

      return redemption;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  /// Mark redemption as used
  Future<void> markRedemptionAsUsed(String redemptionId) async {
    try {
      await _offerService.markRedemptionAsUsed(redemptionId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to mark redemption as used: $e');
    }
  }

  // ==================== FILTERS ====================

  /// Set category filter
  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Set search query
  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _selectedCategory = null;
    _searchQuery = null;
    notifyListeners();
  }

  // ==================== ANALYTICS ====================

  /// Increment offer view count
  Future<void> incrementViewCount(String offerId) async {
    try {
      await _offerService.incrementViewCount(offerId);
    } catch (e) {
      debugPrint('Failed to increment view count: $e');
    }
  }

  /// Check if user has redeemed an offer
  Future<bool> hasUserRedeemed(String userId, String offerId) async {
    return await _offerService.hasUserRedeemed(userId, offerId);
  }

  /// Get offer by ID
  Future<Offer?> getOfferById(String offerId) async {
    return await _offerService.getOfferById(offerId);
  }

  // ==================== SEARCH ====================

  /// Search offers
  void searchOffers(String query) async {
    try {
      _setLoading(true);
      _clearError();

      await _offersSubscription?.cancel();

      _offersSubscription = _offerService
          .searchOffers(query)
          .listen(
            (offers) {
              _offers = offers;
              _setLoading(false);
              notifyListeners();
            },
            onError: (e) {
              _setError('Search failed: $e');
              _setLoading(false);
            },
          );
    } catch (e) {
      _setError('Search failed: $e');
      _setLoading(false);
    }
  }

  // ==================== HELPER METHODS ====================

  void _setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Refresh offers
  Future<void> refresh({
    String? category,
    String? sellerId,
  }) async {
    await loadActiveOffers(category: category, sellerId: sellerId);
  }

  @override
  void dispose() {
    _offersSubscription?.cancel();
    _nearbySubscription?.cancel();
    _followedSubscription?.cancel();
    _redemptionsSubscription?.cancel();
    super.dispose();
  }
}

