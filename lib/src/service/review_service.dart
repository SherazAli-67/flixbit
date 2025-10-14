import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/points_config.dart';
import '../models/review_model.dart';
import '../models/flixbit_transaction_model.dart';
import '../res/firebase_constants.dart';
import 'flixbit_points_manager.dart';
import 'wallet_service.dart';

class ReviewService {
  // Singleton pattern
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WalletService _walletService = WalletService();

  /// Submit a new review
  Future<Review> submitReview({
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
      // Validate review
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5 stars');
      }

      // Check if user can review
      if (!await _canUserReview(userId, sellerId, type)) {
        throw Exception('You have already reviewed this recently');
      }

      // Verify interaction if required
      if (verificationMethod != null && !await _verifyInteraction(userId, sellerId, verificationMethod)) {
        throw Exception('Interaction verification failed');
      }

      // Calculate points earned
      int pointsEarned = await _calculatePoints(
        userId: userId,
        type: type,
        hasComment: comment != null && comment.isNotEmpty,
        hasMedia: (imageUrls?.isNotEmpty ?? false) || videoUrl != null,
        isVerified: verificationMethod != null,
      );

      // Create review document
      final reviewRef = _firestore.collection(FirebaseConstants.reviewsCollection).doc();
      final review = Review(
        id: reviewRef.id,
        userId: userId,
        sellerId: sellerId,
        offerId: offerId,
        rating: rating,
        comment: comment,
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        type: type,
        status: ReviewStatus.pending,
        createdAt: DateTime.now(),
        isVerified: verificationMethod != null,
        verificationMethod: verificationMethod,
        pointsEarned: pointsEarned,
      );

      // Save review
      await reviewRef.set(review.toJson());

      // Award points
      if (pointsEarned > 0) {
        await FlixbitPointsManager.awardPoints(
          userId: userId,
          pointsEarned: pointsEarned,
          source: TransactionSource.review,
          description: _getReviewDescription(type, sellerId),
          metadata: {
            'reviewId': review.id,
            'type': type.name,
            'rating': rating,
            'isVerified': review.isVerified,
            'verificationMethod': verificationMethod,
          },
        );
      }

      // Update review summary
      await _updateReviewSummary(sellerId);

      return review;
    } catch (e) {
      debugPrint('Error submitting review: $e');
      rethrow;
    }
  }

  /// Check if user can submit a review
  Future<bool> _canUserReview(String userId, String sellerId, ReviewType type) async {
    try {
      // Check recent reviews (30-day cooldown)
      final recentReviews = await _firestore
          .collection(FirebaseConstants.reviewsCollection)
          .where('userId', isEqualTo: userId)
          .where('sellerId', isEqualTo: sellerId)
          .where('type', isEqualTo: type.name)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 30))))
          .get();

      if (recentReviews.docs.isNotEmpty) {
        return false;
      }

      // Check daily limit
      final dailyStats = await _walletService.getDailyTransactionSummary(userId);
      final reviewPoints = (dailyStats['review_points'] as num?)?.toInt() ?? 0;
      final dailyLimit = PointsConfig.dailyLimits['review'] ?? 45;

      return reviewPoints < dailyLimit;
    } catch (e) {
      debugPrint('Error checking review eligibility: $e');
      return false;
    }
  }

  /// Verify user interaction
  Future<bool> _verifyInteraction(String userId, String sellerId, String method) async {
    try {
      switch (method) {
        case 'qr_scan':
          // Check QR scan history
          final scanExists = await _firestore
              .collection('qr_scans')
              .where('userId', isEqualTo: userId)
              .where('sellerId', isEqualTo: sellerId)
              .limit(1)
              .get()
              .then((snapshot) => snapshot.docs.isNotEmpty);
          return scanExists;

        case 'offer_redemption':
          // Check offer redemption history
          final redemptionExists = await _firestore
              .collection('offer_redemptions')
              .where('userId', isEqualTo: userId)
              .where('sellerId', isEqualTo: sellerId)
              .limit(1)
              .get()
              .then((snapshot) => snapshot.docs.isNotEmpty);
          return redemptionExists;

        case 'video_watch':
          // Check video watch history
          final watchExists = await _firestore
              .collection(FirebaseConstants.videoAdEngagementsCollection)
              .where('userId', isEqualTo: userId)
              .where('sellerId', isEqualTo: sellerId)
              .where('completed', isEqualTo: true)
              .limit(1)
              .get()
              .then((snapshot) => snapshot.docs.isNotEmpty);
          return watchExists;

        default:
          return false;
      }
    } catch (e) {
      debugPrint('Error verifying interaction: $e');
      return false;
    }
  }

  /// Calculate points for review
  Future<int> _calculatePoints({
    required String userId,
    required ReviewType type,
    required bool hasComment,
    required bool hasMedia,
    required bool isVerified,
  }) async {
    int points = PointsConfig.getPoints('review'); // Base points

    // Bonus points for quality content
    if (hasComment) points += 5;
    if (hasMedia) points += 10;
    if (isVerified) points += 15;

    // Type-specific bonuses
    switch (type) {
      case ReviewType.seller:
        points += 5; // Extra for detailed seller review
        break;
      case ReviewType.offer:
        points += 3; // Bonus for offer feedback
        break;
      case ReviewType.videoAd:
        points += 2; // Bonus for ad feedback
        break;
      case ReviewType.referral:
        points += 4; // Bonus for referral verification
        break;
    }

    // Check daily limit
    final dailyStats = await _walletService.getDailyTransactionSummary(userId);
    final currentPoints = (dailyStats['review_points'] as num?)?.toInt() ?? 0;
    final dailyLimit = PointsConfig.dailyLimits['review'] ?? 45;
    final remainingLimit = dailyLimit - currentPoints;

    // Cap points to daily limit
    return points > remainingLimit ? remainingLimit : points;
  }

  /// Get review description for points award
  String _getReviewDescription(ReviewType type, String sellerId) {
    switch (type) {
      case ReviewType.seller:
        return 'Seller review submitted';
      case ReviewType.offer:
        return 'Offer review submitted';
      case ReviewType.videoAd:
        return 'Video ad review submitted';
      case ReviewType.referral:
        return 'Referral review submitted';
    }
  }

  /// Update seller's review summary
  Future<void> _updateReviewSummary(String sellerId) async {
    try {
      final approvedReviews = await _firestore
          .collection(FirebaseConstants.reviewsCollection)
          .where('sellerId', isEqualTo: sellerId)
          .where('status', isEqualTo: ReviewStatus.approved.name)
          .get();

      if (approvedReviews.docs.isEmpty) return;

      // Calculate metrics
      final reviews = approvedReviews.docs.map((doc) => Review.fromJson(doc.data())).toList();
      final totalRating = reviews.fold(0, (sum, review) => sum + review.rating);
      final averageRating = totalRating / reviews.length;

      // Calculate rating distribution
      final ratingDistribution = <int, int>{};
      for (int i = 1; i <= 5; i++) {
        ratingDistribution[i] = reviews.where((r) => r.rating == i).length;
      }

      // Determine badges
      final badges = <String>[];
      if (averageRating >= 4.5) badges.add('Top Rated');
      if (reviews.length >= 50) badges.add('Popular');
      if (averageRating >= 4.0 && reviews.length >= 20) badges.add('Highly Recommended');

      // Update summary
      await _firestore
          .collection('seller_review_summaries')
          .doc(sellerId)
          .set({
            'sellerId': sellerId,
            'averageRating': averageRating,
            'totalReviews': reviews.length,
            'ratingDistribution': ratingDistribution,
            'badges': badges,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error updating review summary: $e');
      // Don't rethrow - summary update is not critical
    }
  }

  /// Get reviews for a seller
  Stream<List<Review>> getSellerReviews(String sellerId) {
    return _firestore
        .collection(FirebaseConstants.reviewsCollection)
        .where('sellerId', isEqualTo: sellerId)
        .where('status', isEqualTo: ReviewStatus.approved.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromJson(doc.data()))
            .toList());
  }

  /// Get user's review history
  Stream<List<Review>> getUserReviews(String userId) {
    return _firestore
        .collection(FirebaseConstants.reviewsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromJson(doc.data()))
            .toList());
  }

  /// Get seller's review summary
  Stream<ReviewSummary?> getReviewSummary(String sellerId) {
    return _firestore
        .collection('seller_review_summaries')
        .doc(sellerId)
        .snapshots()
        .map((doc) => doc.exists ? ReviewSummary.fromJson(doc.data()!) : null);
  }
}
