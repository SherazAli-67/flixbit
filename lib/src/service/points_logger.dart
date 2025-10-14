import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/points_config.dart';

/// Service to handle points logging and tracking
class PointsLogger {
  // Singleton pattern
  static final PointsLogger _instance = PointsLogger._internal();
  factory PointsLogger() => _instance;
  PointsLogger._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _pointsLogs => _firestore.collection('points_logs');
  CollectionReference get _dailyStats => _firestore.collection('daily_stats');
  CollectionReference get _achievements => _firestore.collection('achievements');

  /// Log points earned from an activity
  Future<void> logPoints({
    required String userId,
    required String activity,
    required int points,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final timestamp = FieldValue.serverTimestamp();
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Create points log
      await _pointsLogs.add({
        'user_id': userId,
        'activity': activity,
        'points': points,
        'timestamp': timestamp,
        'metadata': metadata,
      });

      // Update daily stats
      final dailyRef = _dailyStats.doc('${userId}_$today');
      await _firestore.runTransaction((transaction) async {
        final dailyDoc = await transaction.get(dailyRef);
        
        if (dailyDoc.exists) {
          final data = dailyDoc.data() as Map<String, dynamic>;
          final currentPoints = data['activities']?[activity] ?? 0;
          
          transaction.update(dailyRef, {
            'activities.${activity}': currentPoints + points,
            'total_points': FieldValue.increment(points),
            'last_updated': timestamp,
          });
        } else {
          transaction.set(dailyRef, {
            'user_id': userId,
            'date': today,
            'activities': {activity: points},
            'total_points': points,
            'last_updated': timestamp,
          });
        }
      });

      debugPrint('Points logged: $points for $activity');
    } catch (e) {
      debugPrint('Error logging points: $e');
      rethrow;
    }
  }

  /// Check if user has reached daily limit for an activity
  Future<bool> hasReachedDailyLimit(String userId, String activity) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final dailyDoc = await _dailyStats.doc('${userId}_$today').get();

      if (!dailyDoc.exists) return false;

      final data = dailyDoc.data() as Map<String, dynamic>;
      final currentPoints = data['activities']?[activity] ?? 0;

      return PointsConfig.hasReachedDailyLimit(activity, currentPoints);
    } catch (e) {
      debugPrint('Error checking daily limit: $e');
      return true; // Fail safe: assume limit reached on error
    }
  }

  /// Get daily statistics for a user
  Future<Map<String, dynamic>> getDailyStats(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final doc = await _dailyStats.doc('${userId}_$today').get();

      if (!doc.exists) {
        return {
          'total_points': 0,
          'activities': {},
        };
      }

      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting daily stats: $e');
      rethrow;
    }
  }

  /// Get points history for a user
  Stream<List<Map<String, dynamic>>> getPointsHistory(String userId) {
    return _pointsLogs
        .where('user_id', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();
        });
  }

  /// Track achievement progress
  Future<void> updateAchievementProgress(
    String userId,
    String achievement,
    int progress,
  ) async {
    try {
      final ref = _achievements.doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(ref);
        
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final isUnlocked = data['unlocked']?[achievement] ?? false;
          
          // Check if achievement is newly unlocked
          if (!isUnlocked && 
              PointsConfig.isAchievementUnlocked(achievement, progress)) {
            // Award achievement points
            final reward = PointsConfig.getAchievementReward(achievement);
            await logPoints(
              userId: userId,
              activity: 'achievement_${achievement}',
              points: reward,
              metadata: {'achievement': achievement},
            );
            
            transaction.update(ref, {
              'progress.${achievement}': progress,
              'unlocked.${achievement}': true,
              'last_updated': FieldValue.serverTimestamp(),
            });
          } else {
            transaction.update(ref, {
              'progress.${achievement}': progress,
              'last_updated': FieldValue.serverTimestamp(),
            });
          }
        } else {
          transaction.set(ref, {
            'user_id': userId,
            'progress': {achievement: progress},
            'unlocked': {achievement: false},
            'last_updated': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      debugPrint('Error updating achievement progress: $e');
      rethrow;
    }
  }

  /// Get achievement progress for a user
  Future<Map<String, dynamic>> getAchievements(String userId) async {
    try {
      final doc = await _achievements.doc(userId).get();
      
      if (!doc.exists) {
        return {
          'progress': {},
          'unlocked': {},
        };
      }

      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting achievements: $e');
      rethrow;
    }
  }

  /// Generate points report for a time period
  Future<Map<String, dynamic>> generateReport(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _pointsLogs
          .where('user_id', isEqualTo: userId)
          .where('timestamp', 
                isGreaterThan: Timestamp.fromDate(startDate.subtract(const Duration(days: 1))))
          .where('timestamp', 
                isLessThan: Timestamp.fromDate(endDate.add(const Duration(days: 1))))
          .get();

      final activities = <String, int>{};
      var totalPoints = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final activity = data['activity'] as String;
        final points = data['points'] as int;

        activities[activity] = (activities[activity] ?? 0) + points;
        totalPoints += points;
      }

      return {
        'total_points': totalPoints,
        'activities': activities,
        'period_start': startDate.toIso8601String(),
        'period_end': endDate.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error generating report: $e');
      rethrow;
    }
  }
}
