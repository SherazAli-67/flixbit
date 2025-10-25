import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/review_model.dart';
import '../models/seller_model.dart';
import '../models/offer_model.dart';
import '../service/review_service.dart';
import '../service/seller_follower_service.dart';

class ReviewsProvider extends ChangeNotifier {
  final ReviewService _reviewService = ReviewService();

  // State variables
  List<Review> _reviews = [];
  List<Seller> _sellers = [];
  List<Offer> _offers = [];
  Map<String, ReviewSummary> _reviewSummaries = {};
  Map<String, List<Review>> _sellerReviews = {};
  bool _isLoading = false;
  String? _error;

  // Stream subscriptions
  final Map<String, StreamSubscription<List<Review>>> _reviewSubscriptions = {};
  final Map<String, StreamSubscription<ReviewSummary?>> _summarySubscriptions = {};

  // Getters
  List<Review> get reviews => _reviews;
  List<Seller> get sellers => _sellers;
  List<Offer> get offers => _offers;
  Map<String, ReviewSummary> get reviewSummaries => _reviewSummaries;
  Map<String, List<Review>> get sellerReviews => _sellerReviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get reviews for a specific seller
  List<Review> getReviewsForSeller(String sellerId) {
    return _sellerReviews[sellerId] ?? [];
  }

  // Get review summary for a seller
  ReviewSummary? getReviewSummaryForSeller(String sellerId) {
    return _reviewSummaries[sellerId];
  }

  // Get top-rated sellers
  List<Seller> getTopRatedSellers({int limit = 10}) {
    final sellersWithReviews = _sellers.where((seller) => 
      seller.reviewSummary != null && seller.reviewSummary!.totalReviews > 0
    ).toList();
    
    sellersWithReviews.sort((a, b) => 
      b.reviewSummary!.averageRating.compareTo(a.reviewSummary!.averageRating)
    );
    
    return sellersWithReviews.take(limit).toList();
  }

  // Get sellers by category
  List<Seller> getSellersByCategory(String category) {
    return _sellers.where((seller) => seller.category == category).toList();
  }

  // Check if user can review a seller
  bool canUserReviewSeller(String userId, String sellerId, {String? verificationMethod}) {
    // Check if user has already reviewed this seller recently
    final existingReview = _reviews.firstWhere(
      (review) => review.userId == userId && 
                  review.sellerId == sellerId &&
                  review.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30))),
      orElse: () => Review(
        id: '',
        userId: '',
        sellerId: '',
        rating: 0,
        type: ReviewType.seller,
        status: ReviewStatus.pending,
        createdAt: DateTime.now(),
        isVerified: false,
        pointsEarned: 0,
      ),
    );
    
    return existingReview.id.isEmpty; // No recent review found
  }

  // Check if user has interacted with seller (for verification)
  bool hasUserInteractedWithSeller(String userId, String sellerId, String verificationMethod) {
    // This would check against:
    // - QR code scans
    // - Offer redemptions
    // - Video ad views
    // - Contest participations
    
    // For now, return true (implement actual verification logic)
    return true;
  }

  // Submit a new review
  Future<bool> submitReview({
    required String userId,
    required String sellerId,
    required int rating,
    String? comment,
    List<String>? imageUrls,
    String? videoUrl,
    required ReviewType type,
    String? offerId,
    String? verificationMethod,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final review = await _reviewService.submitReview(
        userId: userId,
        sellerId: sellerId,
        rating: rating,
        comment: comment,
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        type: type,
        offerId: offerId,
        verificationMethod: verificationMethod,
      );

      // Update local state
      _reviews.add(review);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }


  // Load reviews for a seller
  Future<void> loadReviewsForSeller(String sellerId) async {
    try {
      _setLoading(true);
      _clearError();

      // Cancel existing subscription if any
      await _reviewSubscriptions[sellerId]?.cancel();
      await _summarySubscriptions[sellerId]?.cancel();

      // Subscribe to reviews stream
      _reviewSubscriptions[sellerId] = _reviewService
          .getSellerReviews(sellerId)
          .listen(
            (reviews) {
              _sellerReviews[sellerId] = reviews;
              notifyListeners();
            },
            onError: (e) => _setError('Failed to load reviews: $e'),
          );

      // Subscribe to summary stream
      _summarySubscriptions[sellerId] = _reviewService
          .getReviewSummary(sellerId)
          .listen(
            (summary) {
              if (summary != null) {
                _reviewSummaries[sellerId] = summary;
                notifyListeners();
              }
            },
            onError: (e) => _setError('Failed to load review summary: $e'),
          );
    } catch (e) {
      _setError('Failed to load reviews: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load all sellers
  Future<void> loadSellers() async {
    try {
      _isLoading = true;
      _clearError();
      // Don't call notifyListeners here to avoid setState during build

      // TODO: Load from backend
      // _sellers = await _apiService.getSellers();

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners(); // Only notify once at the end
    }
  }

  // Load offers
  Future<void> loadOffers() async {
    try {
      _isLoading = true;
      _clearError();
      // Don't call notifyListeners here to avoid setState during build

      // TODO: Load from backend
      // _offers = await _apiService.getOffers();

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners(); // Only notify once at the end
    }
  }

  // Search sellers
  List<Seller> searchSellers(String query) {
    if (query.isEmpty) return _sellers;
    
    return _sellers.where((seller) =>
      seller.name.toLowerCase().contains(query.toLowerCase()) ||
      seller.category.toLowerCase().contains(query.toLowerCase()) ||
      (seller.description?.toLowerCase().contains(query.toLowerCase()) ?? false)
    ).toList();
  }

  // Follow/Unfollow seller
  Future<void> toggleFollowSeller(String userId, String sellerId) async {
    try {
      // Import SellerFollowerService at the top of this file
      final followerService = SellerFollowerService();
      
      // Toggle follow status
      await followerService.toggleFollow(userId, sellerId, 'manual');
      
      // Update local state will happen automatically through listeners
      notifyListeners();
    } catch (e) {
      _setError('Failed to update follow status: $e');
    }
  }

  // Get user's review history
  Future<void> loadUserReviews(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      // Cancel existing subscription if any
      await _reviewSubscriptions[userId]?.cancel();

      // Subscribe to user reviews stream
      _reviewSubscriptions[userId] = _reviewService
          .getUserReviews(userId)
          .listen(
            (reviews) {
              _reviews = reviews;
              notifyListeners();
            },
            onError: (e) => _setError('Failed to load user reviews: $e'),
          );
    } catch (e) {
      _setError('Failed to load user reviews: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get user's followed sellers
  Future<List<Seller>> getUserFollowedSellers(String userId) async {
    try {
      final followerService = SellerFollowerService();
      return await followerService.getFollowedSellers(userId).first;
    } catch (e) {
      debugPrint('Failed to get followed sellers: $e');
      return [];
    }
  }

  // Helper methods
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
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    for (var subscription in _reviewSubscriptions.values) {
      subscription.cancel();
    }
    for (var subscription in _summarySubscriptions.values) {
      subscription.cancel();
    }
    super.dispose();
  }
}

