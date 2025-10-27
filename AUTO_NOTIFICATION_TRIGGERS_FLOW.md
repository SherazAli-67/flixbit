# Flixbit QR System - Auto-Notification Triggers Complete Flow Documentation

## Table of Contents
1. [Completion Status](#completion-status)
2. [Trigger 1: Welcome Notification](#trigger-1-welcome-notification)
3. [Trigger 2: Thank You Notification](#trigger-2-thank-you-notification)
4. [Trigger 3: Offer Reminder](#trigger-3-offer-reminder)
5. [Trigger 4: Re-engagement](#trigger-4-re-engagement)
6. [Technical Specifications](#technical-specifications)
7. [App-Side Handling](#app-side-handling)
8. [Summary](#summary)

---

## ✅ COMPLETION STATUS

**All 4 Auto-Notification Triggers are COMPLETED and DEPLOYED**

| Trigger | Status | Function Name | Trigger Type | Collection |
|---------|--------|---------------|--------------|------------|
| Welcome | ✅ Deployed | `onQRScanWelcome` | Firestore onCreate | `qr_scans` |
| Thank You | ✅ Deployed | `onOfferRedemptionThankYou` | Firestore onCreate | `offer_redemptions` |
| Offer Reminder | ✅ Deployed | `sendOfferReminders` | Scheduled (Daily 10:00 AM) | `offers` |
| Re-engagement | ✅ Deployed | `sendReEngagementNotifications` | Scheduled (Weekly Monday 9:00 AM) | `seller_followers` |

---

## 🔔 TRIGGER 1: WELCOME NOTIFICATION

### **Function**: `onQRScanWelcome`
### **Trigger**: Firestore onCreate for `qr_scans` collection
### **Purpose**: Welcome new users after their first QR scan

#### **Working Flow:**
```
┌─────────────────────────────────────────────────────────────┐
│ USER SCANS SELLER QR CODE                                    │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ App creates document in 'qr_scans' collection               │
│ Data: { userId, sellerId, scannedAt, qrCode }              │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ CLOUD FUNCTION TRIGGERED: onQRScanWelcome                   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 1. Check if First Scan                                       │
│    - Query 'qr_scans' for userId + sellerId                │
│    - If count > 1, exit (not first scan)                   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Retrieve Seller Settings                                  │
│    - Get seller's auto-notification preferences             │
│    - Check if welcome notification is enabled               │
│    - Get custom message template (if any)                   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Check Rate Limits                                         │
│    - Max 1 notification per user per day per seller         │
│    - Query recent notifications to prevent spam             │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Get User's FCM Token                                      │
│    - Retrieve from 'users/{userId}' document                │
│    - Field: fcmToken                                         │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Send FCM Notification                                     │
│    Title: "Welcome to [Seller Name]!"                       │
│    Body: "Thanks for scanning! Follow us for exclusive..."  │
│    Data: { type: 'welcome', sellerId, route: '/seller...' }│
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. Log Notification                                          │
│    - Create document in 'notification_analytics'            │
│    - Track: sent, delivered status                          │
└─────────────────────────────────────────────────────────────┘
```

#### **Default Message:**
> "Welcome to [Seller Name]! Thanks for scanning our QR code. Follow us for exclusive offers and updates."

#### **Rate Limiting:**
- **Limit**: 1 notification per user per seller (first scan only)
- **Prevention**: Query `auto_notification_log` for recent notifications

---

## 🎉 TRIGGER 2: THANK YOU NOTIFICATION

### **Function**: `onOfferRedemptionThankYou`
### **Trigger**: Firestore onCreate for `offer_redemptions` collection
### **Purpose**: Thank users after successful offer redemption

#### **Working Flow:**
```
┌─────────────────────────────────────────────────────────────┐
│ USER REDEEMS OFFER (Scans Offer QR or Digital Redemption)  │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ App creates document in 'offer_redemptions' collection     │
│ Data: { userId, offerId, sellerId, redeemedAt, status }   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ CLOUD FUNCTION TRIGGERED: onOfferRedemptionThankYou        │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 1. Validate Redemption Status                                │
│    - Check if status is 'redeemed' or undefined             │
│    - Skip if status is 'failed' or 'cancelled'              │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Retrieve Seller Settings                                  │
│    - Check if thank you notification is enabled             │
│    - Get custom message template                            │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Check Rate Limits                                         │
│    - Prevent multiple thank you messages                     │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Get User's FCM Token                                      │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Send FCM Notification                                     │
│    Title: "Thank You for Redeeming!"                        │
│    Body: "Enjoy your [Offer Name]. Visit us again soon!"    │
│    Data: { type: 'thank_you', offerId, sellerId }          │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. Log Notification                                          │
└─────────────────────────────────────────────────────────────┘
```

#### **Default Message:**
> "Thank you for redeeming [Offer Name]! We hope you enjoy it. Visit us again soon for more exclusive offers."

#### **Status Validation:**
- ✅ **Sends notification**: `status = 'redeemed'` or `status = undefined`
- ❌ **Skips notification**: `status = 'failed'`, `status = 'cancelled'`, etc.

---

## ⏰ TRIGGER 3: OFFER REMINDER

### **Function**: `sendOfferReminders`
### **Trigger**: Cloud Scheduler (Daily at 10:00 AM)
### **Purpose**: Remind users about offers expiring in 24 hours

#### **Working Flow:**
```
┌─────────────────────────────────────────────────────────────┐
│ CLOUD SCHEDULER RUNS DAILY AT 10:00 AM                      │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ CLOUD FUNCTION TRIGGERED: sendOfferReminders               │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 1. Identify Expiring Offers                                  │
│    - Query 'offers' collection                               │
│    - Filter: validUntil between now and now+24h             │
│    - Filter: status = 'active'                              │
│    - Filter: reminderSent = false                           │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. For Each Expiring Offer                                   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Get Seller's Followers                                    │
│    - Query 'seller_followers' where sellerId matches        │
│    - Filter: notificationsEnabled = true                    │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Filter Unredeemed Users                                   │
│    - Check 'offer_redemptions' collection                   │
│    - Exclude users who already redeemed this offer          │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Check Seller Settings & Rate Limits                      │
│    - Verify reminder notifications enabled                   │
│    - Check daily notification quota                          │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. Send Batch FCM Notifications                             │
│    Title: "Offer Expiring Soon!"                            │
│    Body: "[Offer Name] expires in 24 hours. Redeem now!"    │
│    Data: { type: 'offer_reminder', offerId, sellerId }     │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. Mark Offer as Reminded                                    │
│    - Update offer: reminderSent = true                      │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 8. Log Notifications                                         │
│    - Track sent count, delivery status                       │
└─────────────────────────────────────────────────────────────┘
```

#### **Default Message:**
> "[Offer Name] expires in 24 hours! Don't miss out on [discount/benefit]. Redeem now before it's gone!"

#### **Schedule:**
- **Frequency**: Daily at 10:00 AM
- **Cron Expression**: `0 10 * * *`
- **Timezone**: UTC

---

## 🔄 TRIGGER 4: RE-ENGAGEMENT

### **Function**: `sendReEngagementNotifications`
### **Trigger**: Cloud Scheduler (Weekly on Monday at 9:00 AM)
### **Purpose**: Re-engage inactive followers (no activity for 30 days)

#### **Working Flow:**
```
┌─────────────────────────────────────────────────────────────┐
│ CLOUD SCHEDULER RUNS WEEKLY (MONDAY 9:00 AM)               │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ CLOUD FUNCTION TRIGGERED: sendReEngagementNotifications    │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 1. Identify Inactive Followers                               │
│    - Query 'seller_followers' collection                     │
│    - Filter: followedAt < 30 days ago                       │
│    - Filter: notificationsEnabled = true                    │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Check User Activity                                       │
│    - Query 'qr_scans' for recent scans (last 30 days)      │
│    - Query 'offer_redemptions' for recent redemptions       │
│    - Exclude users with recent activity                      │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. For Each Inactive User                                    │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Retrieve Seller Settings                                  │
│    - Check if re-engagement notification enabled            │
│    - Get custom message template                            │
│    - Check notification quota                               │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Check Rate Limits                                         │
│    - Max 1 re-engagement per user per seller per month      │
│    - Query notification history                              │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. Get User's FCM Token                                      │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. Send FCM Notification                                     │
│    Title: "We Miss You!"                                     │
│    Body: "Check out our latest offers at [Seller Name]"     │
│    Data: { type: 're_engagement', sellerId }               │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 8. Log Notification                                          │
│    - Track sent count, delivery status                       │
└─────────────────────────────────────────────────────────────┘
```

#### **Default Message:**
> "We miss you! It's been a while since your last visit to [Seller Name]. Check out our latest offers and exclusive deals!"

#### **Schedule:**
- **Frequency**: Weekly on Monday at 9:00 AM
- **Cron Expression**: `0 9 * * 1`
- **Timezone**: UTC

---

## 🔧 TECHNICAL SPECIFICATIONS

### **Firebase Collections Used:**

#### **Primary Collections:**
1. **`qr_scans`** - Triggers welcome notification
2. **`offer_redemptions`** - Triggers thank you notification
3. **`offers`** - Checked by offer reminder scheduler
4. **`seller_followers`** - Used by all functions for targeting
5. **`users`** - Stores FCM tokens
6. **`notification_analytics`** - Logs all sent notifications
7. **`auto_notification_settings`** - Seller preferences

#### **Collection Structures:**

**`qr_scans` Collection:**
```json
{
  "id": "scan_id",
  "userId": "user_id",
  "sellerId": "seller_id",
  "qrCode": "flixbit:seller:seller_id",
  "scannedAt": "timestamp",
  "pointsAwarded": 10,
  "location": "GeoPoint (optional)"
}
```

**`offer_redemptions` Collection:**
```json
{
  "id": "redemption_id",
  "userId": "user_id",
  "offerId": "offer_id",
  "sellerId": "seller_id",
  "redeemedAt": "timestamp",
  "pointsEarned": 15,
  "qrCodeData": "flixbit:offer:...",
  "status": "redeemed"
}
```

**`auto_notification_settings` Collection:**
```json
{
  "sellerId": "seller_id",
  "welcomeEnabled": true,
  "welcomeMessage": "Custom welcome message",
  "thankYouEnabled": true,
  "thankYouMessage": "Custom thank you message",
  "offerReminderEnabled": true,
  "reEngagementEnabled": true,
  "maxNotificationsPerDay": 1
}
```

### **Rate Limiting Rules:**

| Trigger | Rate Limit | Scope | Prevention Method |
|---------|------------|-------|-------------------|
| Welcome | 1 per user per seller | First scan only | Query `qr_scans` count |
| Thank You | 1 per offer redemption | Per redemption | Query `auto_notification_log` |
| Offer Reminder | 1 per offer per user | Per offer | Check `reminderSent` flag |
| Re-engagement | 1 per user per seller per month | Monthly limit | Query notification history |

### **Notification Quota:**
- All auto-notifications consume from seller's notification quota
- Managed by `NotificationQuotaService`
- Free quota: 100 notifications/month per seller
- Purchased quota never expires
- Deduct from purchased first, then free

### **FCM Message Structure:**
```json
{
  "token": "user_fcm_token",
  "notification": {
    "title": "Notification Title",
    "body": "Notification Message"
  },
  "data": {
    "type": "welcome|thank_you|offer_reminder|re_engagement",
    "sellerId": "seller_id",
    "offerId": "offer_id (if applicable)",
    "route": "/target_route",
    "actionText": "Action Button Text"
  },
  "android": {
    "notification": {
      "icon": "ic_notification",
      "color": "#17a3eb",
      "sound": "default"
    }
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "default",
        "badge": 1
      }
    }
  }
}
```

---

## 📱 APP-SIDE HANDLING

### **FCM Service Integration:**

**File**: `lib/src/service/fcm_service.dart`

#### **Foreground Message Handler:**
```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // Display local notification
  // Handle notification type from data payload
  // Navigate to appropriate route if needed
});
```

#### **Background/Terminated Message Handler:**
```dart
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  // Handle notification tap
  // Navigate based on data.type and data.route
});
```

### **Notification Types Handled:**

| Type | Action | Route | Description |
|------|--------|-------|-------------|
| `welcome` | Navigate to seller profile | `/seller_profile_view` | Show seller details after QR scan |
| `thank_you` | Navigate to rewards | `/my_rewards_view` | Show redeemed offer details |
| `offer_reminder` | Navigate to offer details | `/offer_detail_view` | Show expiring offer |
| `re_engagement` | Navigate to seller profile | `/seller_profile_view` | Re-engage with seller |

### **Deep Linking Support:**
- All notifications include `route` and `actionText` in data payload
- App handles navigation based on notification type
- Supports both foreground and background navigation

---

## 📊 SUMMARY

### **Quick Reference Table:**

| Feature | Status | Function | Trigger | Rate Limit | Schedule |
|---------|--------|----------|---------|------------|----------|
| Welcome Notification | ✅ Active | `onQRScanWelcome` | Firestore onCreate | 1 per user per seller | Real-time |
| Thank You Notification | ✅ Active | `onOfferRedemptionThankYou` | Firestore onCreate | 1 per redemption | Real-time |
| Offer Reminder | ✅ Active | `sendOfferReminders` | Cloud Scheduler | 1 per offer per user | Daily 10:00 AM |
| Re-engagement | ✅ Active | `sendReEngagementNotifications` | Cloud Scheduler | 1 per month per user | Weekly Monday 9:00 AM |

### **Key Benefits:**
- ✅ **Automated Engagement**: No manual intervention required
- ✅ **Personalized Messages**: Customizable per seller
- ✅ **Rate Limited**: Prevents spam and respects user preferences
- ✅ **Quota Managed**: Fair usage across all sellers
- ✅ **Analytics Tracked**: Complete notification performance metrics
- ✅ **Real-time Triggers**: Immediate response to user actions
- ✅ **Scheduled Jobs**: Proactive engagement for retention

### **Monitoring & Analytics:**
- All notifications logged in `notification_analytics` collection
- Delivery status tracking via FCM responses
- Error logging in `function_errors` collection
- Performance metrics available in seller dashboard

### **Future Enhancements:**
- A/B testing for notification messages
- Rich media notifications (images, videos)
- Advanced segmentation (demographics, behavior)
- Notification automation workflows
- Integration with email/SMS

---

**Document Version**: 1.0  
**Last Updated**: Auto-Notification System Complete  
**Status**: All 4 Triggers Deployed and Active  
**Next Phase**: Phase 3C - Auto-Notification Service Integration (App-side)



