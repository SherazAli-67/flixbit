<!-- 1568e741-ad91-45ca-b08f-12566e0440e4 52ca61d2-8606-4e52-9aec-7818c0a0bf37 -->
# Create Video Contests Admin Features README

## Overview

Create a detailed README.md file that documents all admin features required for the Video Contest system. This will serve as a specification document for when Admin Dashboard development begins.

## File to Create

**File:** `VIDEO_CONTESTS_ADMIN.md` (root directory)

## Content Structure

### 1. Introduction Section

- Overview of Video Contest system
- Admin vs Sub-Admin roles
- Current implementation status

### 2. Video Ad Management Features

Document admin features for video approval:

- List all pending video ads with filters (status, category, region, date)
- Video preview and playback
- Approve/Reject video with reason
- Flag inappropriate content
- Set as inactive
- Edit video metadata (category, region, reward points)
- Bulk approval/rejection
- Video analytics view

Reference existing models:

- `lib/src/models/video_ad.dart` (ApprovalStatus enum)
- Fields: uploadedBy, approvalStatus, approvedBy, approvedAt, rejectionReason

### 3. Video Contest Management Features

Document admin features for contest management:

- Create new contest form (title, description, dates, category, region)
- Edit existing contests
- Set vote windows (start/end dates)
- Define prize structure (1st, 2nd, 3rd place points)
- Link rewards to contests
- Pause/Resume contests
- End contest early
- Mark as featured/sponsored
- Bulk operations

Reference existing models:

- `lib/src/models/video_contest.dart` (all fields)

### 4. Contest Participant Management

Document features for managing contest videos:

- View all participating videos in a contest
- Add/Remove videos from contest
- Review video eligibility
- Handle contest violations
- Disqualify participants

### 5. Winner Announcement System

Document the winner selection and announcement process:

- View contest leaderboard
- Verify vote counts
- Manual winner selection (if needed)
- Automatic winner calculation based on votes
- Announce winners
- Distribute rewards to winners
- Send notifications to winners
- Export winner list

Reference existing models:

- `lib/src/models/contest_winner.dart`
- `lib/src/models/video_contest.dart` (winnersAnnounced field)

### 6. Analytics Dashboard

Document analytics features needed:

- Video ad performance metrics
- Total views, watch time, completion rate
- Engagement (likes, ratings)
- Reward claims
- Category/region breakdown
- Contest analytics
- Total contests, active, ended
- Participant trends
- Voting activity
- Popular categories
- Regional performance
- Revenue analytics (if sponsorships)

Reference existing services:

- `lib/src/service/video_analytics_service.dart`
- `lib/src/models/video_analytics.dart`

### 7. Moderation Tools

Document content moderation features:

- Flagged content queue
- User reports review
- Block/Unblock users from uploading
- Ban videos/contests
- Automated content filtering rules
- Appeal management

### 8. Sponsorship Management (if applicable)

Document sponsorship features:

- Set sponsorship amounts for videos
- Mark contests as sponsored
- Sponsor performance reports
- Revenue tracking

Reference model fields:

- `VideoAd.sponsorshipAmount`
- `VideoContest.isSponsored`

### 9. Notification Management

Document notification features:

- Send contest announcements
- Winner notifications
- Video approval/rejection notifications
- Custom push notifications for contests

### 10. Reports & Export

Document reporting features:

- Contest performance reports
- Video ad engagement reports
- Winner history
- Revenue reports
- Export to CSV/Excel

### 11. Technical Requirements

Document technical specifications:

- Firebase collections used
- video_ads
- video_contests
- contest_winners
- video_analytics
- video_uploads
- Required permissions
- API endpoints (if any)
- State management approach
- Security rules needed

### 12. UI/UX Requirements

Document UI specifications:

- Responsive design requirements
- Table/List view requirements
- Filter and search functionality
- Bulk action checkboxes
- Status badges and colors
- Modal/Dialog requirements

### 13. Implementation Priority

Suggest implementation phases:

- Phase 1: Video approval system (critical)
- Phase 2: Contest CRUD operations
- Phase 3: Winner announcement
- Phase 4: Analytics dashboard
- Phase 5: Advanced moderation tools

### 14. Future Enhancements

List potential future features:

- AI-powered content moderation
- Advanced analytics (ML predictions)
- Multi-language support for admin panel
- Role-based permissions (granular)
- Audit logs
- Scheduled contests
- Contest templates

## Implementation Approach

1. Create comprehensive markdown file with all sections
2. Include code references to existing models and services
3. Add example screenshots/wireframes descriptions where helpful
4. Include data structure examples
5. Document all enum values and their meanings
6. Add links to related documentation
7. Include Firebase collection structure examples

## Key Files Referenced

- `lib/src/models/video_ad.dart` - Video ad model with approval fields
- `lib/src/models/video_contest.dart` - Contest model
- `lib/src/models/contest_winner.dart` - Winner model
- `lib/src/models/video_analytics.dart` - Analytics model
- `lib/src/service/video_contest_service.dart` - Contest operations
- `lib/src/service/video_analytics_service.dart` - Analytics tracking
- `lib/src/res/firebase_constants.dart` - Collection names

### To-dos

- [ ] Create VideoAnalyticsService with view tracking, engagement tracking, and metrics calculation
- [ ] Create VideoAnalyticsProvider for state management of analytics data
- [ ] Integrate auto-tracking in video_ad_detail_page, video_ads_repository_impl, and video_contest_service
- [ ] Create seller analytics dashboard page with charts, top videos, and export functionality
- [ ] Replace mock metrics in upload_video_ad_page with real analytics data
- [ ] Update seller_video_ads_page with real video data and analytics preview