import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/reward_redemption_model.dart';
import '../providers/reward_provider.dart';
import '../res/app_colors.dart';
import '../res/apptextstyles.dart';
import '../routes/router_enum.dart';
import '../../../l10n/app_localizations.dart';

class MyRewardsPage extends StatefulWidget {
  const MyRewardsPage({super.key});

  @override
  State<MyRewardsPage> createState() => _MyRewardsPageState();
}

class _MyRewardsPageState extends State<MyRewardsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (_userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<RewardProvider>().initialize(_userId!);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, l10n),
            
            // Tab bar
            _buildTabBar(),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildActiveRewardsTab(),
                  _buildUsedRewardsTab(),
                  _buildExpiredRewardsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.whiteColor,
              size: 24,
            ),
          ),
          Expanded(
            child: Text(
              'My Rewards',
              textAlign: TextAlign.center,
              style: AppTextStyles.subHeadingTextStyle,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: AppColors.whiteColor,
        unselectedLabelColor: AppColors.lightGreyColor,
        labelStyle: AppTextStyles.smallBoldTextStyle,
        unselectedLabelStyle: AppTextStyles.smallTextStyle,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(text: 'Active'),
          Tab(text: 'Used'),
          Tab(text: 'Expired'),
        ],
      ),
    );
  }

  Widget _buildActiveRewardsTab() {
    return Consumer<RewardProvider>(
      builder: (context, rewardProvider, child) {
        if (rewardProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          );
        }

        final activeRedemptions = rewardProvider.activeRedemptions;

        if (activeRedemptions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 16,
              children: [
                Icon(
                  Icons.card_giftcard_outlined,
                  color: AppColors.lightGreyColor,
                  size: 48,
                ),
                Text(
                  'No active rewards',
                  style: AppTextStyles.subHeadingTextStyle,
                ),
                Text(
                  'Redeem your first reward to see it here!',
                  style: AppTextStyles.smallTextStyle,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.push(RouterEnum.rewardsView.routeName),
                  child: const Text('Browse Rewards'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => rewardProvider.refresh(),
          color: AppColors.primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeRedemptions.length,
            itemBuilder: (context, index) {
              final redemption = activeRedemptions[index];
              return _buildActiveRewardCard(redemption);
            },
          ),
        );
      },
    );
  }

  Widget _buildUsedRewardsTab() {
    return Consumer<RewardProvider>(
      builder: (context, rewardProvider, child) {
        if (rewardProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          );
        }

        final usedRedemptions = rewardProvider.usedRedemptions;

        if (usedRedemptions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 16,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.lightGreyColor,
                  size: 48,
                ),
                Text(
                  'No used rewards',
                  style: AppTextStyles.subHeadingTextStyle,
                ),
                Text(
                  'Your used rewards will appear here.',
                  style: AppTextStyles.smallTextStyle,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => rewardProvider.refresh(),
          color: AppColors.primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: usedRedemptions.length,
            itemBuilder: (context, index) {
              final redemption = usedRedemptions[index];
              return _buildUsedRewardCard(redemption);
            },
          ),
        );
      },
    );
  }

  Widget _buildExpiredRewardsTab() {
    return Consumer<RewardProvider>(
      builder: (context, rewardProvider, child) {
        if (rewardProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          );
        }

        final expiredRedemptions = rewardProvider.expiredRedemptions;

        if (expiredRedemptions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 16,
              children: [
                Icon(
                  Icons.schedule_outlined,
                  color: AppColors.lightGreyColor,
                  size: 48,
                ),
                Text(
                  'No expired rewards',
                  style: AppTextStyles.subHeadingTextStyle,
                ),
                Text(
                  'Expired rewards will appear here.',
                  style: AppTextStyles.smallTextStyle,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => rewardProvider.refresh(),
          color: AppColors.primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: expiredRedemptions.length,
            itemBuilder: (context, index) {
              final redemption = expiredRedemptions[index];
              return _buildExpiredRewardCard(redemption);
            },
          ),
        );
      },
    );
  }

  Widget _buildActiveRewardCard(RewardRedemption redemption) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        spacing: 12,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Reward #${redemption.id.substring(0, 8)}',
                  style: AppTextStyles.rewardTitleStyle,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Active',
                  style: AppTextStyles.smallTextStyle.copyWith(
                    color: AppColors.successColor,
                  ),
                ),
              ),
            ],
          ),
          
          // Redemption code
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              spacing: 8,
              children: [
                Text(
                  'Redemption Code',
                  style: AppTextStyles.smallTextStyle.copyWith(
                    color: AppColors.primaryColor,
                  ),
                ),
                Text(
                  redemption.redemptionCode,
                  style: AppTextStyles.subHeadingTextStyle.copyWith(
                    color: AppColors.primaryColor,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          
          // Delivery Address (for physical rewards)
          if (redemption.deliveryAddress != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.borderColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        color: AppColors.primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Delivery Address',
                        style: AppTextStyles.smallBoldTextStyle.copyWith(
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    redemption.deliveryAddress!.fullAddress,
                    style: AppTextStyles.smallTextStyle,
                  ),
                  if (redemption.deliveryAddress!.phoneNumber != null)
                    Text(
                      'Phone: ${redemption.deliveryAddress!.phoneNumber}',
                      style: AppTextStyles.smallTextStyle.copyWith(
                        color: AppColors.lightGreyColor,
                      ),
                    ),
                ],
              ),
            ),
          
          // Tracking Number (if shipped)
          if (redemption.trackingNumber != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.successColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_shipping,
                    color: AppColors.successColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tracking Number',
                          style: AppTextStyles.smallTextStyle.copyWith(
                            color: AppColors.successColor,
                          ),
                        ),
                        Text(
                          redemption.trackingNumber!,
                          style: AppTextStyles.smallBoldTextStyle.copyWith(
                            color: AppColors.successColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Redeemed for ${redemption.pointsSpent} points',
                style: AppTextStyles.smallTextStyle,
              ),
              if (redemption.expiresAt != null)
                Text(
                  'Expires: ${_formatDate(redemption.expiresAt!)}',
                  style: AppTextStyles.smallTextStyle.copyWith(
                    color: AppColors.orangeColor,
                  ),
                ),
            ],
          ),
          
          // QR Code button
          if (redemption.qrCodeData != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showQRCode(redemption),
                icon: const Icon(Icons.qr_code, size: 20),
                label: const Text('Show QR Code'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                  side: BorderSide(color: AppColors.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          
          // Use button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _useReward(redemption),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Use Now'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsedRewardCard(RewardRedemption redemption) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.darkGreyColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        spacing: 12,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Reward #${redemption.id.substring(0, 8)}',
                  style: AppTextStyles.rewardTitleStyle.copyWith(
                    color: AppColors.lightGreyColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.darkGreyColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Used',
                  style: AppTextStyles.smallTextStyle.copyWith(
                    color: AppColors.lightGreyColor,
                  ),
                ),
              ),
            ],
          ),
          
          // Redemption code (crossed out)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.darkGreyColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              spacing: 8,
              children: [
                Text(
                  'Redemption Code',
                  style: AppTextStyles.smallTextStyle.copyWith(
                    color: AppColors.lightGreyColor,
                  ),
                ),
                Text(
                  redemption.redemptionCode,
                  style: AppTextStyles.subHeadingTextStyle.copyWith(
                    color: AppColors.lightGreyColor,
                    letterSpacing: 2,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ),
          
          // Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Redeemed for ${redemption.pointsSpent} points',
                style: AppTextStyles.smallTextStyle.copyWith(
                  color: AppColors.lightGreyColor,
                ),
              ),
              if (redemption.claimedAt != null)
                Text(
                  'Used: ${_formatDate(redemption.claimedAt!)}',
                  style: AppTextStyles.smallTextStyle.copyWith(
                    color: AppColors.lightGreyColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredRewardCard(RewardRedemption redemption) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.errorColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        spacing: 12,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Reward #${redemption.id.substring(0, 8)}',
                  style: AppTextStyles.rewardTitleStyle.copyWith(
                    color: AppColors.lightGreyColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Expired',
                  style: AppTextStyles.smallTextStyle.copyWith(
                    color: AppColors.errorColor,
                  ),
                ),
              ),
            ],
          ),
          
          // Redemption code (crossed out)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              spacing: 8,
              children: [
                Text(
                  'Redemption Code',
                  style: AppTextStyles.smallTextStyle.copyWith(
                    color: AppColors.errorColor,
                  ),
                ),
                Text(
                  redemption.redemptionCode,
                  style: AppTextStyles.subHeadingTextStyle.copyWith(
                    color: AppColors.errorColor,
                    letterSpacing: 2,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ),
          
          // Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Redeemed for ${redemption.pointsSpent} points',
                style: AppTextStyles.smallTextStyle.copyWith(
                  color: AppColors.lightGreyColor,
                ),
              ),
              if (redemption.expiresAt != null)
                Text(
                  'Expired: ${_formatDate(redemption.expiresAt!)}',
                  style: AppTextStyles.smallTextStyle.copyWith(
                    color: AppColors.errorColor,
                  ),
                ),
            ],
          ),
          
          // Expired notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.errorColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.errorColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This reward has expired and can no longer be used.',
                    style: AppTextStyles.smallTextStyle.copyWith(
                      color: AppColors.errorColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQRCode(RewardRedemption redemption) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBgColor,
        title: Text(
          'QR Code',
          style: AppTextStyles.subHeadingTextStyle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                spacing: 12,
                children: [
                  // TODO: Add QR code widget here
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.lightGreyColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code,
                      size: 100,
                      color: AppColors.darkGreyColor,
                    ),
                  ),
                  Text(
                    'Scan this QR code at the merchant',
                    style: AppTextStyles.smallTextStyle.copyWith(
                      color: AppColors.darkGreyColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Text(
              'Code: ${redemption.redemptionCode}',
              style: AppTextStyles.smallBoldTextStyle.copyWith(
                color: AppColors.primaryColor,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Close',
              style: AppTextStyles.smallTextStyle.copyWith(
                color: AppColors.lightGreyColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _useReward(RewardRedemption redemption) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBgColor,
        title: Text(
          'Use Reward',
          style: AppTextStyles.subHeadingTextStyle,
        ),
        content: Text(
          'Are you sure you want to use this reward? This action cannot be undone.',
          style: AppTextStyles.smallTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.smallTextStyle.copyWith(
                color: AppColors.lightGreyColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.whiteColor,
            ),
            child: const Text('Use Now'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final rewardProvider = context.read<RewardProvider>();
      final success = await rewardProvider.useReward(redemption.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reward used successfully!'),
            backgroundColor: AppColors.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to use reward. Please try again.'),
            backgroundColor: AppColors.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
