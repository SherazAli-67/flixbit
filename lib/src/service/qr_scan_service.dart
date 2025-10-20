import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/points_config.dart';
import '../models/wallet_models.dart';
import 'flixbit_points_manager.dart';
import 'seller_follower_service.dart';
import 'wallet_service.dart';

class QRScanService {
  // Singleton pattern
  static final QRScanService _instance = QRScanService._internal();
  factory QRScanService() => _instance;
  QRScanService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SellerFollowerService _followerService = SellerFollowerService();

  /// Record a QR scan and award points
  Future<void> recordScan({
    required String userId,
    required String sellerId,
    required String qrCode,
    GeoPoint? location,
  }) async {
    try {
      // Check daily limit
      final dailyStats = await WalletService.getDailySummary(userId);
      final scanPoints = (dailyStats['qrScan'])?.toInt() ?? 0;
      final dailyLimit = PointsConfig.dailyLimits['qr_scan'] ?? 100;

      if (scanPoints >= dailyLimit) {
        throw Exception('Daily QR scan limit reached');
      }

      // Check cooldown period
      final lastScan = await _getLastScan(userId, sellerId);
      if (lastScan != null) {
        final cooldownMinutes = PointsConfig.cooldowns['qr_scan'] ?? 15;
        final cooldownEnd = lastScan.add(Duration(minutes: cooldownMinutes));
        if (DateTime.now().isBefore(cooldownEnd)) {
          throw Exception('Please wait before scanning this seller\'s QR code again');
        }
      }

      // Create scan record
      final scanRef = _firestore.collection('qr_scans').doc();
      await scanRef.set({
        'id': scanRef.id,
        'userId': userId,
        'sellerId': sellerId,
        'qrCode': qrCode,
        'location': location,
        'scannedAt': FieldValue.serverTimestamp(),
        'pointsAwarded': PointsConfig.getPoints('qr_scan'),
      });

      // Award points
      await FlixbitPointsManager.awardPoints(
        userId: userId,
        pointsEarned: PointsConfig.getPoints('qr_scan'),
        source: TransactionSource.qrScan,
        description: 'QR code scan',
        metadata: {
          'scanId': scanRef.id,
          'sellerId': sellerId,
          'location': location?.latitude != null 
              ? {'lat': location?.latitude, 'lng': location?.longitude} 
              : null,
        },
      );

      // Auto-follow seller on QR scan
      final isFollowing = await _followerService.isFollowing(userId, sellerId);
      if (!isFollowing) {
        await _followerService.followSeller(
          userId: userId,
          sellerId: sellerId,
          source: 'qr_scan',
          metadata: {
            'scanId': scanRef.id,
            'location': location?.latitude != null 
                ? {'lat': location?.latitude, 'lng': location?.longitude} 
                : null,
          },
        );
      }

      // Update seller stats
      await _updateSellerStats(sellerId);
    } catch (e) {
      debugPrint('Error recording QR scan: $e');
      rethrow;
    }
  }

  /// Get user's last scan for a seller
  Future<DateTime?> _getLastScan(String userId, String sellerId) async {
    try {
      final lastScan = await _firestore
          .collection('qr_scans')
          .where('userId', isEqualTo: userId)
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('scannedAt', descending: true)
          .limit(1)
          .get();

      if (lastScan.docs.isEmpty) return null;

      return (lastScan.docs.first.data()['scannedAt'] as Timestamp).toDate();
    } catch (e) {
      debugPrint('Error getting last scan: $e');
      return null;
    }
  }

  /// Update seller's QR scan statistics
  Future<void> _updateSellerStats(String sellerId) async {
    try {
      // Get today's scans
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final todayScans = await _firestore
          .collection('qr_scans')
          .where('sellerId', isEqualTo: sellerId)
          .where('scannedAt', isGreaterThan: Timestamp.fromDate(startOfDay))
          .get();

      // Get total scans
      final totalScans = await _firestore
          .collection('qr_scans')
          .where('sellerId', isEqualTo: sellerId)
          .count()
          .get();

      // Update stats
      await _firestore
          .collection('seller_qr_stats')
          .doc(sellerId)
          .set({
            'dailyScans': todayScans.size,
            'totalScans': totalScans.count,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating seller stats: $e');
      // Don't rethrow - stats update is not critical
    }
  }

  /// Get seller's QR scan statistics
  Stream<Map<String, dynamic>> getSellerStats(String sellerId) {
    return _firestore
        .collection('seller_qr_stats')
        .doc(sellerId)
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }

  /// Get user's scan history
  Stream<List<Map<String, dynamic>>> getUserScans(String userId) {
    return _firestore
        .collection('qr_scans')
        .where('userId', isEqualTo: userId)
        .orderBy('scannedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList());
  }

  /// Check if user has scanned a seller's QR code
  Future<bool> hasScannedSeller(String userId, String sellerId) async {
    try {
      final scan = await _firestore
          .collection('qr_scans')
          .where('userId', isEqualTo: userId)
          .where('sellerId', isEqualTo: sellerId)
          .limit(1)
          .get();

      return scan.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking seller scan: $e');
      return false;
    }
  }

  /// Get daily scan count for user
  Future<int> getDailyScanCount(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final scans = await _firestore
          .collection('qr_scans')
          .where('userId', isEqualTo: userId)
          .where('scannedAt', isGreaterThan: Timestamp.fromDate(startOfDay))
          .count()
          .get();

      return scans.count ?? 0;
    } catch (e) {
      debugPrint('Error getting daily scan count: $e');
      return 0;
    }
  }

  /// Get remaining scans available for today
  Future<int> getRemainingScans(String userId) async {
    try {
      final dailyLimit = PointsConfig.dailyLimits['qr_scan'] ?? 100;
      final dailyCount = await getDailyScanCount(userId);
      return dailyLimit - dailyCount;
    } catch (e) {
      debugPrint('Error getting remaining scans: $e');
      return 0;
    }
  }
}
