import 'package:flixbit/src/routes/router_enum.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../res/app_colors.dart';
import '../res/apptextstyles.dart';
import '../../../l10n/app_localizations.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 26,
            children: [
              // Header
              _buildHeader(context, l10n),

              // Available Rewards Section
              _buildAvailableRewardsSection(l10n),

              // Claimed Rewards Section
              _buildClaimedRewardsSection(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
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
        Expanded(
          child: Text(
            l10n.rewards,
            textAlign: TextAlign.center,
            style: AppTextStyles.subHeadingTextStyle,
          ),
        ),
        const SizedBox(width: 48), // Balance the back button
      ],
    );
  }

  Widget _buildAvailableRewardsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Text(
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

  Widget _buildClaimedRewardsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Text(
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
                  onPressed: isClaimable ? () async {
                    // await _claimReward(rewardId);

                    // Show review prompt after successful redemption
                    _showReviewPrompt('1', '1');
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

  void _showReviewPrompt(String sellerId, String offerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How was your experience?'),
        content: const Text('Rate your experience and earn Flixbit points!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              context.push(RouterEnum.writeReviewView.routeName, extra: {
                'sellerId': sellerId,
                'offerId': offerId,
                'sellerName' : 'Sheraz',
                'verificationMethod': 'offer_redemption',
              });

            },
            child: const Text('Write Review'),
          ),
        ],
      ),
    );
  }
}