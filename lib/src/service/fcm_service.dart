import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../res/firebase_constants.dart';

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

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(rewardChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
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
    try {
      _currentToken = await _messaging.getToken();
      if (_currentToken != null) {
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

    // Show local notification
    await _showLocalNotification(message);

    // Save to Firestore for in-app notification center
    await _saveNotificationToFirestore(message);
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('FCM: Notification tapped: ${message.messageId}');
    
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
    // This will be called from the main app with proper context
    debugPrint('FCM: Deep link: $route with data: $data');
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'reward_notifications',
      'Reward Notifications',
      channelDescription: 'Notifications about reward redemptions and updates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
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
      default:
        return NotificationType.other;
    }
  }

  // Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('FCM: Local notification tapped: ${response.payload}');
    
    // Parse payload and handle deep linking
    if (response.payload != null) {
      // This will be handled by the main app
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
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM: Background message received: ${message.messageId}');
  
  // Handle background message
  // Note: Limited functionality in background
  // Main processing should be done in Cloud Functions
}
