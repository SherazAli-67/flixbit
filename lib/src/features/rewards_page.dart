import 'package:flutter/material.dart';
import '../res/app_colors.dart';
import '../res/apptextstyles.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 26,
            children: [
              // Header
              _buildHeader(context),
              
              // Available Rewards Section
              _buildAvailableRewardsSection(),
              
              // Claimed Rewards Section
              _buildClaimedRewardsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.whiteColor,
            size: 24,
          ),
        ),
        const Expanded(
          child: Text(
            'Rewards',
            textAlign: TextAlign.center,
            style: AppTextStyles.subHeadingTextStyle,
          ),
        ),
        const SizedBox(width: 48), // Balance the back button
      ],
    );
  }

  Widget _buildAvailableRewardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        const Text(
          'Available Rewards',
          style: AppTextStyles.subHeadingTextStyle,
        ),
        Column(
          spacing: 16,
          children: [
            _buildRewardCard(
              'Expires in 30 days',
              '20% off at The Coffee Bean',
              'Enjoy a 20% discount on your next purchase.',
              'asset/images/coffee_shop.jpg',
              'Claim',
              true,
            ),
            _buildRewardCard(
              'Expires in 15 days',
              'Free Appetizer at The Grill',
              'Get a complimentary appetizer with your entree.',
              'asset/images/restaurant.jpg',
              'Claim',
              true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClaimedRewardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        const Text(
          'Claimed Rewards',
          style: AppTextStyles.subHeadingTextStyle,
        ),
        _buildRewardCard(
          null, // No expiry text for claimed rewards
          '10% off at The Bakery',
          'Enjoy a 10% discount on your next purchase.',
          'asset/images/bakery.jpg',
          'Redeemed',
          false,
        ),
      ],
    );
  }

  Widget _buildRewardCard(
    String? expiryText,
    String title,
    String description,
    String imagePath,
    String buttonText,
    bool isClaimable,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        spacing: 16,
        children: [
          // Left side - Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                if (expiryText != null)
                  Text(
                    expiryText,
                    style: AppTextStyles.expiryTextStyle,
                  ),
                Text(
                  title,
                  style: AppTextStyles.rewardTitleStyle,
                ),
                Text(
                  description,
                  style: AppTextStyles.rewardDescStyle,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: isClaimable ? () {
                    // Handle claim action
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isClaimable
                        ? AppColors.primaryColor
                        : AppColors.darkGreyColor,
                    foregroundColor: AppColors.whiteColor,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonText,
                    style: AppTextStyles.smallBoldTextStyle.copyWith(
                      color: isClaimable
                          ? AppColors.whiteColor
                          : AppColors.lightGreyColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Right side - Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.unSelectedGreyColor,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildPlaceholderImage(imagePath),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(String imagePath) {
    // Since we don't have actual images, we'll create placeholder containers
    // that represent the different types of establishments
    if (imagePath.contains('coffee_shop')) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff8B4513), Color(0xffD2691E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.local_cafe,
          color: AppColors.whiteColor,
          size: 40,
        ),
      );
    } else if (imagePath.contains('restaurant')) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff2E8B57), Color(0xff3CB371)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.restaurant,
          color: AppColors.whiteColor,
          size: 40,
        ),
      );
    } else if (imagePath.contains('bakery')) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffCD853F), Color(0xffDEB887)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.cake,
          color: AppColors.whiteColor,
          size: 40,
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.unSelectedGreyColor,
        ),
        child: const Icon(
          Icons.image,
          color: AppColors.whiteColor,
          size: 40,
        ),
      );
    }
  }
}