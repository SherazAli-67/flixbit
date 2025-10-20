import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/offer_model.dart';
import '../service/offer_service.dart';

class SellerOffersProvider extends ChangeNotifier {
  final OfferService _offerService = OfferService();

  // Offers by status
  List<Offer> _activeOffers = [];
  List<Offer> _pendingOffers = [];
  List<Offer> _rejectedOffers = [];
  List<Offer> _expiredOffers = [];

  // Analytics
  Map<String, dynamic>? _analytics;

  // State
  bool _loading = false;
  String? _error;

  // Stream subscriptions
  StreamSubscription? _activeSubscription;
  StreamSubscription? _pendingSubscription;

  // Getters
  List<Offer> get activeOffers => _activeOffers;
  List<Offer> get pendingOffers => _pendingOffers;
  List<Offer> get rejectedOffers => _rejectedOffers;
  List<Offer> get expiredOffers => _expiredOffers;
  Map<String, dynamic>? get analytics => _analytics;
  bool get loading => _loading;
  String? get error => _error;

  /// Get all offers (combined)
  List<Offer> get allOffers {
    return [
      ..._activeOffers,
      ..._pendingOffers,
      ..._rejectedOffers,
      ..._expiredOffers,
    ];
  }

  // ==================== CREATE & UPDATE ====================

  /// Create a new offer
  Future<Offer?> createOffer({
    required String sellerId,
    required String title,
    required String description,
    required OfferType type,
    required DateTime validFrom,
    required DateTime validUntil,
    String? imageUrl,
    String? videoUrl,
    double? discountPercentage,
    double? discountAmount,
    String? discountCode,
    int? maxRedemptions,
    String? category,
    double? minPurchaseAmount,
    List<String>? termsAndConditions,
    bool requiresReview = false,
    int reviewPointsReward = 15,
    GeoPoint? targetLocation,
    double? targetRadiusKm,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final offer = await _offerService.createOffer(
        sellerId: sellerId,
        title: title,
        description: description,
        type: type,
        validFrom: validFrom,
        validUntil: validUntil,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        discountPercentage: discountPercentage,
        discountAmount: discountAmount,
        discountCode: discountCode,
        maxRedemptions: maxRedemptions,
        category: category,
        minPurchaseAmount: minPurchaseAmount,
        termsAndConditions: termsAndConditions,
        requiresReview: requiresReview,
        reviewPointsReward: reviewPointsReward,
        targetLocation: targetLocation,
        targetRadiusKm: targetRadiusKm,
      );

      _setLoading(false);
      notifyListeners();

      return offer;
    } catch (e) {
      _setError('Failed to create offer: $e');
      _setLoading(false);
      return null;
    }
  }

  /// Update an existing offer
  Future<bool> updateOffer(String offerId, Map<String, dynamic> updates) async {
    try {
      _setLoading(true);
      _clearError();

      await _offerService.updateOffer(offerId, updates);

      _setLoading(false);
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to update offer: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Delete an offer
  Future<bool> deleteOffer(String offerId) async {
    try {
      _setLoading(true);
      _clearError();

      await _offerService.deleteOffer(offerId);

      _setLoading(false);
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to delete offer: $e');
      _setLoading(false);
      return false;
    }
  }

  // ==================== LOAD OFFERS ====================

  /// Load seller's offers
  Future<void> loadMyOffers(String sellerId) async {
    try {
      _setLoading(true);
      _clearError();

      // Load active offers
      await _activeSubscription?.cancel();
      _activeSubscription = _offerService
          .getSellerOffers(sellerId, status: ApprovalStatus.approved)
          .listen(
            (offers) {
              _activeOffers = offers.where((o) => !o.isExpired).toList();
              _expiredOffers = offers.where((o) => o.isExpired).toList();
              notifyListeners();
            },
            onError: (e) => debugPrint('Error loading active offers: $e'),
          );

      // Load pending offers
      await _pendingSubscription?.cancel();
      _pendingSubscription = _offerService
          .getSellerOffers(sellerId, status: ApprovalStatus.pending)
          .listen(
            (offers) {
              _pendingOffers = offers;
              notifyListeners();
            },
            onError: (e) => debugPrint('Error loading pending offers: $e'),
          );

      // Load rejected offers (one-time fetch)
      final rejectedStream = _offerService.getSellerOffers(
        sellerId,
        status: ApprovalStatus.rejected,
      );
      _rejectedOffers = await rejectedStream.first;

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load offers: $e');
      _setLoading(false);
    }
  }

  // ==================== ANALYTICS ====================

  /// Load analytics for a specific offer
  Future<void> loadOfferAnalytics(String offerId) async {
    try {
      _analytics = await _offerService.getOfferAnalytics(offerId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load analytics: $e');
    }
  }

  /// Get analytics summary for all seller's offers
  Future<Map<String, dynamic>> getSummaryAnalytics() async {
    try {
      int totalViews = 0;
      int totalRedemptions = 0;
      int totalActive = _activeOffers.length;
      int totalPending = _pendingOffers.length;

      for (final offer in _activeOffers) {
        totalViews += offer.viewCount;
        totalRedemptions += offer.currentRedemptions;
      }

      final conversionRate = totalViews > 0
          ? (totalRedemptions / totalViews * 100).toStringAsFixed(1)
          : '0.0';

      return {
        'totalOffers': allOffers.length,
        'activeOffers': totalActive,
        'pendingOffers': totalPending,
        'expiredOffers': _expiredOffers.length,
        'totalViews': totalViews,
        'totalRedemptions': totalRedemptions,
        'conversionRate': '$conversionRate%',
        'averageRedemptionsPerOffer': totalActive > 0
            ? (totalRedemptions / totalActive).toStringAsFixed(1)
            : '0',
      };
    } catch (e) {
      debugPrint('Failed to calculate summary analytics: $e');
      return {};
    }
  }

  // ==================== OFFER MANAGEMENT ====================

  /// Toggle offer active status
  Future<bool> toggleOfferStatus(String offerId, bool isActive) async {
    return await updateOffer(offerId, {'isActive': isActive});
  }

  /// Clone an offer
  Future<Offer?> cloneOffer(String sellerId, Offer originalOffer) async {
    return await createOffer(
      sellerId: sellerId,
      title: '${originalOffer.title} (Copy)',
      description: originalOffer.description,
      type: originalOffer.type,
      validFrom: DateTime.now(),
      validUntil: DateTime.now().add(const Duration(days: 30)),
      imageUrl: originalOffer.imageUrl,
      videoUrl: originalOffer.videoUrl,
      discountPercentage: originalOffer.discountPercentage,
      discountAmount: originalOffer.discountAmount,
      discountCode: originalOffer.discountCode,
      maxRedemptions: originalOffer.maxRedemptions,
      category: originalOffer.category,
      minPurchaseAmount: originalOffer.minPurchaseAmount,
      termsAndConditions: originalOffer.termsAndConditions,
      requiresReview: originalOffer.requiresReview,
      reviewPointsReward: originalOffer.reviewPointsReward,
      targetLocation: originalOffer.targetLocation,
      targetRadiusKm: originalOffer.targetRadiusKm,
    );
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

  /// Refresh all offers
  Future<void> refresh(String sellerId) async {
    await loadMyOffers(sellerId);
  }

  /// Get offer by ID from local state
  Offer? getLocalOfferById(String offerId) {
    try {
      return allOffers.firstWhere((offer) => offer.id == offerId);
    } catch (e) {
      return null;
    }
  }

  /// Get offers by category
  List<Offer> getOffersByCategory(String category) {
    return allOffers.where((offer) => offer.category == category).toList();
  }

  /// Get offers by type
  List<Offer> getOffersByType(OfferType type) {
    return allOffers.where((offer) => offer.type == type).toList();
  }

  /// Get top performing offers (by redemptions)
  List<Offer> getTopPerformingOffers({int limit = 5}) {
    final sorted = List<Offer>.from(_activeOffers)
      ..sort((a, b) => b.currentRedemptions.compareTo(a.currentRedemptions));
    return sorted.take(limit).toList();
  }

  /// Get offers expiring soon (within 7 days)
  List<Offer> getExpiringSoonOffers() {
    final now = DateTime.now();
    final threshold = now.add(const Duration(days: 7));

    return _activeOffers.where((offer) {
      return offer.validUntil.isAfter(now) &&
          offer.validUntil.isBefore(threshold);
    }).toList();
  }

  @override
  void dispose() {
    _activeSubscription?.cancel();
    _pendingSubscription?.cancel();
    super.dispose();
  }
}

