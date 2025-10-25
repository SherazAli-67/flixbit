import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../res/firebase_constants.dart';

class QRAnalyticsService {
  static final QRAnalyticsService _instance = QRAnalyticsService._internal();
  factory QRAnalyticsService() => _instance;
  QRAnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get seller QR statistics
  Future<Map<String, dynamic>> getSellerQRStats(String sellerId) async {
    try {
      // Get QR stats document
      final statsDoc = await _firestore
          .collection('seller_qr_stats')
          .doc(sellerId)
          .get();

      if (!statsDoc.exists) {
        return {
          'dailyScans': 0,
          'totalScans': 0,
          'weeklyScans': 0,
          'monthlyScans': 0,
        };
      }

      final data = statsDoc.data()!;

      // Calculate weekly and monthly scans
      final weeklyScans = await _getScansInPeriod(sellerId, 7);
      final monthlyScans = await _getScansInPeriod(sellerId, 30);

      return {
        'dailyScans': data['dailyScans'] ?? 0,
        'totalScans': data['totalScans'] ?? 0,
        'weeklyScans': weeklyScans,
        'monthlyScans': monthlyScans,
        'lastUpdated': data['lastUpdated'],
      };
    } catch (e) {
      debugPrint('Error getting seller QR stats: $e');
      return {};
    }
  }

  /// Get scans in a specific period (days)
  Future<int> _getScansInPeriod(String sellerId, int days) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      
      final scans = await _firestore
          .collection('qr_scans')
          .where('sellerId', isEqualTo: sellerId)
          .where('scannedAt', isGreaterThan: Timestamp.fromDate(startDate))
          .count()
          .get();

      return scans.count ?? 0;
    } catch (e) {
      debugPrint('Error getting scans in period: $e');
      return 0;
    }
  }

  /// Get scan history with details
  Stream<List<Map<String, dynamic>>> getSellerScanHistory(
    String sellerId, {
    int limit = 50,
  }) {
    return _firestore
        .collection('qr_scans')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('scannedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList());
  }

  /// Get followers gained via QR scans
  Future<int> getFollowersFromQR(String sellerId) async {
    try {
      final followers = await _firestore
          .collection(FirebaseConstants.sellerFollowersCollection)
          .where('sellerId', isEqualTo: sellerId)
          .where('followSource', isEqualTo: 'qr_scan')
          .count()
          .get();

      return followers.count ?? 0;
    } catch (e) {
      debugPrint('Error getting followers from QR: $e');
      return 0;
    }
  }

  /// Get scan locations (if available)
  Future<List<Map<String, dynamic>>> getScanLocations(String sellerId) async {
    try {
      final scans = await _firestore
          .collection('qr_scans')
          .where('sellerId', isEqualTo: sellerId)
          .where('location', isNotEqualTo: null)
          .limit(100)
          .get();

      return scans.docs
          .map((doc) {
            final data = doc.data();
            final location = data['location'] as GeoPoint?;
            if (location != null) {
              return {
                'latitude': location.latitude,
                'longitude': location.longitude,
                'scannedAt': data['scannedAt'],
              };
            }
            return null;
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      debugPrint('Error getting scan locations: $e');
      return [];
    }
  }

  /// Get hourly scan distribution (peak times)
  Future<Map<int, int>> getHourlyScanDistribution(String sellerId) async {
    try {
      final scans = await _firestore
          .collection('qr_scans')
          .where('sellerId', isEqualTo: sellerId)
          .get();

      final hourlyDistribution = <int, int>{};
      
      for (final doc in scans.docs) {
        final timestamp = doc.data()['scannedAt'] as Timestamp?;
        if (timestamp != null) {
          final hour = timestamp.toDate().hour;
          hourlyDistribution[hour] = (hourlyDistribution[hour] ?? 0) + 1;
        }
      }

      return hourlyDistribution;
    } catch (e) {
      debugPrint('Error getting hourly scan distribution: $e');
      return {};
    }
  }

  /// Get daily scan trend (last 30 days)
  Future<Map<String, int>> getDailyScanTrend(String sellerId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final scans = await _firestore
          .collection('qr_scans')
          .where('sellerId', isEqualTo: sellerId)
          .where('scannedAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final dailyTrend = <String, int>{};
      
      for (final doc in scans.docs) {
        final timestamp = doc.data()['scannedAt'] as Timestamp?;
        if (timestamp != null) {
          final date = timestamp.toDate();
          final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          dailyTrend[dateKey] = (dailyTrend[dateKey] ?? 0) + 1;
        }
      }

      return dailyTrend;
    } catch (e) {
      debugPrint('Error getting daily scan trend: $e');
      return {};
    }
  }

  /// Get conversion rate (scans to followers)
  Future<double> getConversionRate(String sellerId) async {
    try {
      final stats = await getSellerQRStats(sellerId);
      final totalScans = stats['totalScans'] as int? ?? 0;
      final followersFromQR = await getFollowersFromQR(sellerId);

      if (totalScans == 0) return 0.0;

      return (followersFromQR / totalScans) * 100;
    } catch (e) {
      debugPrint('Error calculating conversion rate: $e');
      return 0.0;
    }
  }

  /// Get comprehensive analytics
  Future<Map<String, dynamic>> getComprehensiveAnalytics(String sellerId) async {
    try {
      final stats = await getSellerQRStats(sellerId);
      final followersFromQR = await getFollowersFromQR(sellerId);
      final conversionRate = await getConversionRate(sellerId);
      final hourlyScanDistribution = await getHourlyScanDistribution(sellerId);
      final dailyTrend = await getDailyScanTrend(sellerId);

      // Find peak hour
      int peakHour = 0;
      int maxScans = 0;
      hourlyScanDistribution.forEach((hour, scans) {
        if (scans > maxScans) {
          maxScans = scans;
          peakHour = hour;
        }
      });

      return {
        ...stats,
        'followersFromQR': followersFromQR,
        'conversionRate': conversionRate.toStringAsFixed(1) + '%',
        'peakHour': peakHour,
        'peakHourScans': maxScans,
        'hourlyScanDistribution': hourlyScanDistribution,
        'dailyTrend': dailyTrend,
      };
    } catch (e) {
      debugPrint('Error getting comprehensive analytics: $e');
      return {};
    }
  }
}

