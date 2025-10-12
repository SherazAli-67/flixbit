import 'package:flixbit/src/res/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../l10n/app_localizations.dart';
import '../res/app_colors.dart';
import '../res/apptextstyles.dart';

class ReferralPage extends StatelessWidget {
  const ReferralPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 24,
            children: [
              // Header
              _buildHeader(context, l10n),
              
              // Main Illustration Card
              _buildIllustrationCard(l10n),
              
              // Invite and Earn Rewards Section
              _buildInviteSection(l10n),
              
              // Share Your Referral Link Section
              _buildShareSection(l10n),
              
              // Referral Status Section
              _buildReferralStatusSection(l10n),
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
            l10n.referrals,
            textAlign: TextAlign.center,
            style: AppTextStyles.subHeadingTextStyle,
          ),
        ),
        const SizedBox(width: 48), // Balance the back button
      ],
    );
  }

  Widget _buildIllustrationCard(AppLocalizations l10n) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(AppIcons.referralPageImg, fit: BoxFit.cover,));
  }

  Widget _buildInviteSection(AppLocalizations l10n) {
    return Column(
      spacing: 12,
      children: [
         Text(
          l10n.inviteFriends,
          textAlign: TextAlign.center,
          style: AppTextStyles.headingTextStyle3,
        ),
        Text(
          'Share your referral link with friends and earn rewards when they join and participate.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyTextStyle.copyWith(
            color: AppColors.lightGreyColor,
          ),
        ),
      ],
    );
  }

  Widget _buildShareSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        const Text(
          'Share your referral link',
          style: AppTextStyles.subHeadingTextStyle,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSocialIcon('WhatsApp', AppIcons.icWhatsApp),
            _buildSocialIcon('Facebook', AppIcons.icFacebook),
            _buildSocialIcon('Telegram', AppIcons.icTelegram),
            _buildSocialIcon('Snapchat', AppIcons.icSnapchat),
            _buildSocialIcon('Instagram', AppIcons.icInstagram),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Handle copy link action
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.whiteColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Copy Link',
              style: AppTextStyles.buttonTextStyle.copyWith(
                color: AppColors.whiteColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(String name, String icon) {
    return Column(
      spacing: 8,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          padding: EdgeInsets.all(10),
          child: SvgPicture.asset(icon, colorFilter: ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn,), height: 24,)
        ),
        Text(
          name,
          style: AppTextStyles.captionTextStyle,
        ),
      ],
    );
  }

  Widget _buildReferralStatusSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        const Text(
          'Referral Status',
          style: AppTextStyles.subHeadingTextStyle,
        ),
        Column(
          spacing: 16,
          children: [
            _buildReferralFriend(
              'Ethan Carter',
              'Joined',
              '+100 pts',
              Icons.person,
            ),
            _buildReferralFriend(
              'Sophia Clark',
              'Joined',
              '+100 pts',
              Icons.person,
            ),
            _buildReferralFriend(
              'Liam Walker',
              'Joined',
              '+100 pts',
              Icons.person,
            ),
            _buildReferralFriend(
              'Olivia Harris',
              'Joined',
              '+100 pts',
              Icons.person,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReferralFriend(String name, String status, String points, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        spacing: 16,
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(AppIcons.icDummyProfileUrl),
          ),

          
          // Name and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  name,
                  style: AppTextStyles.rewardTitleStyle,
                ),
                Text(
                  status,
                  style: AppTextStyles.rewardDescStyle,
                ),
              ],
            ),
          ),
          
          // Points
          Text(
            points,
            style: AppTextStyles.rewardTitleStyle.copyWith(
              color: AppColors.greenColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}