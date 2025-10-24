import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../res/firebase_constants.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  List<AppNotification> _allNotifications = [];
  List<AppNotification> _unreadNotifications = [];
  bool _isLoading = false;
  String? _error;
  String? _userId;

  // Getters
  List<AppNotification> get allNotifications => _allNotifications;
  List<AppNotification> get unreadNotifications => _unreadNotifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadNotifications.length;

  // Initialize provider with user ID
  Future<void> initialize(String userId) async {
    _userId = userId;
    await loadNotifications();
  }

  // Load notifications from Firestore
  Future<void> loadNotifications() async {
    if (_userId == null) return;

    _setLoading(true);
    _clearError();

    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _allNotifications = snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();

      _unreadNotifications = _allNotifications
          .where((notification) => !notification.isRead)
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load notifications: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Stream notifications for real-time updates
  Stream<List<AppNotification>> getNotificationsStream() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection(FirebaseConstants.notificationsCollection)
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});

      // Update local state
      final index = _allNotifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _allNotifications[index] = _allNotifications[index].copyWith(isRead: true);
        _unreadNotifications.removeWhere((n) => n.id == notificationId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_userId == null || _unreadNotifications.isEmpty) return;

    try {
      final batch = _firestore.batch();
      
      for (final notification in _unreadNotifications) {
        final docRef = _firestore
            .collection(FirebaseConstants.notificationsCollection)
            .doc(notification.id);
        batch.update(docRef, {'isRead': true});
      }

      await batch.commit();

      // Update local state
      _allNotifications = _allNotifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadNotifications.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .doc(notificationId)
          .delete();

      // Update local state
      _allNotifications.removeWhere((n) => n.id == notificationId);
      _unreadNotifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    if (_userId == null) return;

    try {
      final batch = _firestore.batch();
      
      for (final notification in _allNotifications) {
        final docRef = _firestore
            .collection(FirebaseConstants.notificationsCollection)
            .doc(notification.id);
        batch.delete(docRef);
      }

      await batch.commit();

      // Update local state
      _allNotifications.clear();
      _unreadNotifications.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
    }
  }

  // Get notifications by type
  List<AppNotification> getNotificationsByType(NotificationType type) {
    return _allNotifications
        .where((notification) => notification.type == type)
        .toList();
  }

  // Get unread notifications by type
  List<AppNotification> getUnreadNotificationsByType(NotificationType type) {
    return _unreadNotifications
        .where((notification) => notification.type == type)
        .toList();
  }

  // Check if user has unread notifications of specific type
  bool hasUnreadNotificationsOfType(NotificationType type) {
    return _unreadNotifications.any((notification) => notification.type == type);
  }

  // Get notification count by type
  int getNotificationCountByType(NotificationType type) {
    return _allNotifications
        .where((notification) => notification.type == type)
        .length;
  }

  // Get unread notification count by type
  int getUnreadNotificationCountByType(NotificationType type) {
    return _unreadNotifications
        .where((notification) => notification.type == type)
        .length;
  }

  // Refresh notifications
  Future<void> refresh() async {
    await loadNotifications();
  }

  // Create a new notification (for testing or manual creation)
  Future<void> createNotification({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic> data = const {},
    String? actionRoute,
    String? actionText,
  }) async {
    if (_userId == null) return;

    try {
      final notificationRef = _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .doc();

      final notification = AppNotification(
        id: notificationRef.id,
        userId: _userId!,
        title: title,
        body: body,
        type: type,
        data: data,
        createdAt: DateTime.now(),
        actionRoute: actionRoute,
        actionText: actionText,
      );

      await notificationRef.set(notification.toFirestore());

      // Add to local state
      _allNotifications.insert(0, notification);
      _unreadNotifications.insert(0, notification);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  // Private helper methods
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
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

