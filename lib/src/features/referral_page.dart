import 'package:flixbit/src/res/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../l10n/app_localizations.dart';
import '../config/points_config.dart';
import '../res/app_colors.dart';
import '../res/apptextstyles.dart';
import '../service/referral_service.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  final ReferralService _referralService = ReferralService();
  String? _referralCode;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _referredUsers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get referral code
      final code = await _referralService.getReferralCode('currentUser');
      if (code == null) {
        // Generate new code if none exists
        await _referralService.generateReferralCode('currentUser');
      }

      // Get referred users
      final users = await _referralService.getReferredUsers('currentUser');

      if (mounted) {
        setState(() {
          _referralCode = code;
          _referredUsers = users;
          _isLoading = false;
        });
      }

      // Subscribe to stats updates
      _referralService
          .getReferralStats('currentUser')
          .listen(
            (stats) {
              if (mounted) {
                setState(() => _stats = stats);
              }
            },
            onError: (e) {
              debugPrint('Error getting referral stats: $e');
            },
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _copyReferralCode() async {
    if (_referralCode == null) return;

    await Clipboard.setData(ClipboardData(text: _referralCode!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.whiteColor),
              const SizedBox(width: 8),
              Text('Referral code copied to clipboard'),
            ],
          ),
          backgroundColor: AppColors.successColor,
        ),
      );
    }
  }

  Future<void> _shareViaApp(String app) async {
    if (_referralCode == null) return;

    final message = 'Join Flixbit using my referral code: $_referralCode';
    // TODO: Implement sharing via specific apps
    debugPrint('Sharing via $app: $message');
  }

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
          'Share your referral code with friends and earn ${PointsConfig.getPoints("referral")} points for each friend who joins!',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyTextStyle.copyWith(
            color: AppColors.lightGreyColor,
          ),
        ),
        if (_referralCode != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Column(
              spacing: 12,
              children: [
                Text(
                  'Your Referral Code',
                  style: AppTextStyles.bodyTextStyle.copyWith(
                    color: AppColors.lightGreyColor,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _referralCode!,
                      style: AppTextStyles.headingTextStyle3.copyWith(
                        color: AppColors.primaryColor,
                        letterSpacing: 2,
                      ),
                    ),
                    IconButton(
                      onPressed: _copyReferralCode,
                      icon: Icon(
                        Icons.copy,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (_stats != null) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(
                'Total Referrals',
                _stats!['totalReferrals']?.toString() ?? '0',
                Icons.people_outline,
              ),
              _buildStatCard(
                'Active Friends',
                _stats!['activeReferrals']?.toString() ?? '0',
                Icons.person_add,
              ),
              _buildStatCard(
                'Points Earned',
                _stats!['pointsEarned']?.toString() ?? '0',
                Icons.star_outline,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        spacing: 8,
        children: [
          Icon(icon, color: AppColors.primaryColor),
          Text(
            value,
            style: AppTextStyles.headingTextStyle3.copyWith(
              color: AppColors.primaryColor,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.captionTextStyle.copyWith(
              color: AppColors.lightGreyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        const Text(
          'Share via',
          style: AppTextStyles.subHeadingTextStyle,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSocialIcon(
              'WhatsApp',
              AppIcons.icWhatsApp,
              onTap: () => _shareViaApp('whatsapp'),
            ),
            _buildSocialIcon(
              'Facebook',
              AppIcons.icFacebook,
              onTap: () => _shareViaApp('facebook'),
            ),
            _buildSocialIcon(
              'Telegram',
              AppIcons.icTelegram,
              onTap: () => _shareViaApp('telegram'),
            ),
            _buildSocialIcon(
              'Snapchat',
              AppIcons.icSnapchat,
              onTap: () => _shareViaApp('snapchat'),
            ),
            _buildSocialIcon(
              'Instagram',
              AppIcons.icInstagram,
              onTap: () => _shareViaApp('instagram'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _copyReferralCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.whiteColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.copy, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Copy Referral Code',
                  style: AppTextStyles.buttonTextStyle.copyWith(
                    color: AppColors.whiteColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_referralCode != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: AppColors.primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Friends get ${PointsConfig.getPoints("referral_welcome")} points welcome bonus!',
                    style: AppTextStyles.smallTextStyle.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSocialIcon(String name, String icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Column(
        spacing: 8,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(10),
            child: SvgPicture.asset(
              icon,
              colorFilter: ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn),
              height: 24,
            ),
          ),
          Text(
            name,
            style: AppTextStyles.captionTextStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildReferralStatusSection(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.errorColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error!,
                style: AppTextStyles.bodyTextStyle.copyWith(
                  color: AppColors.errorColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_referredUsers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          spacing: 16,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: AppColors.lightGreyColor,
            ),
            Text(
              'No referrals yet',
              style: AppTextStyles.bodyTextStyle.copyWith(
                color: AppColors.lightGreyColor,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Share your code to start earning points!',
              style: AppTextStyles.smallTextStyle.copyWith(
                color: AppColors.lightGreyColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Referral Status',
              style: AppTextStyles.subHeadingTextStyle,
            ),
            Text(
              '${_referredUsers.length} friends joined',
              style: AppTextStyles.bodyTextStyle.copyWith(
                color: AppColors.lightGreyColor,
              ),
            ),
          ],
        ),
        Column(
          spacing: 16,
          children: _referredUsers.map((user) {
            return _buildReferralFriend(
              user['name'] as String,
              'Joined',
              '+${PointsConfig.getPoints("referral")} pts',
              Icons.person,
            );
          }).toList(),
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