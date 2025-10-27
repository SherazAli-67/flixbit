import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_preferences_model.dart';
import '../res/firebase_constants.dart';

class NotificationPreferencesService {
  static final NotificationPreferencesService _instance = NotificationPreferencesService._internal();
  factory NotificationPreferencesService() => _instance;
  NotificationPreferencesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<NotificationPreferences?> getPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.notificationPreferencesCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return NotificationPreferences.fromFirestore(doc);
      } else {
        return getDefaultPreferences(userId);
      }
    } catch (e) {
      debugPrint('Error getting notification preferences: $e');
      return null;
    }
  }

  Stream<NotificationPreferences?> getUserPreferencesStream(){
    String userID = FirebaseAuth.instance.currentUser!.uid;
    return _firestore
        .collection(FirebaseConstants.notificationPreferencesCollection)
        .doc(userID).snapshots().map((snapshot)=> snapshot.exists ? NotificationPreferences.fromJson(snapshot.data()!) : null);

  }
  Future<bool> updatePreferences(String userId, NotificationPreferences preferences) async {
    try {
      await _firestore
          .collection(FirebaseConstants.notificationPreferencesCollection)
          .doc(userId)
          .set(preferences.toFirestore());

      debugPrint('Notification preferences updated for user: $userId');
      return true;
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
      return false;
    }
  }

  Future<bool> toggleNotificationType(String type, bool enabled) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      final preferences = await getPreferences(userId);
      if (preferences == null) return false;

      NotificationPreferences updatedPreferences;
      
      switch (type) {
        case 'welcome':
          updatedPreferences = preferences.copyWith(
            qrWelcomeEnabled: enabled,
            updatedAt: DateTime.now(),
          );
          break;
        case 'thank_you':
          updatedPreferences = preferences.copyWith(
            qrThankYouEnabled: enabled,
            updatedAt: DateTime.now(),
          );
          break;
        case 'offer_reminder':
          updatedPreferences = preferences.copyWith(
            qrOfferReminderEnabled: enabled,
            updatedAt: DateTime.now(),
          );
          break;
        case 're_engagement':
          updatedPreferences = preferences.copyWith(
            qrReEngagementEnabled: enabled,
            updatedAt: DateTime.now(),
          );
          break;
        case 'reward_redemption':
          updatedPreferences = preferences.copyWith(
            rewardNotificationsEnabled: enabled,
            updatedAt: DateTime.now(),
          );
          break;
        case 'tournament_win':
          updatedPreferences = preferences.copyWith(
            tournamentNotificationsEnabled: enabled,
            updatedAt: DateTime.now(),
          );
          break;
        case 'offer_available':
          updatedPreferences = preferences.copyWith(
            offerNotificationsEnabled: enabled,
            updatedAt: DateTime.now(),
          );
          break;
        case 'points_earned':
          updatedPreferences = preferences.copyWith(
            pointsNotificationsEnabled: enabled,
            updatedAt: DateTime.now(),
          );
          break;
        default:
          return false;
      }

      return await updatePreferences(userId, updatedPreferences);
    } catch (e) {
      debugPrint('Error toggling notification type: $e');
      return false;
    }
  }

  Future<bool> setPerSellerPreference( String sellerId, bool enabled) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      final preferences = await getPreferences(userId);
      if (preferences == null) return false;

      final updatedPerSellerPreferences = Map<String, bool>.from(preferences.perSellerPreferences);
      updatedPerSellerPreferences[sellerId] = enabled;

      final updatedPreferences = preferences.copyWith(
        perSellerPreferences: updatedPerSellerPreferences,
        updatedAt: DateTime.now(),
      );

      return await updatePreferences(userId, updatedPreferences);
    } catch (e) {
      debugPrint('Error setting per-seller preference: $e');
      return false;
    }
  }


  Future<bool> shouldShowNotification(String userId, String type, String? sellerId, DateTime time) async {
    try {
      final preferences = await getPreferences(userId);
      if (preferences == null) return true; // Default to showing if no preferences

      if (!preferences.pushNotificationsEnabled) return false;

      if (!preferences.isNotificationTypeEnabled(type)) return false;

      if (sellerId != null && !preferences.isSellerNotificationEnabled(sellerId)) return false;
      return true;
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return true; // Default to showing on error
    }
  }

  NotificationPreferences getDefaultPreferences(String userId) {
    return NotificationPreferences(
      // userId: userId,
      pushNotificationsEnabled: true,
      rewardNotificationsEnabled: true,
      tournamentNotificationsEnabled: true,
      offerNotificationsEnabled: true,
      pointsNotificationsEnabled: true,
      expiryWarningEnabled: true,
      expiryWarningDays: 3,
      qrWelcomeEnabled: true,
      qrThankYouEnabled: true,
      qrOfferReminderEnabled: true,
      qrReEngagementEnabled: true,
      perSellerPreferences: const {},
      quietHoursEnabled: false,
      quietHoursStart: null,
      quietHoursEnd: null,
      updatedAt: DateTime.now(),
    );
  }

  Future<List<Map<String, dynamic>>> getFollowedSellers(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.sellerFollowersCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final sellers = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final sellerId = data['sellerId'] as String?;
        
        if (sellerId != null) {
          final sellerDoc = await _firestore
              .collection(FirebaseConstants.sellersCollection)
              .doc(sellerId)
              .get();
          
          if (sellerDoc.exists) {
            final sellerData = sellerDoc.data()!;
            sellers.add({
              'sellerId': sellerId,
              'sellerName': sellerData['businessName'] ?? 'Unknown Seller',
              'followedAt': data['followedAt'],
            });
          }
        }
      }
      
      return sellers;
    } catch (e) {
      debugPrint('Error getting followed sellers: $e');
      return [];
    }
  }

  Stream<NotificationPreferences?> getPreferencesStream(String userId) {
    return _firestore
        .collection(FirebaseConstants.notificationPreferencesCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return NotificationPreferences.fromFirestore(doc);
      } else {
        return getDefaultPreferences(userId);
      }
    });
  }
}