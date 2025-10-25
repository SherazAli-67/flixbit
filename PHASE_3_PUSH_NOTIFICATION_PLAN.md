# Phase 3: Push Notification System Integration - Implementation Plan

## Overview

Implement comprehensive push notification system integrated with the QR system, enabling sellers to send targeted notifications to their followers based on QR scan sources, with analytics tracking, scheduling, and quota management.

## Current State Analysis

### Existing Infrastructure

**FCM Service** (`lib/src/service/fcm_service.dart`):
- FCM token management
- Local notifications
- Background/foreground message handling
- Topic subscription/unsubscription
- Notification channels for Android
- Deep linking support

**Seller Follower Service** (`lib/src/service/seller_follower_service.dart`):
- Follow/unfollow functionality
- Follower tracking by source (qr_scan, offer_redemption, manual)
- Notification preference management
- Follower analytics by source

**Seller Push Notification Page** (`lib/src/features/seller/seller_push_notification_page.dart`):
- Basic UI skeleton exists
- Title and message input fields
- Audience selection (Followers, Groups, Custom)
- Schedule selection (Now, Specific date/time)
- No backend integration

### What's Missing

- QR-based notification targeting service
- Audience filtering by QR scan source
- Notification campaign creation and management
- Notification quota system
- Notification analytics and tracking
- Auto-notification triggers
- Backend integration for sending notifications

## Implementation Tasks

### Task 10: QR-Based Notification Targeting

#### Subtask 10.1: Create Notification Campaign Model

**New File**: `lib/src/models/qr_notification_campaign_model.dart`

```dart
class QRNotificationCampaign {
  final String id;
  final String sellerId;
  final String title;
  final String message;
  final NotificationAudience audience;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final CampaignStatus status;
  final int targetCount;
  final int sentCount;
  final int deliveredCount;
  final int openedCount;
  final Map<String, dynamic>? filters;
  final String? actionRoute;
  final String? actionText;
  
  // Methods: fromJson, toJson, copyWith
}

enum NotificationAudience {
  allFollowers,
  qrScanFollowers,
  offerFollowers,
  manualFollowers,
  dateRangeFollowers,
  custom
}

enum CampaignStatus {
  draft,
  scheduled,
  sending,
  sent,
  failed,
  cancelled
}
```

#### Subtask 10.2: Create QR Notification Service

**New File**: `lib/src/service/qr_notification_service.dart`

Key Methods:
- `createCampaign()`: Create notification campaign
- `sendNotification()`: Send notifications to targeted followers
- `scheduleNotification()`: Schedule notification for later
- `getTargetAudience()`: Get list of users based on filters
- `getAudienceCount()`: Preview audience size before sending
- `getCampaignAnalytics()`: Get campaign performance metrics
- `cancelCampaign()`: Cancel scheduled campaign
- `getCampaigns()`: Stream of seller's campaigns
- `getCampaignById()`: Get specific campaign details

Integration with FCM:
- Use FCM tokens from user documents
- Send via Firebase Cloud Messaging
- Track delivery status
- Handle failed deliveries
- Batch send for large audiences

#### Subtask 10.3: Update Seller Push Notification Page

**File**: `lib/src/features/seller/seller_push_notification_page.dart`

Modifications:
- Integrate with `QRNotificationService`
- Add QR-specific audience options:
  - All Followers
  - QR Scan Followers Only
  - Offer Redemption Followers
  - Recent Followers (last 7/30 days)
- Show audience count preview
- Add notification quota display
- Implement send functionality
- Add validation (title, message not empty)
- Show success/error feedback
- Add confirmation dialog before sending
- Show loading state during send
- Update to use `context.pop()` and `withValues(alpha:)`

### Task 11: Auto-Notification Triggers

#### Subtask 11.1: Create Auto-Notification Service

**New File**: `lib/src/service/qr_auto_notification_service.dart`

Auto-triggers to implement:
1. **Welcome notification after QR scan**: "Thanks for scanning! Follow us for exclusive offers."
2. **Offer reminder (24h before expiry)**: "Your offer expires tomorrow! Redeem now."
3. **Re-engagement for inactive followers (30 days)**: "We miss you! Check out our latest offers."
4. **Thank you after offer redemption**: "Thanks for redeeming! Enjoy your reward."

Each trigger:
- Configurable on/off per seller
- Customizable message templates
- Respects user notification preferences
- Tracks in analytics
- Rate limited (max 1 per user per day per seller)

Methods:
- `sendWelcomeNotification(userId, sellerId)`
- `sendOfferReminderNotification(userId, offerId)`
- `sendReEngagementNotification(userId, sellerId)`
- `sendThankYouNotification(userId, offerId)`
- `getAutoNotificationSettings(sellerId)`
- `updateAutoNotificationSettings(sellerId, settings)`

#### Subtask 11.2: Integrate Auto-Triggers

Modify existing services to call auto-notifications:

**File**: `lib/src/service/qr_scan_service.dart`
- In `recordScan()`: Call `sendWelcomeNotification()` after successful scan

**File**: `lib/src/service/offer_service.dart` (if exists, or relevant offer service)
- After offer redemption: Call `sendThankYouNotification()`

**Background Job** (optional for Phase 3):
- Check for expiring offers and inactive followers
- Can be implemented later with Cloud Functions

### Task 12: Notification Analytics & Quota Management

#### Subtask 12.1: Create Notification Quota Service

**New File**: `lib/src/service/notification_quota_service.dart`

```dart
class NotificationQuotaService {
  Future<QuotaInfo> getSellerQuota(String sellerId);
  Future<bool> hasQuotaAvailable(String sellerId, int count);
  Future<void> consumeQuota(String sellerId, int count);
  Future<void> purchaseQuota(String sellerId, int count, double amount);
  Future<List<QuotaTransaction>> getQuotaHistory(String sellerId);
  Future<void> resetMonthlyQuota(String sellerId);
}

class QuotaInfo {
  final int freeQuota;
  final int usedQuota;
  final int remainingQuota;
  final int purchasedQuota;
  final DateTime resetDate;
  final double usagePercentage;
}

class QuotaTransaction {
  final String id;
  final String sellerId;
  final int amount;
  final String type; // 'used', 'purchased', 'reset'
  final DateTime timestamp;
  final String? campaignId;
}
```

Admin Configuration:
- Set free notification limit per seller (default: 100/month)
- Pricing for additional notifications
- Quota reset schedule (1st of each month)

Quota Logic:
- Free quota: 100 notifications/month per seller
- Resets on 1st of each month
- Purchased quota never expires
- Deduct from purchased first, then free
- Block sending if quota exhausted
- Show warning at 80% usage

#### Subtask 12.2: Create Notification Analytics Page

**New File**: `lib/src/features/seller/notification_analytics_page.dart`

Display:
- **Summary Cards**:
  - Total campaigns sent
  - Total notifications sent
  - Average delivery rate
  - Average open rate
- **Campaign List** with status
- **Delivery rates** (sent vs delivered)
- **Open rates** (delivered vs opened)
- **Click-through rates** (opened vs clicked)
- **ROI metrics** (redemptions from notifications)
- **Time-based charts** (daily/weekly trends)
- **Audience breakdown** (by source)

Use `fl_chart` for visualizations
Follow coding standards (spacing, withValues, context.pop)

### Task 13: Notification Campaign Management

#### Subtask 13.1: Create Campaign List Page

**New File**: `lib/src/features/seller/notification_campaign_list_page.dart`

Features:
- List all campaigns (sent, scheduled, draft)
- Filter by status (dropdown or tabs)
- View campaign details (tap to navigate)
- Edit draft campaigns
- Cancel scheduled campaigns
- Duplicate campaigns (optional)
- Pull-to-refresh
- Empty state when no campaigns

UI Components:
- Campaign card showing:
  - Title
  - Status badge
  - Target audience
  - Sent/Delivered/Opened counts
  - Created/Scheduled date
  - Action buttons (view, edit, cancel)

#### Subtask 13.2: Create Campaign Detail Page

**New File**: `lib/src/features/seller/notification_campaign_detail_page.dart`

Display:
- **Campaign Header**:
  - Title
  - Status badge
  - Created/Scheduled date
- **Message Content**:
  - Full message text
  - Action route/text
- **Target Audience Details**:
  - Audience type
  - Filters applied
  - Target count
- **Statistics**:
  - Sent count
  - Delivered count
  - Opened count
  - Delivery rate
  - Open rate
- **Timeline of Events**:
  - Created
  - Scheduled
  - Sent
  - Delivered
  - Opened

Actions:
- Cancel (if scheduled)
- Duplicate
- Delete (if draft)

## Firebase Structure

### Collections

#### `qr_notification_campaigns`
```json
{
  "id": "campaign_id",
  "sellerId": "seller_id",
  "title": "Weekend Sale",
  "message": "50% off this weekend!",
  "audience": "qr_scan_followers",
  "filters": {
    "followSource": "qr_scan",
    "dateRange": {
      "start": "2025-10-01",
      "end": "2025-10-25"
    }
  },
  "createdAt": "timestamp",
  "scheduledFor": "timestamp",
  "status": "sent",
  "targetCount": 150,
  "sentCount": 148,
  "deliveredCount": 145,
  "openedCount": 87,
  "actionRoute": "/offers_view",
  "actionText": "View Offers"
}
```

#### `notification_quota`
```json
{
  "sellerId": "seller_id",
  "freeQuota": 100,
  "usedQuota": 45,
  "purchasedQuota": 50,
  "totalQuota": 150,
  "remainingQuota": 105,
  "resetDate": "timestamp",
  "lastUpdated": "timestamp"
}
```

#### `notification_quota_transactions`
```json
{
  "id": "transaction_id",
  "sellerId": "seller_id",
  "amount": 50,
  "type": "used",
  "timestamp": "timestamp",
  "campaignId": "campaign_id",
  "description": "Campaign: Weekend Sale"
}
```

#### `notification_analytics`
```json
{
  "campaignId": "campaign_id",
  "sellerId": "seller_id",
  "sent": 148,
  "delivered": 145,
  "opened": 87,
  "clicked": 34,
  "converted": 12,
  "deliveryRate": 97.9,
  "openRate": 60.0,
  "clickRate": 23.4,
  "conversionRate": 8.3,
  "revenueGenerated": 450.00,
  "lastUpdated": "timestamp"
}
```

## Technical Specifications

### Notification Sending Flow

1. Seller creates campaign in UI
2. Service validates quota availability
3. Service fetches target audience from `seller_followers`
4. Service creates campaign document
5. Service sends notifications via FCM (batch processing)
6. FCM delivers to user devices
7. Service tracks delivery status
8. User opens notification → tracked in analytics
9. User takes action → tracked in analytics
10. Analytics updated in real-time

### Audience Targeting Logic

```dart
// Example: Get QR scan followers from last 30 days
Future<List<String>> getTargetUserIds({
  required String sellerId,
  String? followSource,
  DateTime? startDate,
  DateTime? endDate,
  bool? notificationsEnabled,
}) async {
  var query = _firestore
      .collection('seller_followers')
      .where('sellerId', isEqualTo: sellerId);
  
  if (followSource != null) {
    query = query.where('followSource', isEqualTo: followSource);
  }
  
  if (notificationsEnabled != null) {
    query = query.where('notificationsEnabled', isEqualTo: true);
  }
  
  final snapshot = await query.get();
  final userIds = <String>[];
  
  for (final doc in snapshot.docs) {
    final follower = SellerFollower.fromJson(doc.data());
    
    // Apply date filters
    if (startDate != null && follower.followedAt.isBefore(startDate)) {
      continue;
    }
    if (endDate != null && follower.followedAt.isAfter(endDate)) {
      continue;
    }
    
    userIds.add(follower.userId);
  }
  
  return userIds;
}
```

### Batch Notification Sending

```dart
Future<void> sendNotificationsToUsers(
  List<String> userIds,
  String title,
  String message,
  Map<String, dynamic> data,
) async {
  const batchSize = 500; // FCM limit
  
  for (var i = 0; i < userIds.length; i += batchSize) {
    final batch = userIds.skip(i).take(batchSize).toList();
    
    // Get FCM tokens for batch
    final tokens = await _getTokensForUsers(batch);
    
    // Send multicast message
    await _sendMulticastMessage(tokens, title, message, data);
    
    // Track sent count
    await _updateCampaignSentCount(campaignId, batch.length);
  }
}
```

### Notification Quota Logic

- Free quota: 100 notifications/month per seller (admin configurable)
- Resets on 1st of each month
- Purchased quota never expires
- Deduct from purchased first, then free
- Block sending if quota exhausted
- Show warning at 80% usage

## UI/UX Standards

- Use `spacing` parameter for Column/Row
- Use `withValues(alpha:)` for opacity
- Single-line setState and callbacks
- Use `context.pop()` for navigation
- Follow existing color scheme (AppColors)
- Show loading states during sends
- Confirm before sending
- Show success/error messages with SnackBar

## Files to Create (11 new files)

### Models (1 file)
1. `lib/src/models/qr_notification_campaign_model.dart`

### Services (3 files)
2. `lib/src/service/qr_notification_service.dart`
3. `lib/src/service/qr_auto_notification_service.dart`
4. `lib/src/service/notification_quota_service.dart`

### Features/Pages (5 files)
5. `lib/src/features/seller/notification_analytics_page.dart`
6. `lib/src/features/seller/notification_campaign_list_page.dart`
7. `lib/src/features/seller/notification_campaign_detail_page.dart`
8. `lib/src/features/seller/notification_audience_selector_page.dart`
9. `lib/src/features/seller/notification_schedule_picker_page.dart`

### Widgets (2 files)
10. `lib/src/widgets/notification_preview_widget.dart`
11. `lib/src/widgets/audience_count_widget.dart`

## Files to Modify (5 files)

1. `lib/src/features/seller/seller_push_notification_page.dart` - Complete backend integration
2. `lib/src/service/qr_scan_service.dart` - Add welcome notification trigger
3. `lib/src/service/offer_service.dart` - Add thank you notification trigger (if exists)
4. `lib/src/routes/router_enum.dart` - Add notification routes
5. `lib/src/routes/app_router.dart` - Configure notification routes

## Routes to Add

```dart
// In router_enum.dart
notificationAnalyticsView('/notification_analytics_view'),
notificationCampaignListView('/notification_campaign_list_view'),
notificationCampaignDetailView('/notification_campaign_detail_view'),
notificationAudienceSelectorView('/notification_audience_selector_view'),

// In app_router.dart
GoRoute(
  path: RouterEnum.notificationAnalyticsView.route,
  name: RouterEnum.notificationAnalyticsView.name,
  builder: (context, state) => const NotificationAnalyticsPage(),
),
GoRoute(
  path: RouterEnum.notificationCampaignListView.route,
  name: RouterEnum.notificationCampaignListView.name,
  builder: (context, state) => const NotificationCampaignListPage(),
),
GoRoute(
  path: RouterEnum.notificationCampaignDetailView.route,
  name: RouterEnum.notificationCampaignDetailView.name,
  builder: (context, state) {
    final campaignId = state.extra as String;
    return NotificationCampaignDetailPage(campaignId: campaignId);
  },
),
```

## Navigation Integration

Add navigation to notification features from:

1. **Seller Dashboard** (`seller_dashboard_page.dart`):
   - Add "Notifications" quick action card
   - Button: "Send Notification" → `SellerPushNotificationPage`
   - Button: "View Analytics" → `NotificationAnalyticsPage`
   - Button: "Manage Campaigns" → `NotificationCampaignListPage`

2. **Seller Menu/Settings**:
   - Add "Notification Center" menu item

## Admin Configuration Needed

Create admin settings for:
- Free notification quota per seller (default: 100/month)
- Notification pricing tiers
- Auto-notification defaults (on/off)
- Notification rate limits (max per day)
- Spam prevention rules

## Success Criteria

- ✅ Sellers can send notifications to QR scan followers
- ✅ Audience filtering by source works correctly
- ✅ Notification quota system enforces limits
- ✅ Analytics track delivery and open rates
- ✅ Auto-notifications trigger on QR scan
- ✅ Scheduled notifications send at correct time
- ✅ Users can opt-out of notifications
- ✅ All UI follows coding standards
- ✅ No performance issues with large audiences

## Implementation Priority

### Phase 3A: Core Notification System (High Priority)
1. Task 10.1: Notification campaign model
2. Task 10.2: QR notification service
3. Task 10.3: Update push notification page
4. Task 12.1: Quota service

**Estimated: 12-16 hours**

### Phase 3B: Analytics & Management (Medium Priority)
5. Task 12.2: Notification analytics page
6. Task 13.1: Campaign list page
7. Task 13.2: Campaign detail page

**Estimated: 8-10 hours**

### Phase 3C: Auto-Notifications (Low Priority)
8. Task 11.1: Auto-notification service
9. Task 11.2: Integrate auto-triggers

**Estimated: 4-6 hours**

**Total Estimated Time: 24-32 hours**

## Dependencies

### Required Packages (Already in project)
- `firebase_messaging`
- `flutter_local_notifications`
- `cloud_firestore`
- `firebase_auth`
- `fl_chart` (for analytics)

### Required Services
- FCMService (existing)
- SellerFollowerService (existing)

### Required Models
- SellerFollower (existing)
- AppNotification (existing)

## Security Considerations

- ✅ Validate seller owns campaign before sending
- ✅ Rate limit notification sends (max 1 per user per day per seller)
- ✅ Respect user notification preferences
- ✅ Prevent spam with quota system
- ✅ Secure FCM tokens (stored in user documents)
- ✅ Admin approval for high-volume sends (>1000 notifications)
- ✅ Validate message content (no offensive language)

## Testing Checklist

- [ ] Send notification to all followers
- [ ] Send to QR scan followers only
- [ ] Send to offer redemption followers
- [ ] Filter by date range (last 7 days, 30 days)
- [ ] Quota enforcement works (block when exhausted)
- [ ] Scheduled notifications send on time
- [ ] Analytics track correctly (sent, delivered, opened)
- [ ] Auto-notifications trigger on QR scan
- [ ] Users can opt-out of notifications
- [ ] Deep linking works (notification → app route)
- [ ] Batch sending works for large audiences (>500 users)
- [ ] Error handling for failed sends
- [ ] UI follows coding standards

## Known Limitations

1. **FCM Limitations**:
   - Max 500 tokens per multicast message
   - Rate limits apply (check Firebase quotas)
   
2. **Tracking Limitations**:
   - Open rate tracking requires user to open notification
   - Click tracking requires user to tap action
   - Some devices may not report delivery status

3. **Scheduling Limitations**:
   - Scheduled notifications require background job or Cloud Functions
   - May implement simple scheduling with local checks initially

## Future Enhancements (Post Phase 3)

- A/B testing for notification messages
- Rich media notifications (images, videos)
- Notification templates library
- Advanced segmentation (demographics, behavior)
- Notification automation workflows
- Integration with email/SMS
- Notification performance predictions

---

**Status**: Ready for Implementation  
**Priority**: High (Core feature for seller engagement)  
**Complexity**: High (FCM integration, quota management, analytics)  
**Phase**: 3 of 8 in Complete QR System Implementation

