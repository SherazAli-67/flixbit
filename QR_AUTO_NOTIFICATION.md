Auto-Notification Triggers - Implementation Plan
Overview
Implement automatic notification triggers that send notifications to users based on specific QR system events, such as QR scans, offer redemptions, and follower inactivity.
Subtask 11.1: Create Auto-Notification Service
File to Create
lib/src/service/qr_auto_notification_service.dart
Auto-Triggers to Implement
1. Welcome Notification After QR Scan
   Trigger: User scans seller's QR code for the first time
   Message Template: "Thanks for scanning! Follow us for exclusive offers."
   Timing: Immediately after QR scan
   Conditions:
   Only if user is not already following the seller
   Only if seller has welcome notifications enabled
   Respects user notification preferences
2. Offer Reminder (24h Before Expiry)
   Trigger: User has an active offer that expires in 24 hours
   Message Template: "Your offer expires tomorrow! Redeem now."
   Timing: 24 hours before offer expiration
   Conditions:
   User has not redeemed the offer yet
   Offer is still valid
   Seller has reminder notifications enabled
3. Re-engagement for Inactive Followers (30 Days)
   Trigger: Follower hasn't interacted with seller in 30 days
   Message Template: "We miss you! Check out our latest offers."
   Timing: 30 days after last interaction
   Conditions:
   No QR scans in last 30 days
   No offer redemptions in last 30 days
   Seller has re-engagement notifications enabled
4. Thank You After Offer Redemption
   Trigger: User successfully redeems an offer
   Message Template: "Thanks for redeeming! Enjoy your reward."
   Timing: Immediately after offer redemption
   Conditions:
   Offer redemption was successful
   Seller has thank you notifications enabled