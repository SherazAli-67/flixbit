import 'package:flutter/foundation.dart';

/// Configuration for points earning system across the app
class PointsConfig {
  /// Point values for different activities
  static const earnRates = {
    // Tournament related points
    'tournament_prediction': 10,    // Points for correct prediction
    'tournament_qualification': 50, // Bonus for qualifying
    'tournament_win': 500,         // Points for tournament win
    
    // Engagement points
    'video_ad': 5,                 // Points per video ad watched
    'referral': 20,                // Points per successful referral
    'review': 15,                  // Points for verified review
    'qr_scan': 10,                 // Points per QR scan
    'daily_login': 5,              // Daily login bonus
    
    // Special events (configurable)
    'special_event': 50,           // Special event bonus
    'streak_bonus': 25,            // Consecutive day streak bonus
  };

  /// Daily limits for point earning activities
  static const dailyLimits = {
    'video_ad': 50,    // Max 10 videos per day (5 points each)
    'qr_scan': 100,    // Max 10 scans per day (10 points each)
    'review': 45,      // Max 3 reviews per day (15 points each)
  };

  /// Cooldown periods (in minutes) for activities
  static const cooldowns = {
    'video_ad': 5,     // 5 minutes between videos
    'qr_scan': 15,     // 15 minutes between scans
    'review': 60,      // 1 hour between reviews
  };

  /// Streak bonuses configuration
  static const streakBonuses = {
    7: 50,    // 7 day streak bonus
    30: 250,  // 30 day streak bonus
    90: 1000, // 90 day streak bonus
  };

  /// Special event multipliers
  static const eventMultipliers = {
    'weekend_bonus': 2.0,      // Double points on weekends
    'happy_hour': 1.5,         // 50% bonus during happy hours
    'special_promotion': 3.0,  // Triple points during promotions
  };

  /// Achievement thresholds
  static const achievements = {
    'prediction_master': 100,  // 100 correct predictions
    'video_watcher': 50,      // 50 videos watched
    'review_expert': 25,      // 25 reviews submitted
    'qr_hunter': 100,         // 100 QR codes scanned
    'referral_king': 10,      // 10 successful referrals
  };

  /// Achievement rewards (points)
  static const achievementRewards = {
    'prediction_master': 1000,
    'video_watcher': 500,
    'review_expert': 750,
    'qr_hunter': 1000,
    'referral_king': 1500,
  };

  /// Minimum points required for different actions
  static const minimumRequirements = {
    'tournament_entry': 100,   // Min points to enter tournament
    'special_offer': 500,     // Min points for special offers
    'premium_features': 1000,  // Min points for premium features
  };

  /// Debug mode configuration
  static bool get isDebugMode => kDebugMode;
  
  /// Debug multiplier (only applies in debug mode)
  static const debugMultiplier = 10;

  /// Get points for an activity
  static int getPoints(String activity) {
    if (isDebugMode) {
      return (earnRates[activity] ?? 0) * debugMultiplier;
    }
    return earnRates[activity] ?? 0;
  }

  /// Check if user has reached daily limit
  static bool hasReachedDailyLimit(String activity, int currentPoints) {
    final limit = dailyLimits[activity];
    if (limit == null) return false;
    return currentPoints >= limit;
  }

  /// Get remaining points possible for today
  static int getRemainingPoints(String activity, int currentPoints) {
    final limit = dailyLimits[activity];
    if (limit == null) return 0;
    return limit - currentPoints;
  }

  /// Calculate streak bonus
  static int getStreakBonus(int streakDays) {
    int bonus = 0;
    for (var days in streakBonuses.keys) {
      if (streakDays >= days) {
        bonus = streakBonuses[days]!;
      }
    }
    return bonus;
  }

  /// Apply event multiplier
  static double applyEventMultiplier(String event, int basePoints) {
    final multiplier = eventMultipliers[event] ?? 1.0;
    return basePoints * multiplier;
  }

  /// Check if achievement is unlocked
  static bool isAchievementUnlocked(String achievement, int progress) {
    final threshold = achievements[achievement];
    if (threshold == null) return false;
    return progress >= threshold;
  }

  /// Get achievement reward
  static int getAchievementReward(String achievement) {
    return achievementRewards[achievement] ?? 0;
  }
}
