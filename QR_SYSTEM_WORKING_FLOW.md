# Flixbit QR System - Complete Working Flow Documentation

## Table of Contents
1. [Phase 1: Seller QR Enhancements](#phase-1-seller-qr-enhancements)
2. [Phase 2: User Experience Improvements](#phase-2-user-experience-improvements)
3. [Complete User Journey Examples](#complete-user-journey-examples)
4. [Data Flow Architecture](#data-flow-architecture)

---

## PHASE 1: SELLER QR ENHANCEMENTS

### Flow 1: Seller QR Code Generation & Management

```
┌─────────────────────────────────────────────────────────────┐
│ SELLER REGISTERS → SELLER DASHBOARD                          │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 1. QR Code Auto-Generation                                   │
│    - Format: 'flixbit:seller:{sellerId}'                    │
│    - Displayed in dashboard with seller info                 │
│    - White background, 200px size                            │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Seller Actions Available                                  │
│    ├─ Download QR → Saves PNG to device                     │
│    ├─ Share QR → Copies data to clipboard                   │
│    └─ Display QR → Shows for printing/scanning              │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Seller Prints/Displays QR at Business Location           │
└─────────────────────────────────────────────────────────────┘
```

**Technical Implementation:**
- **File**: `lib/src/features/seller/seller_main_menu/seller_dashboard_page.dart`
- **Service**: `lib/src/service/qr_download_service.dart`
- **QR Library**: `qr_flutter` package
- **Storage**: Device documents directory via `path_provider`

---

### Flow 2: Seller QR Analytics Dashboard

```
┌─────────────────────────────────────────────────────────────┐
│ SELLER → QR CODE TRACKING PAGE                              │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 1. Real-Time Statistics Display                             │
│    ├─ Total Scans (all-time)                                │
│    ├─ Daily Scans (today)                                   │
│    ├─ Weekly Scans (last 7 days)                            │
│    └─ Monthly Scans (last 30 days)                          │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Visual Analytics                                          │
│    ├─ Daily Trend Chart (last 30 days line graph)          │
│    ├─ Peak Hour Analysis (busiest scan time)               │
│    └─ Conversion Metrics (scans → followers)                │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Data Sources                                              │
│    ├─ Firebase: 'qr_scans' collection                       │
│    ├─ Firebase: 'seller_qr_stats' collection                │
│    └─ Firebase: 'seller_followers' collection               │
└─────────────────────────────────────────────────────────────┘
```

**Technical Implementation:**
- **File**: `lib/src/features/seller/seller_qr_code_tracking_page.dart`
- **Service**: `lib/src/service/qr_analytics_service.dart`
- **Charts**: `fl_chart` package for line graphs
- **Data**: Real-time Firebase streams

**Key Metrics Calculated:**
```dart
- Conversion Rate = (Followers from QR / Total Scans) × 100
- Peak Hour = Hour with maximum scan count
- Daily Trend = Scans per day for last 30 days
```

---

### Flow 3: Follower Management System

```
┌─────────────────────────────────────────────────────────────┐
│ SELLER → MY FOLLOWERS PAGE                                   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 1. Filter Options                                            │
│    ├─ All Followers                                          │
│    ├─ QR Scan (followed via QR)                             │
│    ├─ Manual (followed manually)                            │
│    └─ Offer Redemption (followed via offer)                 │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Follower Details Displayed                                │
│    ├─ User ID (masked for privacy)                          │
│    ├─ Follow Source (QR/Manual/Offer)                       │
│    ├─ Follow Date & Time                                     │
│    └─ Notification Status (enabled/disabled)                │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Real-Time Updates via Firebase Streams                   │
└─────────────────────────────────────────────────────────────┘
```

**Technical Implementation:**
- **File**: `lib/src/features/seller/seller_followers_page.dart`
- **Service**: `lib/src/service/seller_follower_service.dart`
- **Data Model**: `lib/src/models/seller_follower_model.dart`
- **Collection**: `seller_followers` in Firebase Firestore

**Follower Record Structure:**
```dart
{
  id: String,
  userId: String,
  sellerId: String,
  followedAt: DateTime,
  followSource: String, // 'manual', 'qr_scan', 'offer_redemption'
  notificationsEnabled: bool,
  metadata: Map<String, dynamic>
}
```

---

### Flow 4: Offer QR Code System

```
┌─────────────────────────────────────────────────────────────┐
│ SELLER CREATES OFFER                                         │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 1. Automatic QR Generation                                   │
│    Format: 'flixbit:offer:{offerId}:{sellerId}:{timestamp}' │
│    Stored in: offer.qrCodeData field                        │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Seller Views Offer List                                   │
│    ├─ Tap "View QR Code" → Quick QR View                    │
│    └─ Tap "Manage QR" → Full Management Page                │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 3A. Quick QR View (OfferQRDetailPage)                       │
│    ├─ Large QR display                                       │
│    ├─ Offer details (validity, discount)                    │
│    ├─ Download button                                        │
│    ├─ Share button                                           │
│    └─ Copy QR data button                                    │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 3B. Full QR Management (OfferQRManagementPage)              │
│    ├─ QR Code Display Section                               │
│    │   └─ Offer image + QR code                             │
│    ├─ Offer Details Section                                 │
│    │   └─ Validity, redemptions, status                     │
│    ├─ Analytics Section                                      │
│    │   ├─ Views count                                        │
│    │   ├─ Total redemptions                                  │
│    │   ├─ QR vs Digital redemptions                         │
│    │   └─ Conversion rate                                    │
│    ├─ QR Actions Section                                     │
│    │   ├─ Download, Share, Copy                             │
│    │   └─ Generate printable flyer                          │
│    └─ QR Settings Section                                    │
│        └─ Status, ID, creation date                         │
└─────────────────────────────────────────────────────────────┘
```

**Technical Implementation:**
- **Files**: 
  - `lib/src/features/seller/offer_qr_detail_page.dart` (Quick view)
  - `lib/src/features/seller/offer_qr_management_page.dart` (Full management)
- **Service**: `lib/src/service/offer_service.dart` (getOfferAnalytics method)
- **QR Generation**: Done in `OfferService.createOffer()` method

---

## PHASE 2: USER EXPERIENCE IMPROVEMENTS

### Flow 5: User QR Scanning (Camera)

```
┌─────────────────────────────────────────────────────────────┐
│ USER → OPENS QR SCANNER                                      │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 1. Camera Initialization                                     │
│    - Back camera activated                                   │
│    - Real-time QR detection enabled                         │
│    - Processing state managed                                │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. QR Code Detected                                          │
│    - Parse QR data format                                    │
│    - Validate format: 'flixbit:seller:...' or               │
│                       'flixbit:offer:...'                    │
└─────────────────────────────────────────────────────────────┘
                           ↓
        ┌─────────────────┴─────────────────┐
        ↓                                     ↓
┌──────────────────┐              ┌──────────────────┐
│ SELLER QR        │              │ OFFER QR         │
└──────────────────┘              └──────────────────┘
        ↓                                     ↓
┌──────────────────┐              ┌──────────────────┐
│ Process Seller   │              │ Process Offer    │
│ QR Scan          │              │ QR Redemption    │
└──────────────────┘              └──────────────────┘
```

**Seller QR Scan Flow:**
```
┌─────────────────────────────────────────────────────────────┐
│ 1. Validation Checks                                         │
│    ├─ Check daily limit (100 scans/day)                     │
│    ├─ Check cooldown (15 min between same seller)           │
│    └─ Verify user authentication                            │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Record Scan in Firebase                                   │
│    Collection: 'qr_scans'                                    │
│    Data: {                                                   │
│      userId, sellerId, qrCode,                              │
│      scannedAt, pointsAwarded,                              │
│      location (optional)                                     │
│    }                                                         │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Award Points                                              │
│    - 10 Flixbit points awarded                              │
│    - Transaction recorded in wallet                          │
│    - Source: TransactionSource.qrScan                       │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Auto-Follow Seller                                        │
│    - Check if already following                              │
│    - If not, create follower record                         │
│    - Update seller's follower count                         │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Update Seller Stats                                       │
│    Collection: 'seller_qr_stats'                            │
│    Update: dailyScans, totalScans                           │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. Navigate to Seller Profile                               │
│    - Show success message                                    │
│    - Display seller details                                  │
│    - Show follow status                                      │
└─────────────────────────────────────────────────────────────┘
```

**Offer QR Redemption Flow:**
```
┌─────────────────────────────────────────────────────────────┐
│ 1. Validate Offer QR                                         │
│    ├─ Check offer exists                                     │
│    ├─ Verify QR data matches                                │
│    ├─ Check offer is active                                 │
│    └─ Check not expired                                      │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Check Redemption Eligibility                             │
│    ├─ User hasn't redeemed before                           │
│    ├─ Daily redemption limit not reached                    │
│    └─ Offer not fully redeemed                              │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Create Redemption Record                                  │
│    Collection: 'offer_redemptions'                          │
│    Data: {                                                   │
│      userId, offerId, sellerId,                             │
│      redeemedAt, pointsEarned,                              │
│      qrCodeData                                              │
│    }                                                         │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Award Points & Update Counts                             │
│    - Award review points (if applicable)                     │
│    - Increment offer redemption count                        │
│    - Update offer analytics                                  │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Auto-Follow Seller                                        │
│    Source: 'offer_redemption'                               │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. Show Success Dialog                                       │
│    - Confirmation message                                    │
│    - Points earned display                                   │
│    - Navigate to offer details                              │
└─────────────────────────────────────────────────────────────┘
```

**Technical Implementation:**
- **File**: `lib/src/features/main_menu/qr_scanner_page.dart`
- **Services**: 
  - `lib/src/service/qr_scan_service.dart` (seller scans)
  - `lib/src/service/offer_service.dart` (offer redemptions)
- **Scanner**: `mobile_scanner` package v7.1.2

---

### Flow 6: Gallery QR Import

```
┌─────────────────────────────────────────────────────────────┐
│ USER → QR SCANNER → "Scan from Gallery" Button              │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 1. Open Image Picker                                         │
│    - ImagePicker.pickImage(source: gallery)                 │
│    - User selects image from device                         │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Analyze Image for QR Code                                │
│    - cameraController.analyzeImage(imagePath)               │
│    - Extract barcode data                                    │
│    - Validate QR format                                      │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Process QR Code                                           │
│    - Same flow as camera scan                                │
│    - Parse seller/offer QR                                   │
│    - Award points, follow seller, etc.                       │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Error Handling                                            │
│    - No QR found → Show error message                        │
│    - Invalid format → Show error message                     │
│    - Processing error → Show error message                   │
└─────────────────────────────────────────────────────────────┘
```

**Technical Implementation:**
- **Methods**: `_pickImageFromGallery()` and `_processImageForQR()`
- **Package**: `image_picker` for gallery access
- **Scanner**: `mobile_scanner.analyzeImage()` for QR detection
- **File**: `lib/src/features/main_menu/qr_scanner_page.dart`

---

### Flow 7: Follow/Unfollow Seller

```
┌─────────────────────────────────────────────────────────────┐
│ USER → SELLER PROFILE → Follow Button                       │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 1. Check Current Follow Status                              │
│    - Query 'seller_followers' collection                    │
│    - userId + sellerId combination                          │
└─────────────────────────────────────────────────────────────┘
                           ↓
        ┌─────────────────┴─────────────────┐
        ↓                                     ↓
┌──────────────────┐              ┌──────────────────┐
│ NOT FOLLOWING    │              │ ALREADY FOLLOWING│
│ → Follow         │              │ → Unfollow       │
└──────────────────┘              └──────────────────┘
        ↓                                     ↓
┌──────────────────┐              ┌──────────────────┐
│ Create Record    │              │ Delete Record    │
│ in Firebase      │              │ from Firebase    │
└──────────────────┘              └──────────────────┘
        ↓                                     ↓
┌──────────────────┐              ┌──────────────────┐
│ Update Seller    │              │ Update Seller    │
│ Follower Count   │              │ Follower Count   │
│ (+1)             │              │ (-1)             │
└──────────────────┘              └──────────────────┘
        ↓                                     ↓
┌─────────────────────────────────────────────────────────────┐
│ Update UI                                                    │
│    - Change button icon (heart filled/outline)              │
│    - Change button text (Following/Follow)                  │
│    - Change button color (red/primary)                      │
│    - Show success message                                    │
└─────────────────────────────────────────────────────────────┘
```

**Technical Implementation:**
- **File**: `lib/src/features/reviews/seller_profile_page.dart`
- **Service**: `lib/src/service/seller_follower_service.dart` (toggleFollow method)
- **State Management**: Local state with real-time UI updates

---

### Flow 8: User Scan History

```
┌─────────────────────────────────────────────────────────────┐
│ USER → SCAN HISTORY PAGE                                     │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 1. Load User's Scan History                                 │
│    - Stream from 'qr_scans' collection                      │
│    - Filter by userId                                        │
│    - Order by scannedAt (descending)                        │
│    - Limit to last 50 scans                                 │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Display Scan Cards                                        │
│    Each card shows:                                          │
│    ├─ QR icon                                                │
│    ├─ Seller ID (masked)                                     │
│    ├─ Scan date & time                                       │
│    ├─ Points earned badge (+10)                             │
│    └─ Location indicator (if available)                     │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Empty State                                               │
│    If no scans: Show message                                │
│    "No scan history yet"                                     │
│    "Scan a seller's QR code to get started"                 │
└─────────────────────────────────────────────────────────────┘
```

**Technical Implementation:**
- **File**: `lib/src/features/main_menu/qr_scan_history_page.dart`
- **Service**: `lib/src/service/qr_scan_service.dart` (getUserScans method)
- **Data**: Real-time Firebase stream

---

## COMPLETE USER JOURNEY EXAMPLE

### Scenario: User Scans Restaurant QR Code

```
1. USER ENTERS RESTAURANT
   └─ Sees QR code on table/counter

2. OPENS FLIXBIT APP
   └─ Navigates to QR Scanner

3. SCANS QR CODE
   ├─ Camera detects: 'flixbit:seller:abc123xyz'
   ├─ Validates format ✓
   └─ Checks daily limit ✓

4. SYSTEM PROCESSES SCAN
   ├─ Records in 'qr_scans' collection
   ├─ Awards 10 Flixbit points
   ├─ Auto-follows restaurant
   └─ Updates restaurant stats

5. USER SEES SUCCESS
   ├─ "Points awarded for QR scan!"
   ├─ Navigates to restaurant profile
   └─ Sees follow status: "Following"

6. RESTAURANT OWNER SEES ANALYTICS
   ├─ Daily scans: +1
   ├─ Total scans: Updated
   ├─ New follower: +1
   └─ Can now send notifications to user

7. USER BROWSES OFFERS
   ├─ Sees restaurant's active offers
   ├─ Finds "20% OFF" offer
   └─ Scans offer QR code

8. OFFER REDEMPTION
   ├─ Validates offer QR
   ├─ Creates redemption record
   ├─ Awards review points
   └─ Shows success dialog

9. RESTAURANT TRACKS PERFORMANCE
   ├─ Views: +1
   ├─ QR Redemptions: +1
   ├─ Conversion rate: Updated
   └─ Analytics dashboard shows trends

10. FUTURE ENGAGEMENT
    ├─ User receives push notifications
    ├─ Restaurant sends new offers
    └─ User can view scan history
```

---

## DATA FLOW ARCHITECTURE

```
┌──────────────┐
│   USER APP   │
└──────┬───────┘
       │ Scans QR
       ↓
┌──────────────────────┐
│  QR Scanner Service  │
└──────┬───────────────┘
       │ Validates & Parses
       ↓
┌──────────────────────────────────────────────┐
│              FIREBASE FIRESTORE              │
├──────────────────────────────────────────────┤
│  Collections Updated:                        │
│  ├─ qr_scans (scan record)                  │
│  ├─ seller_qr_stats (seller stats)          │
│  ├─ seller_followers (follow record)        │
│  ├─ flixbit_transactions (points)           │
│  └─ offer_redemptions (if offer QR)         │
└──────┬───────────────────────────────────────┘
       │ Real-time Updates
       ↓
┌──────────────────────────────────────────────┐
│         SELLER DASHBOARD                     │
├──────────────────────────────────────────────┤
│  ├─ QR Analytics (real-time)                │
│  ├─ Follower List (real-time)               │
│  └─ Offer Analytics (real-time)             │
└──────────────────────────────────────────────┘
```

---

## FIREBASE COLLECTIONS STRUCTURE

### qr_scans Collection
```dart
{
  id: String,
  userId: String,
  sellerId: String,
  qrCode: String,
  scannedAt: Timestamp,
  pointsAwarded: int,
  location: GeoPoint? (optional)
}
```

### seller_qr_stats Collection
```dart
{
  sellerId: String,
  dailyScans: int,
  totalScans: int,
  lastUpdated: Timestamp
}
```

### seller_followers Collection
```dart
{
  id: String,
  userId: String,
  sellerId: String,
  followedAt: DateTime,
  followSource: String, // 'qr_scan', 'manual', 'offer_redemption'
  notificationsEnabled: bool,
  metadata: Map<String, dynamic>
}
```

### offer_redemptions Collection
```dart
{
  id: String,
  userId: String,
  offerId: String,
  sellerId: String,
  redeemedAt: DateTime,
  pointsEarned: int,
  qrCodeData: String
}
```

---

## KEY FEATURES SUMMARY

### Phase 1 Features (100% Complete)
✅ Seller QR code generation with correct format
✅ QR download and share functionality
✅ Comprehensive QR analytics dashboard
✅ Follower management system
✅ Offer QR code generation and management
✅ Real-time statistics and charts

### Phase 2 Features (75% Complete)
✅ Camera-based QR scanning
✅ Gallery QR import
✅ Follow/unfollow functionality
✅ User scan history
⏳ Location tracking (pending)

---

## NAVIGATION PATHS

### User Navigation
```
Main Menu → QR Scanner → [Scan QR] → Seller Profile
Main Menu → QR Scanner → [Scan from Gallery] → Seller Profile
Main Menu → Profile → QR SYSTEM → Scan History → [View Past Scans]
Seller Profile → [Follow Button] → Toggle Follow Status
```

**Navigation Implementation:**
- **User Profile Page** (`lib/src/features/main_menu/profile_page.dart`):
  - Added "QR SYSTEM" section with "Scan History" menu item
  - Navigation: `context.push(RouterEnum.qrScanHistoryView.routeName)`

### Seller Navigation
```
Seller Dashboard → QR System Section → My Followers → [Filter & View]
Seller Dashboard → QR System Section → QR Analytics → [View Statistics]
Seller Dashboard → [View QR Code] → Download/Share
Seller Offers → [View QR Code] → Quick QR View
Seller Offers → [Manage QR] → Full QR Management
```

**Navigation Implementation:**
- **Seller Dashboard Page** (`lib/src/features/seller/seller_main_menu/seller_dashboard_page.dart`):
  - Added "QR System" quick actions card with two buttons:
    - "My Followers" → `context.push(RouterEnum.sellerFollowersView.routeName)`
    - "QR Analytics" → `context.push(RouterEnum.sellerQRCodeTrackingView.routeName)`
  - Uses custom `_buildQuickActionButton` widget for consistent styling

---

**Document Version**: 1.0
**Last Updated**: Implementation Complete
**Status**: Phase 1 & Phase 2 Implemented

