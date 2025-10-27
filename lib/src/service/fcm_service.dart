import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../res/firebase_constants.dart';
import 'notification_preferences_service.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;
  String? _currentToken;

  // Initialize FCM service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permission
      final permission = await requestPermission();
      if (!permission) {
        debugPrint('FCM: Permission denied');
        return;
      }

      // Get FCM token
      await _getToken();

      // Setup message handlers
      _setupMessageHandlers();

      // Listen to token refresh
      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      _isInitialized = true;
      debugPrint('FCM: Initialized successfully');
    } catch (e) {
      debugPrint('FCM: Initialization failed: $e');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  // Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const rewardChannel = AndroidNotificationChannel(
      'reward_notifications',
      'Reward Notifications',
      description: 'Notifications about reward redemptions and updates',
      importance: Importance.high,
    );

    const generalChannel = AndroidNotificationChannel(
      'general_notifications',
      'General Notifications',
      description: 'General app notifications',
      importance: Importance.defaultImportance,
    );

    // QR System notification channels
    const qrWelcomeChannel = AndroidNotificationChannel(
      'qr_welcome_notifications',
      'QR Welcome Notifications',
      description: 'Welcome notifications after QR code scans',
      importance: Importance.high,
    );

    const qrThankYouChannel = AndroidNotificationChannel(
      'qr_thank_you_notifications',
      'QR Thank You Notifications',
      description: 'Thank you notifications after offer redemptions',
      importance: Importance.high,
    );

    const qrOfferReminderChannel = AndroidNotificationChannel(
      'qr_offer_reminder_notifications',
      'QR Offer Reminder Notifications',
      description: 'Reminder notifications for expiring offers',
      importance: Importance.max,
    );

    const qrReEngagementChannel = AndroidNotificationChannel(
      'qr_re_engagement_notifications',
      'QR Re-engagement Notifications',
      description: 'Re-engagement notifications for inactive followers',
      importance: Importance.defaultImportance,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(rewardChannel);
      await androidPlugin.createNotificationChannel(generalChannel);
      await androidPlugin.createNotificationChannel(qrWelcomeChannel);
      await androidPlugin.createNotificationChannel(qrThankYouChannel);
      await androidPlugin.createNotificationChannel(qrOfferReminderChannel);
      await androidPlugin.createNotificationChannel(qrReEngagementChannel);
    }
  }

  // Request notification permission
  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
             settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('FCM: Permission request failed: $e');
      return false;
    }
  }

  // Get FCM token
  Future<String?> getToken() async {
    if (_currentToken != null) return _currentToken;
    return await _getToken();
  }

  Future<String?> _getToken() async {
    debugPrint("Getting token");
    try {
      _currentToken = await _messaging.getToken();
      debugPrint("Current token: $_currentToken");
      if (_currentToken != null) {
        debugPrint("Current token: $_currentToken");
        await _updateTokenInFirestore(_currentToken!);
      }
      return _currentToken;
    } catch (e) {
      debugPrint('FCM: Failed to get token: $e');
      return null;
    }
  }

  // Update token in Firestore
  Future<void> _updateTokenInFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userRef = _firestore.collection(FirebaseConstants.usersCollection).doc(user.uid);
      
      // Get current user data
      final userDoc = await userRef.get();
      if (!userDoc.exists) return;

      final currentTokens = List<String>.from(userDoc.data()?['fcmTokens'] ?? []);
      
      // Add new token if not already present
      if (!currentTokens.contains(token)) {
        currentTokens.add(token);
      }

      // Update user document
      await userRef.update({
        'fcmToken': token,
        'fcmTokens': currentTokens,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('FCM: Token updated in Firestore');
    } catch (e) {
      debugPrint('FCM: Failed to update token in Firestore: $e');
    }
  }

  // Handle token refresh
  void _onTokenRefresh(String newToken) {
    _currentToken = newToken;
    _updateTokenInFirestore(newToken);
    debugPrint('FCM: Token refreshed: $newToken');
  }

  // Setup message handlers
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background messages (when app is in background but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Terminated app messages
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('FCM: Foreground message received: ${message.messageId}');

    // Track notification delivery
    await _trackNotificationDelivery(message);

    // Check if notification should be shown based on user preferences
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final data = message.data;
      final notificationType = data['type'] as String?;
      final sellerId = data['sellerId'] as String?;
      
      final preferencesService = NotificationPreferencesService();
      final shouldShow = await preferencesService.shouldShowNotification(
        user.uid,
        notificationType ?? 'other',
        sellerId,
        DateTime.now(),
      );
      
      if (!shouldShow) {
        debugPrint('FCM: Notification blocked by user preferences');
        return; // Don't show notification
      }
    }

    // Show local notification
    await _showLocalNotification(message);

    // Save to Firestore for in-app notification center
    await _saveNotificationToFirestore(message);
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('FCM: Notification tapped: ${message.messageId}');
    
    // Track notification open
    _trackNotificationOpen(message);
    
    // Handle deep linking based on notification data
    final data = message.data;
    final route = data['route'];
    
    if (route != null) {
      // Navigate to the specified route
      // Note: This requires access to the router context
      // We'll handle this in the main app with a global navigator key
      _handleDeepLink(route, data);
    }
  }

  // Handle deep linking
  void _handleDeepLink(String route, Map<String, dynamic> data) {
    debugPrint('FCM: Deep link: $route with data: $data');
    
    // Handle QR notification deep linking
    final notificationType = data['type'] as String?;
    final sellerId = data['sellerId'] as String?;
    final offerId = data['offerId'] as String?;
    
    String? targetRoute;
    
    switch (notificationType) {
      case 'welcome':
      case 're_engagement':
        if (sellerId != null) {
          targetRoute = '/seller_profile_view?sellerId=$sellerId';
        }
        break;
      case 'thank_you':
        targetRoute = '/my_rewards_view';
        break;
      case 'offer_reminder':
        if (offerId != null) {
          targetRoute = '/offer_detail_view?offerId=$offerId';
        }
        break;
      default:
        // Use the provided route if available
        targetRoute = route;
        break;
    }
    
    if (targetRoute != null && _notificationTapHandler != null) {
      _notificationTapHandler!(targetRoute, data);
    }
  }

  // Callback for notification tap handling
  Function(String route, Map<String, dynamic> data)? _notificationTapHandler;

  // Set notification tap handler
  void setNotificationTapHandler(Function(String route, Map<String, dynamic> data)? handler) {
    _notificationTapHandler = handler;
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final notificationType = _getNotificationTypeFromData(message.data);
    final channelInfo = _getChannelInfo(notificationType);
    final actions = _getNotificationActions(notificationType, message.data);

    final androidDetails = AndroidNotificationDetails(
      channelInfo['channelId'],
      channelInfo['channelName'],
      channelDescription: channelInfo['description'],
      importance: channelInfo['importance'],
      priority: channelInfo['priority'],
      icon: '@mipmap/ic_launcher',
      actions: actions,
      groupKey: message.data['sellerId'] != null ? 'seller_${message.data['sellerId']}' : null,
      setAsGroupSummary: false,
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        notification.body ?? '',
        htmlFormatBigText: true,
        contentTitle: notification.title,
        htmlFormatContentTitle: true,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  // Get channel information based on notification type
  Map<String, dynamic> _getChannelInfo(NotificationType type) {
    switch (type) {
      case NotificationType.welcome:
        return {
          'channelId': 'qr_welcome_notifications',
          'channelName': 'QR Welcome Notifications',
          'description': 'Welcome notifications after QR code scans',
          'importance': Importance.high,
          'priority': Priority.high,
        };
      case NotificationType.thankYou:
        return {
          'channelId': 'qr_thank_you_notifications',
          'channelName': 'QR Thank You Notifications',
          'description': 'Thank you notifications after offer redemptions',
          'importance': Importance.high,
          'priority': Priority.high,
        };
      case NotificationType.offerReminder:
        return {
          'channelId': 'qr_offer_reminder_notifications',
          'channelName': 'QR Offer Reminder Notifications',
          'description': 'Reminder notifications for expiring offers',
          'importance': Importance.max,
          'priority': Priority.max,
        };
      case NotificationType.reEngagement:
        return {
          'channelId': 'qr_re_engagement_notifications',
          'channelName': 'QR Re-engagement Notifications',
          'description': 'Re-engagement notifications for inactive followers',
          'importance': Importance.defaultImportance,
          'priority': Priority.defaultPriority,
        };
      case NotificationType.rewardRedemption:
      case NotificationType.rewardExpiring:
      case NotificationType.rewardShipped:
      case NotificationType.rewardDelivered:
        return {
          'channelId': 'reward_notifications',
          'channelName': 'Reward Notifications',
          'description': 'Notifications about reward redemptions and updates',
          'importance': Importance.high,
          'priority': Priority.high,
        };
      default:
        return {
          'channelId': 'general_notifications',
          'channelName': 'General Notifications',
          'description': 'General app notifications',
          'importance': Importance.defaultImportance,
          'priority': Priority.defaultPriority,
        };
    }
  }

  // Get notification actions based on type
  List<AndroidNotificationAction> _getNotificationActions(NotificationType type, Map<String, dynamic> data) {
    switch (type) {
      case NotificationType.welcome:
        return [
          const AndroidNotificationAction(
            'view_profile',
            'View Profile',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
          const AndroidNotificationAction(
            'dismiss',
            'Dismiss',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
        ];
      case NotificationType.thankYou:
        return [
          const AndroidNotificationAction(
            'view_rewards',
            'View Rewards',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
          const AndroidNotificationAction(
            'dismiss',
            'Dismiss',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
        ];
      case NotificationType.offerReminder:
        return [
          const AndroidNotificationAction(
            'redeem_now',
            'Redeem Now',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
          const AndroidNotificationAction(
            'remind_later',
            'Remind Later',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
        ];
      case NotificationType.reEngagement:
        return [
          const AndroidNotificationAction(
            'view_offers',
            'View Offers',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
          const AndroidNotificationAction(
            'unfollow',
            'Unfollow',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
        ];
      default:
        return [
          const AndroidNotificationAction(
            'dismiss',
            'Dismiss',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
        ];
    }
  }

  // Save notification to Firestore
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notification = message.notification;
      if (notification == null) return;

      final notificationRef = _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .doc();

      final appNotification = AppNotification(
        id: notificationRef.id,
        userId: user.uid,
        title: notification.title ?? 'Notification',
        body: notification.body ?? '',
        type: _getNotificationTypeFromData(message.data),
        data: message.data,
        createdAt: DateTime.now(),
        actionRoute: message.data['route'],
        actionText: message.data['actionText'],
      );

      await notificationRef.set(appNotification.toFirestore());
    } catch (e) {
      debugPrint('FCM: Failed to save notification to Firestore: $e');
    }
  }

  // Get notification type from data
  NotificationType _getNotificationTypeFromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'reward_redemption':
        return NotificationType.rewardRedemption;
      case 'reward_expiring':
        return NotificationType.rewardExpiring;
      case 'reward_shipped':
        return NotificationType.rewardShipped;
      case 'reward_delivered':
        return NotificationType.rewardDelivered;
      case 'tournament_win':
        return NotificationType.tournamentWin;
      case 'offer_available':
        return NotificationType.offerAvailable;
      case 'points_earned':
        return NotificationType.pointsEarned;
      // QR System notification types
      case 'welcome':
        return NotificationType.welcome;
      case 'thank_you':
        return NotificationType.thankYou;
      case 'offer_reminder':
        return NotificationType.offerReminder;
      case 're_engagement':
        return NotificationType.reEngagement;
      default:
        return NotificationType.other;
    }
  }

  // Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('FCM: Local notification tapped: ${response.payload}');
    debugPrint('FCM: Action ID: ${response.actionId}');
    
    // Parse payload and handle deep linking
    if (response.payload != null) {
      try {
        // Parse the payload data
        final data = Map<String, dynamic>.from(response.payload as Map);
        final actionId = response.actionId;
        
        // Handle action button taps
        if (actionId != null && actionId != 'dismiss') {
          _handleNotificationAction(actionId, data);
        } else {
          // Handle regular notification tap
          final route = data['route'] as String?;
          if (route != null) {
            _handleDeepLink(route, data);
          }
        }
      } catch (e) {
        debugPrint('FCM: Error parsing notification payload: $e');
      }
    }
  }

  // Handle notification action button taps
  void _handleNotificationAction(String actionId, Map<String, dynamic> data) {
    // Track action click
    _trackActionClick(actionId, data);
    
    final sellerId = data['sellerId'] as String?;
    final offerId = data['offerId'] as String?;
    
    String? targetRoute;
    
    switch (actionId) {
      case 'view_profile':
        if (sellerId != null) {
          targetRoute = '/seller_profile_view?sellerId=$sellerId';
        }
        break;
      case 'view_rewards':
        targetRoute = '/my_rewards_view';
        break;
      case 'redeem_now':
        if (offerId != null) {
          targetRoute = '/offer_detail_view?offerId=$offerId';
        }
        break;
      case 'view_offers':
        if (sellerId != null) {
          targetRoute = '/seller_profile_view?sellerId=$sellerId';
        }
        break;
      case 'unfollow':
        // Handle unfollow action - could show a dialog or directly unfollow
        debugPrint('FCM: Unfollow action for seller: $sellerId');
        break;
      case 'remind_later':
        // Handle remind later - could schedule a reminder
        debugPrint('FCM: Remind later for offer: $offerId');
        break;
      default:
        debugPrint('FCM: Unknown action: $actionId');
        break;
    }
    
    if (targetRoute != null && _notificationTapHandler != null) {
      _notificationTapHandler!(targetRoute, data);
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('FCM: Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('FCM: Failed to subscribe to topic $topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('FCM: Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('FCM: Failed to unsubscribe from topic $topic: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Get notification permission status
  Future<AuthorizationStatus> getPermissionStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final status = await getPermissionStatus();
    return status == AuthorizationStatus.authorized;
  }

  // Track notification delivery
  Future<void> _trackNotificationDelivery(RemoteMessage message) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final data = message.data;
      final notificationType = data['type'] as String?;
      final sellerId = data['sellerId'] as String?;
      final campaignId = data['campaignId'] as String?;

      await _firestore
          .collection(FirebaseConstants.notificationAnalyticsCollection)
          .add({
        'userId': user.uid,
        'messageId': message.messageId,
        'notificationType': notificationType,
        'sellerId': sellerId,
        'campaignId': campaignId,
        'event': 'delivered',
        'timestamp': FieldValue.serverTimestamp(),
        'platform': Platform.isAndroid ? 'android' : 'ios',
      });

      debugPrint('FCM: Notification delivery tracked');
    } catch (e) {
      debugPrint('FCM: Failed to track notification delivery: $e');
    }
  }

  // Track notification open
  Future<void> _trackNotificationOpen(RemoteMessage message) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final data = message.data;
      final notificationType = data['type'] as String?;
      final sellerId = data['sellerId'] as String?;
      final campaignId = data['campaignId'] as String?;

      await _firestore
          .collection(FirebaseConstants.notificationAnalyticsCollection)
          .add({
        'userId': user.uid,
        'messageId': message.messageId,
        'notificationType': notificationType,
        'sellerId': sellerId,
        'campaignId': campaignId,
        'event': 'opened',
        'timestamp': FieldValue.serverTimestamp(),
        'platform': Platform.isAndroid ? 'android' : 'ios',
      });

      debugPrint('FCM: Notification open tracked');
    } catch (e) {
      debugPrint('FCM: Failed to track notification open: $e');
    }
  }

  // Track action button click
  Future<void> _trackActionClick(String actionId, Map<String, dynamic> data) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notificationType = data['type'] as String?;
      final sellerId = data['sellerId'] as String?;
      final campaignId = data['campaignId'] as String?;

      await _firestore
          .collection(FirebaseConstants.notificationAnalyticsCollection)
          .add({
        'userId': user.uid,
        'notificationType': notificationType,
        'sellerId': sellerId,
        'campaignId': campaignId,
        'event': 'action_clicked',
        'actionId': actionId,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': Platform.isAndroid ? 'android' : 'ios',
      });

      debugPrint('FCM: Action click tracked: $actionId');
    } catch (e) {
      debugPrint('FCM: Failed to track action click: $e');
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM: Background message received: ${message.messageId}');
  
  // Handle background message
  // Note: Limited functionality in background
  // Main processing should be done in Cloud Functions
}
