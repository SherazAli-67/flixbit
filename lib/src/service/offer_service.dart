import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/points_config.dart';
import '../models/offer_model.dart';
import '../models/wallet_models.dart';
import '../res/firebase_constants.dart';
import 'flixbit_points_manager.dart';
import 'seller_follower_service.dart';
import 'wallet_service.dart';

class OfferService {
  // Singleton pattern
  static final OfferService _instance = OfferService._internal();
  factory OfferService() => _instance;
  OfferService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SellerFollowerService _followerService = SellerFollowerService();

  // ==================== SELLER OPERATIONS ====================

  /// Create a new offer (seller)
  Future<Offer> createOffer({
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
      // Generate unique QR code data
      final offerRef = _firestore.collection(FirebaseConstants.offersCollection).doc();
      final qrCodeData = _generateQRCodeData(offerRef.id, sellerId);

      final offer = Offer(
        id: offerRef.id,
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
        termsAndConditions: termsAndConditions ?? [],
        requiresReview: requiresReview,
        reviewPointsReward: reviewPointsReward,
        isActive: true,
        createdAt: DateTime.now(),
        status: ApprovalStatus.pending,
        qrCodeData: qrCodeData,
        targetLocation: targetLocation,
        targetRadiusKm: targetRadiusKm,
      );

      await offerRef.set(offer.toJson());

      debugPrint('Offer created: ${offer.id} for seller: $sellerId');
      return offer;
    } catch (e) {
      debugPrint('Error creating offer: $e');
      rethrow;
    }
  }

  /// Update an existing offer
  Future<void> updateOffer(String offerId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(FirebaseConstants.offersCollection)
          .doc(offerId)
          .update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Offer updated: $offerId');
    } catch (e) {
      debugPrint('Error updating offer: $e');
      rethrow;
    }
  }

  /// Delete an offer
  Future<void> deleteOffer(String offerId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.offersCollection)
          .doc(offerId)
          .delete();

      debugPrint('Offer deleted: $offerId');
    } catch (e) {
      debugPrint('Error deleting offer: $e');
      rethrow;
    }
  }

  /// Get seller's offers
  Stream<List<Offer>> getSellerOffers(String sellerId, {ApprovalStatus? status}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebaseConstants.offersCollection)
        .where('sellerId', isEqualTo: sellerId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Offer.fromJson(doc.data()))
            .toList());
  }

  // ==================== USER OPERATIONS ====================

  /// Get active approved offers
  Stream<List<Offer>> getActiveOffers({
    String? category,
    String? sellerId,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebaseConstants.offersCollection)
        .where('status', isEqualTo: ApprovalStatus.approved.name)
        .where('isActive', isEqualTo: true);

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    if (sellerId != null && sellerId.isNotEmpty) {
      query = query.where('sellerId', isEqualTo: sellerId);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Offer.fromJson(doc.data()))
            .where((offer) => offer.canBeRedeemed)
            .toList());
  }

  /// Get nearby offers based on user location
  Stream<List<Offer>> getNearbyOffers(GeoPoint userLocation, double radiusKm) {
    // Note: Firestore doesn't support geospatial queries natively
    // This is a simplified implementation - consider using GeoFlutterFire for production
    return _firestore
        .collection(FirebaseConstants.offersCollection)
        .where('status', isEqualTo: ApprovalStatus.approved.name)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final offers = snapshot.docs
          .map((doc) => Offer.fromJson(doc.data()))
          .where((offer) => offer.canBeRedeemed)
          .toList();

      // Filter by distance (simple approximation)
      return offers.where((offer) {
        if (offer.targetLocation == null) return true; // Include all offers without location

        final distance = _calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          offer.targetLocation!.latitude,
          offer.targetLocation!.longitude,
        );

        final maxRadius = offer.targetRadiusKm ?? radiusKm;
        return distance <= maxRadius;
      }).toList();
    });
  }

  /// Get offers from followed sellers
  Stream<List<Offer>> getFollowedSellersOffers(String userId) async* {
    final followedSellers = await _followerService.getFollowedSellers(userId).first;
    final sellerIds = followedSellers.map((s) => s.id).toList();

    if (sellerIds.isEmpty) {
      yield [];
      return;
    }

    // Firestore 'in' query limited to 10 items, so batch if needed
    final batches = <List<String>>[];
    for (var i = 0; i < sellerIds.length; i += 10) {
      batches.add(sellerIds.skip(i).take(10).toList());
    }

    for (final batch in batches) {
      yield* _firestore
          .collection(FirebaseConstants.offersCollection)
          .where('sellerId', whereIn: batch)
          .where('status', isEqualTo: ApprovalStatus.approved.name)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Offer.fromJson(doc.data()))
              .where((offer) => offer.canBeRedeemed)
              .toList());
    }
  }

  /// Redeem an offer
  Future<OfferRedemption> redeemOffer({
    required String userId,
    required String offerId,
    required String method, // 'qr' or 'digital'
    String? qrCodeData,
  }) async {
    try {
      // Get offer
      final offerDoc = await _firestore
          .collection(FirebaseConstants.offersCollection)
          .doc(offerId)
          .get();

      if (!offerDoc.exists) {
        throw Exception('Offer not found');
      }

      final offer = Offer.fromJson(offerDoc.data()!);

      // Validate offer can be redeemed
      if (!offer.canBeRedeemed) {
        throw Exception('Offer cannot be redeemed: ${offer.validityStatus}');
      }

      // Check if user already redeemed
      final alreadyRedeemed = await hasUserRedeemed(userId, offerId);
      if (alreadyRedeemed) {
        throw Exception('You have already redeemed this offer');
      }

      // Validate QR code if method is qr
      if (method == 'qr' && qrCodeData != null) {
        if (qrCodeData != offer.qrCodeData) {
          throw Exception('Invalid QR code');
        }
      }

      // Check daily redemption limit
      final dailyStats = await WalletService.getDailySummary(userId);
      final redemptionPoints = (dailyStats['offer_redemption'])?.toInt() ?? 0;
      final dailyLimit = PointsConfig.dailyLimits['offer_redemption'] ?? 100;

      if (redemptionPoints >= dailyLimit) {
        throw Exception('Daily offer redemption limit reached');
      }

      // Create redemption record
      final redemptionRef = _firestore
          .collection(FirebaseConstants.offerRedemptionsCollection)
          .doc();

      final redemption = OfferRedemption(
        id: redemptionRef.id,
        userId: userId,
        offerId: offerId,
        sellerId: offer.sellerId,
        redeemedAt: DateTime.now(),
        pointsEarned: offer.reviewPointsReward,
        qrCodeData: qrCodeData,
      );

      await redemptionRef.set(redemption.toJson());

      // Increment redemption count
      await _firestore
          .collection(FirebaseConstants.offersCollection)
          .doc(offerId)
          .update({
        'currentRedemptions': FieldValue.increment(1),
      });

      // Award points
      if (offer.reviewPointsReward > 0) {
        await FlixbitPointsManager.awardPoints(
          userId: userId,
          pointsEarned: offer.reviewPointsReward,
          source: TransactionSource.offerRedemption,
          description: 'Redeemed offer: ${offer.title}',
          metadata: {
            'offerId': offerId,
            'sellerId': offer.sellerId,
            'redemptionId': redemption.id,
            'method': method,
          },
        );
      }

      // Auto-follow seller
      final isFollowing = await _followerService.isFollowing(userId, offer.sellerId);
      if (!isFollowing) {
        await _followerService.followSeller(
          userId: userId,
          sellerId: offer.sellerId,
          source: 'offer_redemption',
          metadata: {'offerId': offerId},
        );
      }

      // Update analytics
      await _updateOfferAnalytics(offerId, method);

      debugPrint('Offer redeemed: $offerId by user: $userId');
      return redemption;
    } catch (e) {
      debugPrint('Error redeeming offer: $e');
      rethrow;
    }
  }

  /// Validate QR code redemption
  Future<bool> validateQRRedemption(String userId, String offerId, String qrData) async {
    try {
      final offerDoc = await _firestore
          .collection(FirebaseConstants.offersCollection)
          .doc(offerId)
          .get();

      if (!offerDoc.exists) return false;

      final offer = Offer.fromJson(offerDoc.data()!);
      return offer.qrCodeData == qrData;
    } catch (e) {
      debugPrint('Error validating QR redemption: $e');
      return false;
    }
  }

  // ==================== ANALYTICS ====================

  /// Increment view count
  Future<void> incrementViewCount(String offerId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.offersCollection)
          .doc(offerId)
          .update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
      // Don't rethrow - view tracking is not critical
    }
  }

  /// Check if user has redeemed an offer
  Future<bool> hasUserRedeemed(String userId, String offerId) async {
    try {
      final redemption = await _firestore
          .collection(FirebaseConstants.offerRedemptionsCollection)
          .where('userId', isEqualTo: userId)
          .where('offerId', isEqualTo: offerId)
          .limit(1)
          .get();

      return redemption.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking redemption: $e');
      return false;
    }
  }

  /// Get offer analytics
  Future<Map<String, dynamic>> getOfferAnalytics(String offerId) async {
    try {
      final analyticsDoc = await _firestore
          .collection(FirebaseConstants.offerAnalyticsCollection)
          .doc(offerId)
          .get();

      if (!analyticsDoc.exists) {
        return {
          'views': 0,
          'redemptions': 0,
          'qrRedemptions': 0,
          'digitalRedemptions': 0,
          'conversionRate': '0%',
        };
      }

      return analyticsDoc.data()!;
    } catch (e) {
      debugPrint('Error getting offer analytics: $e');
      return {};
    }
  }

  /// Update offer analytics
  Future<void> _updateOfferAnalytics(String offerId, String method) async {
    try {
      final analyticsRef = _firestore
          .collection(FirebaseConstants.offerAnalyticsCollection)
          .doc(offerId);

      await analyticsRef.set({
        'offerId': offerId,
        'redemptions': FieldValue.increment(1),
        '${method}Redemptions': FieldValue.increment(1),
        'lastRedemptionAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Calculate conversion rate
      final offerDoc = await _firestore
          .collection(FirebaseConstants.offersCollection)
          .doc(offerId)
          .get();

      if (offerDoc.exists) {
        final offer = Offer.fromJson(offerDoc.data()!);
        final conversionRate = offer.viewCount > 0
            ? (offer.currentRedemptions / offer.viewCount * 100).toStringAsFixed(1) + '%'
            : '0%';

        await analyticsRef.update({'conversionRate': conversionRate});
      }
    } catch (e) {
      debugPrint('Error updating offer analytics: $e');
      // Don't rethrow - analytics update is not critical
    }
  }

  /// Get user's redemption history
  Stream<List<OfferRedemption>> getUserRedemptions(String userId) {
    return _firestore
        .collection(FirebaseConstants.offerRedemptionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('redeemedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OfferRedemption.fromJson(doc.data()))
            .toList());
  }

  /// Mark redemption as used
  Future<void> markRedemptionAsUsed(String redemptionId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.offerRedemptionsCollection)
          .doc(redemptionId)
          .update({
        'isUsed': true,
        'usedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Redemption marked as used: $redemptionId');
    } catch (e) {
      debugPrint('Error marking redemption as used: $e');
      rethrow;
    }
  }

  // ==================== ADMIN OPERATIONS ====================

  /// Approve an offer
  Future<void> approveOffer(String offerId, String adminId, {String? notes}) async {
    try {
      await _firestore
          .collection(FirebaseConstants.offersCollection)
          .doc(offerId)
          .update({
        'status': ApprovalStatus.approved.name,
        'approvedBy': adminId,
        'approvedAt': FieldValue.serverTimestamp(),
        'adminNotes': notes,
      });

      debugPrint('Offer approved: $offerId by admin: $adminId');
    } catch (e) {
      debugPrint('Error approving offer: $e');
      rethrow;
    }
  }

  /// Reject an offer
  Future<void> rejectOffer(String offerId, String adminId, String reason) async {
    try {
      await _firestore
          .collection(FirebaseConstants.offersCollection)
          .doc(offerId)
          .update({
        'status': ApprovalStatus.rejected.name,
        'approvedBy': adminId,
        'approvedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      });

      debugPrint('Offer rejected: $offerId by admin: $adminId');
    } catch (e) {
      debugPrint('Error rejecting offer: $e');
      rethrow;
    }
  }

  /// Get pending offers for approval
  Stream<List<Offer>> getPendingOffers() {
    return _firestore
        .collection(FirebaseConstants.offersCollection)
        .where('status', isEqualTo: ApprovalStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Offer.fromJson(doc.data()))
            .toList());
  }

  // ==================== HELPER METHODS ====================

  /// Generate unique QR code data
  String _generateQRCodeData(String offerId, String sellerId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'flixbit:offer:$offerId:$sellerId:$timestamp';
  }

  /// Calculate distance between two points (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth's radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = (dLat / 2).abs() * (dLat / 2).abs() +
        lat1.abs() * lat2.abs() * (dLon / 2).abs() * (dLon / 2).abs();

    final c = 2.0 * a.abs().clamp(0.0, 1.0);
    return (R * c).toDouble();
  }

  double _toRadians(double degrees) {
    return degrees * 3.141592653589793 / 180.0;
  }

  /// Get offer by ID
  Future<Offer?> getOfferById(String offerId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.offersCollection)
          .doc(offerId)
          .get();

      if (!doc.exists) return null;

      return Offer.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('Error getting offer by ID: $e');
      return null;
    }
  }

  /// Search offers
  Stream<List<Offer>> searchOffers(String query) {
    return _firestore
        .collection(FirebaseConstants.offersCollection)
        .where('status', isEqualTo: ApprovalStatus.approved.name)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Offer.fromJson(doc.data()))
            .where((offer) {
              final searchQuery = query.toLowerCase();
              return offer.canBeRedeemed &&
                  (offer.title.toLowerCase().contains(searchQuery) ||
                      offer.description.toLowerCase().contains(searchQuery) ||
                      (offer.category?.toLowerCase().contains(searchQuery) ?? false));
            })
            .toList());
  }
}

