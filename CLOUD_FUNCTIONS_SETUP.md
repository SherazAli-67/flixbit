# Firebase Cloud Functions Setup for Flixbit Notifications

This document provides the complete setup and implementation guide for Firebase Cloud Functions to handle notifications in the Flixbit app.

## Prerequisites

1. Firebase project with Firestore and Cloud Functions enabled
2. Node.js 18+ installed
3. Firebase CLI installed (`npm install -g firebase-tools`)
4. Flutter app with FCM integration (already implemented)

## Setup Steps

### 1. Initialize Cloud Functions

```bash
# Navigate to your project root
cd /path/to/flixbit

# Initialize Firebase Functions
firebase init functions

# Select:
# - Use TypeScript: Yes
# - ESLint: Yes
# - Install dependencies: Yes
```

### 2. Install Required Dependencies

```bash
cd functions
npm install firebase-admin firebase-functions
```

### 3. Update functions/src/index.ts

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

// 1. Reward Redemption Notification
export const onRewardRedemption = functions.firestore
  .document('reward_redemptions/{redemptionId}')
  .onCreate(async (snap, context) => {
    const redemption = snap.data();
    const { userId, rewardId, pointsSpent } = redemption;

    try {
      // Get reward details
      const rewardDoc = await admin.firestore()
        .collection('rewards')
        .doc(rewardId)
        .get();
      
      if (!rewardDoc.exists) {
        console.error('Reward not found:', rewardId);
        return;
      }

      const reward = rewardDoc.data();
      
      // Get user's FCM tokens
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(userId)
        .get();
      
      const fcmTokens = userDoc.data()?.fcmTokens || [];
      
      if (fcmTokens.length === 0) {
        console.log('No FCM tokens for user:', userId);
        return;
      }

      // Send FCM notification
      const message = {
        notification: {
          title: '🎉 Reward Redeemed!',
          body: `You've redeemed ${reward.title} for ${pointsSpent} points`
        },
        data: {
          type: 'reward_redemption',
          redemptionId: context.params.redemptionId,
          rewardId: rewardId,
          redemptionCode: redemption.redemptionCode,
          route: '/my-rewards'
        },
        tokens: fcmTokens
      };

      const response = await admin.messaging().sendMulticast(message);
      console.log('Successfully sent message:', response.successCount);

      // Create notification document
      await admin.firestore()
        .collection('notifications')
        .add({
          userId: userId,
          title: '🎉 Reward Redeemed!',
          body: `You've redeemed ${reward.title} for ${pointsSpent} points`,
          type: 'reward_redemption',
          data: {
            redemptionId: context.params.redemptionId,
            rewardId: rewardId,
            redemptionCode: redemption.redemptionCode
          },
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          actionRoute: '/my-rewards'
        });

    } catch (error) {
      console.error('Error sending reward redemption notification:', error);
    }
  });

// 2. Reward Shipped Notification
export const onRewardShipped = functions.firestore
  .document('reward_redemptions/{redemptionId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Check if status changed to 'shipped'
    if (before.status !== 'shipped' && after.status === 'shipped') {
      const { userId, trackingNumber } = after;

      try {
        // Get reward details
        const rewardDoc = await admin.firestore()
          .collection('rewards')
          .doc(after.rewardId)
          .get();
        
        const reward = rewardDoc.data();
        
        // Get user's FCM tokens
        const userDoc = await admin.firestore()
          .collection('users')
          .doc(userId)
          .get();
        
        const fcmTokens = userDoc.data()?.fcmTokens || [];
        
        if (fcmTokens.length === 0) return;

        // Send FCM notification
        const message = {
          notification: {
            title: '📦 Reward Shipped!',
            body: `Your ${reward.title} is on the way! Track: ${trackingNumber}`
          },
          data: {
            type: 'reward_shipped',
            redemptionId: context.params.redemptionId,
            trackingNumber: trackingNumber,
            route: '/my-rewards'
          },
          tokens: fcmTokens
        };

        await admin.messaging().sendMulticast(message);

        // Create notification document
        await admin.firestore()
          .collection('notifications')
          .add({
            userId: userId,
            title: '📦 Reward Shipped!',
            body: `Your ${reward.title} is on the way! Track: ${trackingNumber}`,
            type: 'reward_shipped',
            data: {
              redemptionId: context.params.redemptionId,
              trackingNumber: trackingNumber
            },
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            actionRoute: '/my-rewards'
          });

      } catch (error) {
        console.error('Error sending shipping notification:', error);
      }
    }
  });

// 3. Reward Delivered Notification
export const onRewardDelivered = functions.firestore
  .document('reward_redemptions/{redemptionId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Check if status changed to 'delivered'
    if (before.status !== 'delivered' && after.status === 'delivered') {
      const { userId } = after;

      try {
        // Get reward details
        const rewardDoc = await admin.firestore()
          .collection('rewards')
          .doc(after.rewardId)
          .get();
        
        const reward = rewardDoc.data();
        
        // Get user's FCM tokens
        const userDoc = await admin.firestore()
          .collection('users')
          .doc(userId)
          .get();
        
        const fcmTokens = userDoc.data()?.fcmTokens || [];
        
        if (fcmTokens.length === 0) return;

        // Send FCM notification
        const message = {
          notification: {
            title: '✅ Reward Delivered!',
            body: `Your ${reward.title} has been delivered. Enjoy!`
          },
          data: {
            type: 'reward_delivered',
            redemptionId: context.params.redemptionId,
            route: '/my-rewards'
          },
          tokens: fcmTokens
        };

        await admin.messaging().sendMulticast(message);

        // Create notification document
        await admin.firestore()
          .collection('notifications')
          .add({
            userId: userId,
            title: '✅ Reward Delivered!',
            body: `Your ${reward.title} has been delivered. Enjoy!`,
            type: 'reward_delivered',
            data: {
              redemptionId: context.params.redemptionId
            },
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            actionRoute: '/my-rewards'
          });

      } catch (error) {
        console.error('Error sending delivery notification:', error);
      }
    }
  });

// 4. Check Expiring Rewards (Scheduled Function)
export const checkExpiringRewards = functions.pubsub
  .schedule('0 9 * * *') // Daily at 9 AM UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const threeDaysFromNow = admin.firestore.Timestamp.fromDate(
      new Date(now.toDate().getTime() + (3 * 24 * 60 * 60 * 1000))
    );

    try {
      // Query expiring rewards
      const expiringQuery = await admin.firestore()
        .collection('reward_redemptions')
        .where('status', '==', 'active')
        .where('expiresAt', '>=', now)
        .where('expiresAt', '<=', threeDaysFromNow)
        .where('expiryWarningSent', '==', false)
        .get();

      console.log(`Found ${expiringQuery.docs.length} expiring rewards`);

      for (const doc of expiringQuery.docs) {
        const redemption = doc.data();
        const daysLeft = Math.ceil(
          (redemption.expiresAt.toDate() - now.toDate()) / (1000 * 60 * 60 * 24)
        );

        // Get reward details
        const rewardDoc = await admin.firestore()
          .collection('rewards')
          .doc(redemption.rewardId)
          .get();
        
        const reward = rewardDoc.data();
        
        // Get user's FCM tokens
        const userDoc = await admin.firestore()
          .collection('users')
          .doc(redemption.userId)
          .get();
        
        const fcmTokens = userDoc.data()?.fcmTokens || [];
        
        if (fcmTokens.length === 0) continue;

        // Send FCM notification
        const message = {
          notification: {
            title: '⏰ Reward Expiring Soon!',
            body: `Your ${reward.title} expires in ${daysLeft} days. Use it now!`
          },
          data: {
            type: 'reward_expiring',
            redemptionId: doc.id,
            daysLeft: daysLeft.toString(),
            route: '/my-rewards'
          },
          tokens: fcmTokens
        };

        try {
          await admin.messaging().sendMulticast(message);

          // Create notification document
          await admin.firestore()
            .collection('notifications')
            .add({
              userId: redemption.userId,
              title: '⏰ Reward Expiring Soon!',
              body: `Your ${reward.title} expires in ${daysLeft} days. Use it now!`,
              type: 'reward_expiring',
              data: {
                redemptionId: doc.id,
                daysLeft: daysLeft
              },
              isRead: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              actionRoute: '/my-rewards'
            });

          // Mark warning as sent
          await doc.ref.update({ expiryWarningSent: true });
          
        } catch (error) {
          console.error('Error sending expiry notification:', error);
        }
      }

      // Handle expired rewards
      const expiredQuery = await admin.firestore()
        .collection('reward_redemptions')
        .where('status', '==', 'active')
        .where('expiresAt', '<', now)
        .get();

      console.log(`Found ${expiredQuery.docs.length} expired rewards`);

      for (const doc of expiredQuery.docs) {
        const redemption = doc.data();

        // Update status to expired
        await doc.ref.update({ 
          status: 'expired',
          expiredAt: now 
        });

        // Get reward details
        const rewardDoc = await admin.firestore()
          .collection('rewards')
          .doc(redemption.rewardId)
          .get();
        
        const reward = rewardDoc.data();
        
        // Get user's FCM tokens
        const userDoc = await admin.firestore()
          .collection('users')
          .doc(redemption.userId)
          .get();
        
        const fcmTokens = userDoc.data()?.fcmTokens || [];
        
        if (fcmTokens.length === 0) continue;

        // Send expiry notification
        const message = {
          notification: {
            title: '⏰ Reward Expired',
            body: `Your ${reward.title} has expired. Better luck next time!`
          },
          data: {
            type: 'reward_expired',
            redemptionId: doc.id,
            route: '/my-rewards'
          },
          tokens: fcmTokens
        };

        try {
          await admin.messaging().sendMulticast(message);

          // Create notification document
          await admin.firestore()
            .collection('notifications')
            .add({
              userId: redemption.userId,
              title: '⏰ Reward Expired',
              body: `Your ${reward.title} has expired. Better luck next time!`,
              type: 'reward_expired',
              data: {
                redemptionId: doc.id
              },
              isRead: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              actionRoute: '/my-rewards'
            });
            
        } catch (error) {
          console.error('Error sending expired notification:', error);
        }
      }

    } catch (error) {
      console.error('Error in checkExpiringRewards:', error);
    }
  });

// 5. Cleanup Invalid FCM Tokens (Scheduled Function)
export const cleanupInvalidTokens = functions.pubsub
  .schedule('0 2 * * 0') // Weekly on Sunday at 2 AM UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    try {
      const usersSnapshot = await admin.firestore()
        .collection('users')
        .where('fcmTokens', '!=', null)
        .get();

      let cleanedCount = 0;

      for (const userDoc of usersSnapshot.docs) {
        const userData = userDoc.data();
        const fcmTokens = userData.fcmTokens || [];
        
        if (fcmTokens.length === 0) continue;

        // Test tokens by sending a silent message
        const validTokens = [];
        
        for (const token of fcmTokens) {
          try {
            await admin.messaging().send({
              token: token,
              data: { test: 'true' }
            });
            validTokens.push(token);
          } catch (error) {
            console.log(`Invalid token removed: ${token}`);
          }
        }

        // Update user document with valid tokens only
        if (validTokens.length !== fcmTokens.length) {
          await userDoc.ref.update({
            fcmTokens: validTokens,
            fcmTokenUpdatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
          cleanedCount++;
        }
      }

      console.log(`Cleaned up FCM tokens for ${cleanedCount} users`);
      
    } catch (error) {
      console.error('Error in cleanupInvalidTokens:', error);
    }
  });
```

### 4. Deploy Functions

```bash
# Deploy all functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:onRewardRedemption
```

### 5. Test Functions

```bash
# Test locally (optional)
firebase emulators:start --only functions,firestore
```

## Function Triggers Summary

| Function | Trigger | Purpose |
|----------|---------|---------|
| `onRewardRedemption` | onCreate on `/reward_redemptions/{id}` | Send notification when reward is redeemed |
| `onRewardShipped` | onUpdate on `/reward_redemptions/{id}` | Send notification when reward is shipped |
| `onRewardDelivered` | onUpdate on `/reward_redemptions/{id}` | Send notification when reward is delivered |
| `checkExpiringRewards` | Daily at 9 AM UTC | Check for expiring rewards and send warnings |
| `cleanupInvalidTokens` | Weekly on Sunday at 2 AM UTC | Clean up invalid FCM tokens |

## Firestore Security Rules

Add these rules to your `firestore.rules`:

```javascript
// Notifications collection
match /notifications/{notificationId} {
  allow read: if request.auth != null && 
              resource.data.userId == request.auth.uid;
  allow create: if false; // Only via Cloud Functions
  allow update: if request.auth != null && 
                resource.data.userId == request.auth.uid;
  allow delete: if false; // Only via Cloud Functions
}

// Reward redemptions collection
match /reward_redemptions/{redemptionId} {
  allow read: if request.auth != null && 
              resource.data.userId == request.auth.uid;
  allow create: if request.auth != null && 
                request.resource.data.userId == request.auth.uid;
  allow update: if false; // Only via Cloud Functions or admin
  allow delete: if false; // Only via admin
}
```

## Monitoring and Logs

Monitor your functions in the Firebase Console:
- Go to Functions section
- View logs and metrics
- Set up alerts for errors

## Cost Considerations

- Cloud Functions: $0.40 per million invocations
- FCM: Free for unlimited messages
- Firestore: Based on reads/writes
- Estimated cost: <$10/month for 10,000 users

## Troubleshooting

1. **Functions not triggering**: Check Firestore security rules
2. **FCM not working**: Verify FCM tokens are valid
3. **High costs**: Optimize function execution time
4. **Missing notifications**: Check function logs in Firebase Console

## Next Steps

1. Deploy the functions to your Firebase project
2. Test with real reward redemptions
3. Monitor function performance and costs
4. Add more notification types as needed (tournament wins, offers, etc.)

