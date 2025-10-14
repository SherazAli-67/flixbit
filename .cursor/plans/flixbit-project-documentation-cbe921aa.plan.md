<!-- cbe921aa-301a-4715-89c6-30ff72efff09 c6970041-5655-4ddb-afb6-62d46a743e44 -->
# Flixbit Project Documentation Plan

## Project Overview Analysis

- Document project purpose: Flixbit is a gamified marketing platform combining game predictions, rewards, QR code tracking, and location-based notifications
- Record technical stack: Flutter (Frontend), Firebase (Backend, Auth, Firestore, Storage)
- Document dual-user system: Regular users (buyers) and sellers with separate interfaces
- Record app version: 1.0.0+1, Flutter SDK: ^3.8.1

## Architecture Documentation

- **State Management**: Provider pattern with 7 providers:
- `AuthenticationProvider`: User authentication and profile management
- `LocaleProvider`: Multi-language support (English/Arabic)
- `LinkedAccountsProvider`: User/Seller account switching
- `ProfileProvider`: User profile management
- `ReviewsProvider`: Reviews and ratings
- `MainMenuTabChangeProvider`: Bottom navigation
- `VideoAdsProvider`: Video ad management

- **Routing**: GoRouter with StatefulShellRoute for nested navigation
- User flow: Dashboard, QR Scanner, Wallet, Profile
- Seller flow: Seller Dashboard, Offers, Video Ads, Tournaments, Profile
- 30+ routes defined in `RouterEnum`

## Core Features Documentation

1. **Authentication System**

- Email/password authentication via Firebase
- User and Seller separate data in Firestore collections
- Profile image storage in Firebase Storage

2. **Game Prediction System** (DETAILED MODULE)

**Core Integration:**

- Accessible from Dashboard via "Game Predictions" quick access icon
- Route: `/game_predication_view` → `GamePredicationPage`
- Three-page flow: Tournament List → Match List → Make Prediction

**Tournament Management:**

- Service: `TournamentService.getDummyTournaments()`
- Currently using dummy data (3 tournaments: Premier League, Champions League, La Liga)
- Real implementation will connect to Firestore `tournaments` collection
- Admin/Sub-admin create tournaments with:
  - Points per prediction (10-15 points typical)
  - Qualification threshold (75-80% accuracy)
  - Prize pool and winner count
  - Date range and match count

**User Prediction Flow:**

1. View tournament cards with live stats
2. Click "View Matches" → `TournamentMatchesPage`
3. Select match → `MakePredictionPage`
4. Submit before 1-hour deadline
5. Stats auto-update after match completion

**Stats Tracking (`UserTournamentStats`):**

- Total predictions made vs total matches
- Correct predictions count
- Real-time accuracy percentage
- Points earned (correct × pointsPerPrediction)
- Qualification status (isQualified flag)
- Purchased points to boost qualification

**UI Components:**

- Tournament cards with status badges (upcoming/live/completed)
- Three-column stats display (Accuracy/Points/Predictions)
- Linear progress bar toward qualification threshold
- Color-coded indicators (green=qualified, blue=active)
- Qualification badge or action button

**Point Integration:**

- Connects to Flixbit virtual currency system
- Points earned → Added to user wallet
- Points can be purchased to reach qualification
- Qualified users → Eligible for prize draw

**Prize Distribution Logic:**

- After tournament ends (status: completed)
- Filter qualified users (accuracy >= threshold)
- Random selection from qualified pool
- Number of winners defined in tournament
- Notification sent to winners
- Prizes can be: cash, coupons, physical rewards

**Data Flow:**

```
Tournament → contains Matches
User → makes Predictions on Matches
System → calculates accuracy after Match.status = completed
Stats → updated in UserTournamentStats
Qualification → checked against threshold
Prize Draw → random selection of qualified users
```

**Firebase Collections Structure:**

- `tournaments/{tournamentId}` - Tournament data
- `matches/{matchId}` - Match details with tournamentId reference
- `predictions/{predictionId}` - User predictions
- `user_tournament_stats/{userId}_{tournamentId}` - Performance tracking
- `tournament_winners/{tournamentId}` - Winner records after draw

3. **QR Code System**

- Each seller has unique QR code
- Users scan to follow sellers and receive notifications
- QR tracking for engagement analytics

4. **Flixbit Points (Virtual Currency)**

- Earned through: predictions, watching ads, referrals, reviews
- Redeemable for: coupons, rewards, contest entries
- Buy/sell functionality

5. **Video Ads System**

- Sellers upload promotional videos
- Minimum watch time for reward eligibility
- Rating system (thumbs up/down)
- Contest voting windows

6. **Offers & Coupons**

- Multiple offer types: discount, free item, BOGO, cashback, points, voucher
- Validity period tracking
- Redemption limit management
- Review-linked rewards

7. **Wheel of Fortune**

- Gift sending/receiving system
- Random reward spin
- Auto-expiry and refund mechanism

8. **Reviews System**

- Multiple review types: seller, offer, video ad, referral
- Verification methods: QR scan, offer redemption, video watch
- Points rewards for verified reviews
- Seller reply capability

## Data Models Documentation

**Key Models:**

- `UserModel`: userID, name, email, profileImg, createdAt
- `Seller`: 23 fields including verification, ratings, business hours
- `Tournament`: status, points system, qualification threshold, prizes
- `Match`: teams, scores, status, prediction close time
- `Prediction`: user predictions with accuracy tracking
- `Offer`: 6 types with validity and redemption tracking
- `Review`: ratings, verification, points earned
- `VideoAd`: duration, rewards, contest settings

## Localization System

- Supported: English (en) and Arabic (ar)
- RTL support for Arabic
- 50+ localized strings
- ARB files: `app_en.arb`, `app_ar.arb`
- Auto-generated localization classes

## UI/UX Configuration

**Colors** (`app_colors.dart`):

- Dark theme with custom color scheme
- Primary: #17a3eb (blue)
- Background: #0f1c22 (dark)
- 30+ defined colors for consistency

**Typography**:

- Font family: Figtree (Regular, Medium, Bold)
- Custom text styles in `apptextstyles.dart`

**Assets**:

- Images: location.png, referral_page_img.png, sign_in_img.png
- SVG icons: camera, social media (Facebook, Instagram, Snapchat, Telegram, WhatsApp), login elements

## Firebase Configuration

**Collections**:

- `users`: User profiles and data
- `sellers`: Seller profiles and business info
- Additional collections implied: tournaments, matches, predictions, offers, reviews, video_ads

**Services**:

- `tournament_service.dart`: Tournament and match management
- `seller_service.dart`: Seller profile operations
- `gift_service.dart`: Wheel of Fortune gift system
- `video_ads_repository.dart`: Video ad CRUD operations

## Key File Locations

**Configuration**:

- `lib/src/res/app_colors.dart`: Color constants
- `lib/src/res/app_constants.dart`: App-wide constants
- `lib/src/res/firebase_constants.dart`: Firestore collection names
- `lib/src/routes/router_enum.dart`: All route definitions
- `lib/src/routes/app_router.dart`: GoRouter configuration

**Features** (39 files):

- Authentication: `lib/src/features/authentication/`
- Game Prediction: `lib/src/features/game_prediction/`
- Main Menu: `lib/src/features/main_menu/`
- Seller Features: `lib/src/features/seller/`
- Video Ads: `lib/src/features/video_ads/`
- Reviews: `lib/src/features/reviews/`

**Models** (11 files in `lib/src/models/`):

- Core models: user, seller, tournament, match, prediction, offer, review, video_ad
- Supporting: gift_model, wheel_result_model, user_tournament_stats

## Dependencies Summary

**Key Packages**:

- State Management: provider ^6.1.5+1
- Navigation: go_router ^14.2.0
- Firebase: firebase_core, firebase_auth, cloud_firestore, firebase_storage
- UI: flutter_svg ^2.2.1, cached_network_image ^3.4.1
- Features: flutter_fortune_wheel ^1.3.1, confetti ^0.7.0, video_player ^2.9.2
- QR: mobile_scanner ^7.1.2, qr_flutter ^4.1.0
- Storage: shared_preferences ^2.5.3
- Media: image_picker ^1.2.0
- Localization: flutter_localizations, intl ^0.20.2

## Build Configuration

**Platforms**: Android, iOS, Web, Linux, Windows, macOS

**Firebase**: Configured with google-services.json (Android) and GoogleService-Info.plist (iOS)

**Material 3**: Enabled with dark theme

**Localization**: Flutter gen enabled in pubspec.yaml

### To-dos

- [ ] Update Match model with new fields and methods for status management
- [ ] Create Firebase Cloud Function for automatic status updates
- [ ] Create MatchStatusValidator service for status transition validation
- [ ] Enhance EnhancedTournamentService with real-time status updates
- [ ] Update seller UI with new status controls and match phases
- [ ] Add status change notifications and history tracking
- [ ] Enhance user UI with real-time status indicators and notifications