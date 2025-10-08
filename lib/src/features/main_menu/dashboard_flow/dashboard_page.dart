import 'package:flixbit/src/res/apptextstyles.dart';
import 'package:flixbit/src/routes/router_enum.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flixbit/src/models/video_ad.dart';
import '../../../res/app_colors.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                // Top Bar
                _buildTopBar(),

                // Media Section
                _buildMediaSection(),
                
                // Quick Access Section
                _buildQuickAccessSection(context),
                
                // List Cards Section
                _buildListCardsSection(context),


                // Bottom Cards Section
                _buildBottomCardsSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Dashboard',
          style: AppTextStyles.headingTextStyle3
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.2),
            // border: Border.all(color: AppColors.primaryColor, width: 1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.settings,
            color: AppColors.primaryColor,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildMediaSection() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xff2a3b45), Color(0xff1e2a32), ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        const Text(
          'Quick Access',
          style: AppTextStyles.subHeadingTextStyle
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 5,
          children: [
            _buildQuickAccessButton(Icons.card_giftcard, 'Offers', (){
              context.push(RouterEnum.offersView.routeName);
            }),
            _buildQuickAccessButton(Icons.wb_sunny, 'Gifts', (){}),
            _buildQuickAccessButton(Icons.account_tree, 'Rewards', (){
              context.push(RouterEnum.rewardsView.routeName);
            }),
            _buildQuickAccessButton(Icons.notifications, 'Notifications', (){}),
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

  Widget _buildListCardsSection(BuildContext context) {
    return Column(
      spacing: 20,
      children: [
        _buildListCard(Icons.sports_soccer, 'Game Predictions', 'Predict matches and win prizes', (){
          context.push(RouterEnum.gamePredictionView.routeName);
        }),
        _buildListCard(Icons.ondemand_video, 'Watch & Earn', 'Watch ads to earn Flixbit', (){
          // Navigate directly to VideoAdDetailPage with a sample ad
          final ad = VideoAd(
            id: 'video_1',
            title: 'Featured Seller Ad',
            mediaUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
            durationSeconds: 30,
            rewardPoints: 5,
            minWatchSeconds: 10,
          );
          context.push(
            RouterEnum.videoDetailsView.routeName,
            extra: {
              'ad': ad,
              'sellerId': 'seller_123',
            },
          );
        }),
        _buildListCard(Icons.stars, 'Subscription Packages', 'Upgrade for more features', (){
          context.push(RouterEnum.subscriptionView.routeName);
        }),
        _buildListCard(Icons.store, 'My Sellers', 'Manage your followed sellers', (){
          context.push(RouterEnum.mySellersView.routeName); // New route
        }),
        _buildListCard(Icons.people, 'Referrals', 'Invite friends and earn', (){
          context.push(RouterEnum.referralView.routeName);
        }),
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
              child: Icon(
                icon,
                color: AppColors.primaryColor,
                size: 24,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.tileTitleTextStyle
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.smallTextStyle.copyWith(color: AppColors.unSelectedGreyColor)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCardsSection(BuildContext context) {
    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: _buildBottomCard(Icons.confirmation_number, 'Coupons', 'View coupons', (){}),
        ),
        Expanded(
          child: _buildBottomCard(Icons.casino, 'Wheel of Fortune', 'Spin to win', (){
            context.push(RouterEnum.wheelOfFortuneView.routeName);
          }),
        ),
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
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryColor,
                size: 20,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 2,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.smallTextStyle.copyWith(fontWeight: FontWeight.w700)
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.captionTextStyle.copyWith(color: AppColors.unSelectedGreyColor)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
