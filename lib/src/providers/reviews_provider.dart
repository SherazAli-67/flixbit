import 'package:flutter/foundation.dart';
import '../models/review_model.dart';
import '../models/seller_model.dart';
import '../models/offer_model.dart';

class ReviewsProvider extends ChangeNotifier {
  // State variables
  List<Review> _reviews = [];
  List<Seller> _sellers = [];
  List<Offer> _offers = [];
  Map<String, ReviewSummary> _reviewSummaries = {};
  Map<String, List<Review>> _sellerReviews = {};
  bool _isLoading = false;
  String? _error;

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

      // Validate review
      if (rating < 1 || rating > 5) {
        _setError('Rating must be between 1 and 5 stars');
        return false;
      }

      // Check if user can review
      if (!canUserReviewSeller(userId, sellerId)) {
        _setError('You have already reviewed this seller recently');
        return false;
      }

      // Verify interaction if required
      if (verificationMethod != null && !hasUserInteractedWithSeller(userId, sellerId, verificationMethod)) {
        _setError('You must interact with this seller before leaving a review');
        return false;
      }

      // Calculate points earned
      int pointsEarned = 5; // Base points for rating
      if (comment != null && comment.isNotEmpty) pointsEarned += 5;
      if (imageUrls != null && imageUrls.isNotEmpty) pointsEarned += 10;

      // Create review
      final review = Review(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        sellerId: sellerId,
        offerId: offerId,
        rating: rating,
        comment: comment,
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        type: type,
        status: ReviewStatus.pending, // Will be approved by admin
        createdAt: DateTime.now(),
        isVerified: verificationMethod != null,
        verificationMethod: verificationMethod,
        pointsEarned: pointsEarned,
      );

      // Add to local state
      _reviews.add(review);
      _updateSellerReviews(sellerId);
      
      // TODO: Submit to backend
      // await _apiService.submitReview(review);
      
      notifyListeners();
      return true;

    } catch (e) {
      _setError('Failed to submit review: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update seller's review summary
  void _updateSellerReviews(String sellerId) {
    final sellerReviewList = _reviews.where((review) => 
      review.sellerId == sellerId && review.status == ReviewStatus.approved
    ).toList();

    _sellerReviews[sellerId] = sellerReviewList;

    if (sellerReviewList.isNotEmpty) {
      // Calculate average rating
      final totalRating = sellerReviewList.fold(0, (sum, review) => sum + review.rating);
      final averageRating = totalRating / sellerReviewList.length;

      // Calculate rating distribution
      final ratingDistribution = <int, int>{};
      for (int i = 1; i <= 5; i++) {
        ratingDistribution[i] = sellerReviewList.where((r) => r.rating == i).length;
      }

      // Determine badges
      final badges = <String>[];
      if (averageRating >= 4.5) badges.add('Top Rated');
      if (sellerReviewList.length >= 50) badges.add('Popular');
      if (averageRating >= 4.0 && sellerReviewList.length >= 20) badges.add('Highly Recommended');

      _reviewSummaries[sellerId] = ReviewSummary(
        sellerId: sellerId,
        averageRating: averageRating,
        totalReviews: sellerReviewList.length,
        ratingDistribution: ratingDistribution,
        badges: badges,
        lastUpdated: DateTime.now(),
      );
    }
  }

  // Load reviews for a seller
  Future<void> loadReviewsForSeller(String sellerId) async {
    try {
      _setLoading(true);
      _clearError();

      // TODO: Load from backend
      // final reviews = await _apiService.getReviewsForSeller(sellerId);
      // _sellerReviews[sellerId] = reviews;

      notifyListeners();
    } catch (e) {
      _setError('Failed to load reviews: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load all sellers
  Future<void> loadSellers() async {
    try {
      _setLoading(true);
      _clearError();

      // TODO: Load from backend
      // _sellers = await _apiService.getSellers();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load sellers: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load offers
  Future<void> loadOffers() async {
    try {
      _setLoading(true);
      _clearError();

      // TODO: Load from backend
      // _offers = await _apiService.getOffers();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load offers: $e');
    } finally {
      _setLoading(false);
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
      // TODO: Implement follow/unfollow logic
      // await _apiService.toggleFollowSeller(userId, sellerId);
      
      // Update local state
      final sellerIndex = _sellers.indexWhere((s) => s.id == sellerId);
      if (sellerIndex != -1) {
        // Update followers count
        // This would need to be tracked separately
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update follow status: $e');
    }
  }

  // Get user's review history
  List<Review> getUserReviews(String userId) {
    return _reviews.where((review) => review.userId == userId).toList();
  }

  // Get user's followed sellers
  List<Seller> getUserFollowedSellers(String userId) {
    // TODO: Implement user's followed sellers logic
    return [];
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

  // Initialize with sample data for development
  void initializeWithSampleData() {
    // Sample sellers
    _sellers = [
      Seller(
        id: '1',
        name: 'The Coffee Bean',
        description: 'Premium coffee and pastries',
        category: 'Food & Beverage',
        location: 'Downtown',
        isVerified: true,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        followersCount: 150,
        badges: ['Top Rated', 'Popular'],
      ),
      Seller(
        id: '2',
        name: 'Tech Store Pro',
        description: 'Latest gadgets and electronics',
        category: 'Electronics',
        location: 'Mall District',
        isVerified: true,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        followersCount: 89,
        badges: ['Highly Recommended'],
      ),
    ];

    // Sample reviews
    _reviews = [
      Review(
        id: '1',
        userId: 'user1',
        sellerId: '1',
        rating: 5,
        comment: 'Amazing coffee and great service!',
        type: ReviewType.seller,
        status: ReviewStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        isVerified: true,
        verificationMethod: 'qr_scan',
        pointsEarned: 10,
      ),
      Review(
        id: '2',
        userId: 'user2',
        sellerId: '1',
        rating: 4,
        comment: 'Good coffee, friendly staff',
        type: ReviewType.seller,
        status: ReviewStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        isVerified: true,
        verificationMethod: 'offer_redemption',
        pointsEarned: 10,
      ),
    ];

    // Update review summaries
    _updateSellerReviews('1');
    _updateSellerReviews('2');

    notifyListeners();
  }
}

