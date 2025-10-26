import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/qr_notification_campaign_model.dart';
import '../models/seller_follower_model.dart';
import '../res/firebase_constants.dart';
import 'notification_quota_service.dart';

class QRNotificationService {
  // Singleton pattern
  static final QRNotificationService _instance = QRNotificationService._internal();
  factory QRNotificationService() => _instance;
  QRNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationQuotaService _quotaService = NotificationQuotaService();

  // Create a new notification campaign
  Future<String> createCampaign({
    required String sellerId,
    required String title,
    required String message,
    required NotificationAudience audience,
    Map<String, dynamic>? filters,
    DateTime? scheduledFor,
    String? actionRoute,
    String? actionText,
  }) async {
    try {
      final campaignRef = _firestore
          .collection(FirebaseConstants.qrNotificationCampaignsCollection)
          .doc();

      final campaign = QRNotificationCampaign(
        id: campaignRef.id,
        sellerId: sellerId,
        title: title,
        message: message,
        audience: audience,
        createdAt: DateTime.now(),
        scheduledFor: scheduledFor,
        status: scheduledFor != null ? CampaignStatus.scheduled : CampaignStatus.draft,
        filters: filters,
        actionRoute: actionRoute,
        actionText: actionText,
      );

      await campaignRef.set(campaign.toFirestore());
      debugPrint('QR Notification: Campaign created: ${campaign.id}');
      return campaign.id;
    } catch (e) {
      debugPrint('QR Notification: Failed to create campaign: $e');
      rethrow;
    }
  }

  // Get target audience based on campaign filters
  Future<List<String>> getTargetAudience({
    required String sellerId,
    required NotificationAudience audience,
    Map<String, dynamic>? filters,
  }) async {
    try {
      var query = _firestore
          .collection(FirebaseConstants.sellerFollowersCollection)
          .where('sellerId', isEqualTo: sellerId);

      // Apply audience-specific filters
      switch (audience) {
        case NotificationAudience.allFollowers:
          // No additional filters
          break;
        case NotificationAudience.qrScanFollowers:
          query = query.where('followSource', isEqualTo: FollowSource.qrScan);
          break;
        case NotificationAudience.offerFollowers:
          query = query.where('followSource', isEqualTo: FollowSource.offerRedemption);
          break;
        case NotificationAudience.manualFollowers:
          query = query.where('followSource', isEqualTo: FollowSource.manual);
          break;
        case NotificationAudience.dateRangeFollowers:
          // Apply date range filters from filters parameter
          if (filters != null && filters['startDate'] != null) {
            final startDate = DateTime.parse(filters['startDate']);
            query = query.where('followedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
          }
          if (filters != null && filters['endDate'] != null) {
            final endDate = DateTime.parse(filters['endDate']);
            query = query.where('followedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
          }
          break;
        case NotificationAudience.custom:
          // Apply custom filters
          if (filters != null) {
            if (filters['followSource'] != null) {
              query = query.where('followSource', isEqualTo: filters['followSource']);
            }
            if (filters['startDate'] != null) {
              final startDate = DateTime.parse(filters['startDate']);
              query = query.where('followedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
            }
            if (filters['endDate'] != null) {
              final endDate = DateTime.parse(filters['endDate']);
              query = query.where('followedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
            }
          }
          break;
      }

      // Always filter for users with notifications enabled
      query = query.where('notificationsEnabled', isEqualTo: true);

      final snapshot = await query.get();
      final userIds = <String>[];

      for (final doc in snapshot.docs) {
        final follower = SellerFollower.fromJson(doc.data());
        userIds.add(follower.userId);
      }

      debugPrint('QR Notification: Target audience size: ${userIds.length}');
      return userIds;
    } catch (e) {
      debugPrint('QR Notification: Failed to get target audience: $e');
      rethrow;
    }
  }

  // Get audience count for preview
  Future<int> getAudienceCount({
    required String sellerId,
    required NotificationAudience audience,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final userIds = await getTargetAudience(
        sellerId: sellerId,
        audience: audience,
        filters: filters,
      );
      return userIds.length;
    } catch (e) {
      debugPrint('QR Notification: Failed to get audience count: $e');
      return 0;
    }
  }

  // Send notification campaign
  Future<void> sendCampaign(String campaignId) async {
    try {
      // Get campaign
      final campaignDoc = await _firestore
          .collection(FirebaseConstants.qrNotificationCampaignsCollection)
          .doc(campaignId)
          .get();

      if (!campaignDoc.exists) {
        throw Exception('Campaign not found');
      }

      final campaign = QRNotificationCampaign.fromFirestore(campaignDoc);

      // Get target audience first to check quota
      final userIds = await getTargetAudience(
        sellerId: campaign.sellerId,
        audience: campaign.audience,
        filters: campaign.filters,
      );

      if (userIds.isEmpty) {
        await _updateCampaignStatus(campaignId, CampaignStatus.failed, errorMessage: 'No target audience found');
        return;
      }

      // Check quota availability
      final hasQuota = await _quotaService.hasQuotaAvailable(campaign.sellerId, userIds.length);
      if (!hasQuota) {
        await _updateCampaignStatus(campaignId, CampaignStatus.failed, errorMessage: 'Insufficient quota available');
        throw Exception('Insufficient quota available. Please purchase more quota or wait for monthly reset.');
      }

      // Update status to sending
      await _updateCampaignStatus(campaignId, CampaignStatus.sending);

      // Update target count
      await _updateCampaignTargetCount(campaignId, userIds.length);

      // Send notifications in batches
      await _sendNotificationsToUsers(
        campaignId: campaignId,
        userIds: userIds,
        title: campaign.title,
        message: campaign.message,
        actionRoute: campaign.actionRoute,
        actionText: campaign.actionText,
      );

      // Consume quota after successful send
      await _quotaService.consumeQuota(campaign.sellerId, userIds.length);

      // Update status to sent
      await _updateCampaignStatus(campaignId, CampaignStatus.sent, sentAt: DateTime.now());

      debugPrint('QR Notification: Campaign sent successfully: $campaignId');
    } catch (e) {
      debugPrint('QR Notification: Failed to send campaign: $e');
      await _updateCampaignStatus(campaignId, CampaignStatus.failed, errorMessage: e.toString());
      rethrow;
    }
  }

  // Send notifications to users via FCM
  Future<void> _sendNotificationsToUsers({
    required String campaignId,
    required List<String> userIds,
    required String title,
    required String message,
    String? actionRoute,
    String? actionText,
  }) async {
    const batchSize = 500; // FCM multicast limit
    int totalSent = 0;

    for (var i = 0; i < userIds.length; i += batchSize) {
      final batch = userIds.skip(i).take(batchSize).toList();
      
      try {
        // Get FCM tokens for this batch
        final tokens = await _getFCMTokensForUsers(batch);
        
        if (tokens.isNotEmpty) {
          // Send multicast message
          await _sendMulticastMessage(
            tokens: tokens,
            title: title,
            message: message,
            actionRoute: actionRoute,
            actionText: actionText,
          );
          
          totalSent += tokens.length;
          debugPrint('QR Notification: Sent batch ${i ~/ batchSize + 1}: ${tokens.length} notifications');
        }
      } catch (e) {
        debugPrint('QR Notification: Failed to send batch: $e');
        // Continue with next batch
      }
    }

    // Update sent count
    await _updateCampaignSentCount(campaignId, totalSent);
  }

  // Get FCM tokens for users
  Future<List<String>> _getFCMTokensForUsers(List<String> userIds) async {
    final tokens = <String>[];
    
    for (final userId in userIds) {
      try {
        final userDoc = await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final fcmToken = userData['fcmToken'] as String?;
          if (fcmToken != null && fcmToken.isNotEmpty) {
            tokens.add(fcmToken);
          }
        }
      } catch (e) {
        debugPrint('QR Notification: Failed to get token for user $userId: $e');
      }
    }

    return tokens;
  }

  // Send multicast message via FCM
  Future<void> _sendMulticastMessage({
    required List<String> tokens,
    required String title,
    required String message,
    String? actionRoute,
    String? actionText,
  }) async {
    try {
      // This would typically be done via Firebase Admin SDK on the backend
      // For now, we'll simulate the FCM call
      // In a real implementation, you'd call a Cloud Function or use Firebase Admin SDK
      
      debugPrint('QR Notification: Sending multicast to ${tokens.length} tokens');
      debugPrint('Title: $title');
      debugPrint('Message: $message');
      
      // Simulate sending delay
      await Future.delayed(Duration(milliseconds: 500));
      
      // In real implementation, this would be:
      // await FirebaseMessaging.instance.sendMulticast(
      //   MulticastMessage(
      //     tokens: tokens,
      //     notification: Notification(
      //       title: title,
      //       body: message,
      //     ),
      //     data: {
      //       'route': actionRoute ?? '',
      //       'actionText': actionText ?? '',
      //       'type': 'qr_notification',
      //     },
      //   ),
      // );
      
    } catch (e) {
      debugPrint('QR Notification: Failed to send multicast: $e');
      rethrow;
    }
  }

  // Update campaign status
  Future<void> _updateCampaignStatus(
    String campaignId,
    CampaignStatus status, {
    DateTime? sentAt,
    String? errorMessage,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (sentAt != null) {
        updateData['sentAt'] = Timestamp.fromDate(sentAt);
      }

      if (errorMessage != null) {
        updateData['errorMessage'] = errorMessage;
      }

      if (status == CampaignStatus.sent) {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection(FirebaseConstants.qrNotificationCampaignsCollection)
          .doc(campaignId)
          .update(updateData);
    } catch (e) {
      debugPrint('QR Notification: Failed to update campaign status: $e');
    }
  }

  // Update campaign target count
  Future<void> _updateCampaignTargetCount(String campaignId, int targetCount) async {
    try {
      await _firestore
          .collection(FirebaseConstants.qrNotificationCampaignsCollection)
          .doc(campaignId)
          .update({
        'targetCount': targetCount,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('QR Notification: Failed to update target count: $e');
    }
  }

  // Update campaign sent count
  Future<void> _updateCampaignSentCount(String campaignId, int sentCount) async {
    try {
      await _firestore
          .collection(FirebaseConstants.qrNotificationCampaignsCollection)
          .doc(campaignId)
          .update({
        'sentCount': sentCount,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('QR Notification: Failed to update sent count: $e');
    }
  }

  // Get campaigns for a seller
  Stream<List<QRNotificationCampaign>> getCampaigns(String sellerId) {
    return _firestore
        .collection(FirebaseConstants.qrNotificationCampaignsCollection)
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QRNotificationCampaign.fromFirestore(doc))
            .toList());
  }

  // Get specific campaign
  Future<QRNotificationCampaign?> getCampaign(String campaignId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.qrNotificationCampaignsCollection)
          .doc(campaignId)
          .get();

      if (!doc.exists) return null;
      return QRNotificationCampaign.fromFirestore(doc);
    } catch (e) {
      debugPrint('QR Notification: Failed to get campaign: $e');
      return null;
    }
  }

  // Cancel scheduled campaign
  Future<void> cancelCampaign(String campaignId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.qrNotificationCampaignsCollection)
          .doc(campaignId)
          .update({
        'status': CampaignStatus.cancelled.name,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      debugPrint('QR Notification: Campaign cancelled: $campaignId');
    } catch (e) {
      debugPrint('QR Notification: Failed to cancel campaign: $e');
      rethrow;
    }
  }

  // Get campaign analytics
  Future<Map<String, dynamic>> getCampaignAnalytics(String campaignId) async {
    try {
      final campaign = await getCampaign(campaignId);
      if (campaign == null) return {};

      return {
        'campaignId': campaign.id,
        'title': campaign.title,
        'status': campaign.statusDisplayName,
        'targetCount': campaign.targetCount,
        'sentCount': campaign.sentCount,
        'deliveredCount': campaign.deliveredCount,
        'openedCount': campaign.openedCount,
        'deliveryRate': campaign.deliveryRate,
        'openRate': campaign.openRate,
        'createdAt': campaign.createdAt,
        'sentAt': campaign.sentAt,
        'completedAt': campaign.completedAt,
      };
    } catch (e) {
      debugPrint('QR Notification: Failed to get campaign analytics: $e');
      return {};
    }
  }

  // Schedule campaign for later
  Future<void> scheduleCampaign(String campaignId, DateTime scheduledFor) async {
    try {
      await _firestore
          .collection(FirebaseConstants.qrNotificationCampaignsCollection)
          .doc(campaignId)
          .update({
        'scheduledFor': Timestamp.fromDate(scheduledFor),
        'status': CampaignStatus.scheduled.name,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      debugPrint('QR Notification: Campaign scheduled: $campaignId for $scheduledFor');
    } catch (e) {
      debugPrint('QR Notification: Failed to schedule campaign: $e');
      rethrow;
    }
  }

  // Get seller's quota information
  Future<QuotaInfo> getSellerQuota(String sellerId) async {
    return await _quotaService.getSellerQuota(sellerId);
  }

  // Check if seller has quota available
  Future<bool> hasQuotaAvailable(String sellerId, int count) async {
    return await _quotaService.hasQuotaAvailable(sellerId, count);
  }

  // Get quota usage percentage
  Future<double> getQuotaUsagePercentage(String sellerId) async {
    return await _quotaService.getQuotaUsagePercentage(sellerId);
  }

  // Check if quota is near limit
  Future<bool> isQuotaNearLimit(String sellerId) async {
    return await _quotaService.isQuotaNearLimit(sellerId);
  }

  // Purchase additional quota
  Future<void> purchaseQuota(String sellerId, int count, double amount) async {
    await _quotaService.purchaseQuota(sellerId, count, amount);
  }

  // Get quota transaction history
  Future<List<QuotaTransaction>> getQuotaHistory(String sellerId) async {
    return await _quotaService.getQuotaHistory(sellerId);
  }
}
