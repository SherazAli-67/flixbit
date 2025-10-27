import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flixbit/src/res/apptextstyles.dart';
import 'package:flixbit/src/routes/router_enum.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flixbit/src/models/video_ad.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../res/app_colors.dart';
import '../../../res/firebase_constants.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  VideoAd? _featuredVideo;

  @override
  void initState() {
    super.initState();
    _loadFeaturedVideo();
  }


  Future<void> _loadFeaturedVideo() async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.videoAdsCollection)
          .where('approvalStatus', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty && mounted) {
        setState(()=> _featuredVideo = VideoAd.fromFirestore(
          snapshot.docs.first.data(),
          snapshot.docs.first.id,
        ));
      }
    } catch (e) {
      debugPrint("Error while fetching featured video"); // Silently fail - featured video is optional
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 24,
              children: [
                Text(l10n.dashboard, style: AppTextStyles.headingTextStyle3),
                _buildMediaSection(context),
                _buildQuickAccessSection(context, l10n),
                _buildListCardsSection(context, l10n),
                _buildBottomCardsSection(context, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaSection(BuildContext context) {
    if (_featuredVideo == null) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.cardBgColor,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 12,
            children: [
              Icon(Icons.videocam, size: 48, color: AppColors.unSelectedGreyColor),
              Text('No featured video yet', style: AppTextStyles.bodyTextStyle.copyWith(color: AppColors.lightGreyColor,),),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: _featuredVideo!.thumbnailUrl != null
            ? DecorationImage(image: NetworkImage(_featuredVideo!.thumbnailUrl!), fit: BoxFit.cover,)
            : null,
        gradient: _featuredVideo!.thumbnailUrl == null
            ? const LinearGradient(
                colors: [Color(0xff2a3b45), Color(0xff1e2a32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.6),
              Colors.black.withValues(alpha: 0.3),
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: GestureDetector(
          onTap: ()=> context.push(
            RouterEnum.videoDetailsView.routeName,
            extra: {
              'ad': _featuredVideo!,
              'sellerId': _featuredVideo!.uploadedBy,
            },
          ),
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      _featuredVideo!.title,
                      style: AppTextStyles.tileTitleTextStyle.copyWith(
                        shadows: [const Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      spacing: 8,
                      children: [
                        Icon(Icons.stars, size: 14, color: Colors.amber),
                        Text(
                          '+${_featuredVideo!.rewardPoints} Flixbit',
                          style: AppTextStyles.smallTextStyle.copyWith(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Text(
          l10n.quickAccess,
          style: AppTextStyles.subHeadingTextStyle
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 5,
          children: [
            _buildQuickAccessButton(Icons.card_giftcard, l10n.offers, ()=> context.push(RouterEnum.offersView.routeName)),
            _buildQuickAccessButton(Icons.wb_sunny, l10n.gifts, (){}),
            _buildQuickAccessButton(Icons.account_tree, l10n.rewards, ()=>context.push(RouterEnum.rewardsView.routeName)),
            _buildQuickAccessButton(Icons.notifications, l10n.notifications, ()=> context.push(RouterEnum.notificationCenterView.routeName)),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessButton(IconData icon, String label,VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              spacing: 8,
              children: [
                Icon(
                  icon,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
                Text(
                    label,
                    style: AppTextStyles.captionTextStyle
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListCardsSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      spacing: 20,
      children: [
        _buildListCard(Icons.sports_soccer, l10n.gamePredictions, l10n.predictMatchOutcomes, ()=> context.push(RouterEnum.gamePredictionView.routeName)),
        _buildListCard(Icons.stars, l10n.subscriptionPackages, l10n.upgradeForMoreFeatures, ()=> context.push(RouterEnum.subscriptionView.routeName)),
        _buildListCard(Icons.video_collection_rounded, 'Watch & Earn', 'Watch Featured ads and Earn Flixbit points', ()=> context.push(RouterEnum.videoAdsView.routeName)),
        _buildListCard(Icons.emoji_events, 'Video Contests', 'Vote on videos and win prizes', ()=> context.push(RouterEnum.contestListView.routeName)),
        _buildListCard(Icons.people, l10n.referrals, l10n.inviteFriends, ()=>  context.push(RouterEnum.referralView.routeName)),
      ],
    );
  }

  Widget _buildListCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          spacing: 16,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: AppColors.primaryColor, size: 24,),),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(title, style: AppTextStyles.tileTitleTextStyle),
                  Text(subtitle, style: AppTextStyles.smallTextStyle.copyWith(color: AppColors.unSelectedGreyColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCardsSection(BuildContext context, AppLocalizations l10n) {
    return Row(
      spacing: 10,
      children: [
        Expanded(child: _buildBottomCard(Icons.confirmation_number, l10n.coupons, l10n.viewCoupons, (){}),),
        Expanded(child: _buildBottomCard(Icons.casino, l10n.wheelOfFortune, l10n.spinToWin, ()=> context.push(RouterEnum.wheelOfFortuneView.routeName)),),
      ],
    );
  }

  Widget _buildBottomCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        alignment: Alignment.center,
        height: 90,
        decoration: BoxDecoration(color: AppColors.cardBgColor, borderRadius: BorderRadius.circular(12),),
        child: Row(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.primaryColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20),),
              child: Icon(icon, color: AppColors.primaryColor, size: 20,),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 2,
                children: [
                  Text(title, style: AppTextStyles.smallTextStyle.copyWith(fontWeight: FontWeight.w700)),
                  Text(subtitle, style: AppTextStyles.captionTextStyle.copyWith(color: AppColors.unSelectedGreyColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
