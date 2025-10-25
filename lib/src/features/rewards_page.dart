import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/reward_model.dart';
import '../providers/reward_provider.dart';
import '../res/app_colors.dart';
import '../res/apptextstyles.dart';
import '../routes/router_enum.dart';
import '../../../l10n/app_localizations.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  String? _userId;
  late Size _size;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (_userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_)=> context.read<RewardProvider>().initialize(_userId!));
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
    _size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header with balance
            SliverToBoxAdapter(
              child: _buildHeader(context, l10n),
            ),
            
            // Tab bar
            SliverToBoxAdapter(
              child: _buildTabBar(),
            ),
            
            // Tab content
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAvailableRewardsTab(),
                  _buildMyRewardsTab(),
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
      child: Column(
        spacing: 16,
        children: [
          // Top row with back button and title
          Row(
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
                  l10n.rewards,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subHeadingTextStyle,
                ),
              ),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),
          
          // Balance card
          Consumer<RewardProvider>(
            builder: (context, rewardProvider, child) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor.withValues(alpha: 0.8),
                      AppColors.primaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Flixbit Balance',
                          style: AppTextStyles.smallTextStyle.copyWith(
                            color: AppColors.whiteColor.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${rewardProvider.userBalance}',
                          style: AppTextStyles.headingTextStyle.copyWith(
                            color: AppColors.whiteColor,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.whiteColor,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
       /* indicator: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),*/
        labelColor: AppColors.whiteColor,
        unselectedLabelColor: AppColors.lightGreyColor,
        labelStyle: AppTextStyles.smallBoldTextStyle,
        unselectedLabelStyle: AppTextStyles.smallTextStyle,
        tabs: const [
          Tab(text: 'Available Rewards'),
          Tab(text: 'My Rewards'),
        ],
      ),
    );
  }

  Widget _buildAvailableRewardsTab() {
    return Consumer<RewardProvider>(
      builder: (context, rewardProvider, child) {
        if (rewardProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          );
        }

        if (rewardProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 16,
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.errorColor,
                  size: 48,
                ),
                Text(
                  rewardProvider.error!,
                  style: AppTextStyles.smallTextStyle,
                  textAlign: TextAlign.center,
                ),
                ElevatedButton(
                  onPressed: () => rewardProvider.refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (rewardProvider.availableRewards.isEmpty) {
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
                  'No rewards available',
                  style: AppTextStyles.subHeadingTextStyle,
                ),
                Text(
                  'Check back later for new rewards!',
                  style: AppTextStyles.smallTextStyle,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => rewardProvider.refresh(),
          color: AppColors.primaryColor,
          child: CustomScrollView(
            slivers: [
              // Filters
              SliverToBoxAdapter(
                child: _buildFilters(rewardProvider),
              ),
              
              // Recommended section (if user has balance)
              if (rewardProvider.userBalance > 0 && rewardProvider.recommendedRewards.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildRecommendedSection(rewardProvider),
                ),
              
              // Rewards list
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final reward = rewardProvider.availableRewards[index];
                      return _buildRewardCard(reward, rewardProvider);
                    },
                    childCount: rewardProvider.availableRewards.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters(RewardProvider rewardProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 12,
        children: [
          // Category filter chips
          if (rewardProvider.availableCategories.isNotEmpty) ...[
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: rewardProvider.availableCategories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: rewardProvider.selectedCategory == null,
                        onSelected: (selected) {
                          if (selected) {
                            rewardProvider.setCategoryFilter(null);
                          }
                        },
                        selectedColor: AppColors.primaryColor.withValues(alpha: 0.3),
                        checkmarkColor: AppColors.primaryColor,
                      ),
                    );
                  }
                  
                  final category = rewardProvider.availableCategories[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_getCategoryDisplayName(category)),
                      selected: rewardProvider.selectedCategory == category,
                      onSelected: (selected) {
                        rewardProvider.setCategoryFilter(selected ? category : null);
                      },
                      selectedColor: AppColors.primaryColor.withValues(alpha: 0.3),
                      checkmarkColor: AppColors.primaryColor,
                    ),
                  );
                },
              ),
            ),
          ],
          
          // Sort dropdown
          Row(
            children: [
              const Text('Sort by:', style: AppTextStyles.smallTextStyle),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: rewardProvider.sortBy,
                onChanged: (value) {
                  if (value != null) {
                    rewardProvider.setSortBy(value);
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'featured', child: Text('Featured')),
                  DropdownMenuItem(value: 'pointsCost', child: Text('Price: Low to High')),
                  DropdownMenuItem(value: 'createdAt', child: Text('Newest')),
                ],
                underline: Container(),
                dropdownColor: AppColors.cardBgColor,
                style: AppTextStyles.smallTextStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(Reward reward, RewardProvider rewardProvider) {
    final canAfford = rewardProvider.canAffordReward(reward);
    final hasReachedLimit = rewardProvider.hasReachedRedemptionLimit(reward);
    final canRedeem = canAfford && !hasReachedLimit && reward.canBeRedeemed;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: reward.isFeatured 
            ? Border.all(color: AppColors.primaryColor.withValues(alpha: 0.5), width: 1)
            : null,
      ),
      child: Column(
        spacing: 12,
        children: [
          // Header row
          Row(
            children: [
              if (reward.isFeatured)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'FEATURED',
                    style: AppTextStyles.smallBoldTextStyle.copyWith(
                      color: AppColors.whiteColor,
                      fontSize: 10,
                    ),
                  ),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(reward.category).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getCategoryDisplayName(reward.category),
                  style: AppTextStyles.smallTextStyle.copyWith(
                    color: _getCategoryColor(reward.category),
                  ),
                ),
              ),
            ],
          ),

          // Content row
          Row(
            spacing: 16,
            children: [
              // Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _getCategoryColor(reward.category).withValues(alpha: 0.1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: reward.imageUrl != null
                      ? Image.network(
                          reward.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(reward.category),
                        )
                      : _buildPlaceholderIcon(reward.category),
                ),
              ),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Text(
                      reward.title,
                      style: AppTextStyles.rewardTitleStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      reward.description,
                      style: AppTextStyles.rewardDescStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Stock status
                    if (!reward.isInStock)
                      Text(
                        'Out of Stock',
                        style: AppTextStyles.smallTextStyle.copyWith(
                          color: AppColors.errorColor,
                        ),
                      )
                    else if (reward.stockQuantity <= 5)
                      Text(
                        'Only ${reward.stockQuantity} left!',
                        style: AppTextStyles.smallTextStyle.copyWith(
                          color: AppColors.orangeColor,
                        ),
                      ),

                    // Points cost and button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${reward.pointsCost} points',
                            style: AppTextStyles.smallBoldTextStyle.copyWith(
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: canRedeem ? () => _navigateToRewardDetail(reward.id) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canRedeem
                                ? AppColors.primaryColor
                                : AppColors.darkGreyColor,
                            foregroundColor: AppColors.whiteColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Text(
                            _getButtonText(canAfford, hasReachedLimit, reward),
                            style: AppTextStyles.smallBoldTextStyle.copyWith(
                              color: canRedeem
                                  ? AppColors.whiteColor
                                  : AppColors.lightGreyColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyRewardsTab() {
    return Consumer<RewardProvider>(
      builder: (context, rewardProvider, child) {
        if (rewardProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          );
        }

        if (rewardProvider.userRedemptions.isEmpty) {
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
                  'No rewards redeemed yet',
                  style: AppTextStyles.subHeadingTextStyle,
                ),
                Text(
                  'Start earning points and redeem your first reward!',
                  style: AppTextStyles.smallTextStyle,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(0),
                  child: const Text('Browse Rewards'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => rewardProvider.refresh(),
          color: AppColors.primaryColor,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final redemption = rewardProvider.userRedemptions[index];
                      return _buildRedemptionCard(redemption);
                    },
                    childCount: rewardProvider.userRedemptions.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRedemptionCard(dynamic redemption) {
    // This will be implemented when we create the redemption model
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reward #${redemption.id.substring(0, 8)}',
                style: AppTextStyles.rewardTitleStyle,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(redemption.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  redemption.statusText,
                  style: AppTextStyles.smallTextStyle.copyWith(
                    color: _getStatusColor(redemption.status),
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Redeemed for ${redemption.pointsSpent} points',
            style: AppTextStyles.smallTextStyle,
          ),
          Text(
            'Code: ${redemption.redemptionCode}',
            style: AppTextStyles.smallBoldTextStyle.copyWith(
              color: AppColors.primaryColor,
            ),
          ),
          if (redemption.expiresAt != null)
            Text(
              'Expires: ${_formatDate(redemption.expiresAt)}',
              style: AppTextStyles.smallTextStyle.copyWith(
                color: AppColors.lightGreyColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon(RewardCategory category) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getCategoryColor(category).withValues(alpha: 0.8),
            _getCategoryColor(category),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        _getCategoryIcon(category),
        color: AppColors.whiteColor,
        size: 40,
      ),
    );
  }

  void _navigateToRewardDetail(String rewardId) {
    context.push('${RouterEnum.rewardDetailView.routeName}?rewardId=$rewardId');
  }

  String _getButtonText(bool canAfford, bool hasReachedLimit, Reward reward) {
    if (!reward.canBeRedeemed) return 'Unavailable';
    if (hasReachedLimit) return 'Limit Reached';
    if (!canAfford) return 'Insufficient Points';
    return 'Redeem';
  }

  String _getCategoryDisplayName(RewardCategory category) {
    switch (category) {
      case RewardCategory.voucher:
        return 'Voucher';
      case RewardCategory.coupon:
        return 'Coupon';
      case RewardCategory.merchandise:
        return 'Merchandise';
      case RewardCategory.electronics:
        return 'Electronics';
      case RewardCategory.giftCard:
        return 'Gift Card';
      case RewardCategory.experience:
        return 'Experience';
      case RewardCategory.food:
        return 'Food';
      case RewardCategory.entertainment:
        return 'Entertainment';
      case RewardCategory.travel:
        return 'Travel';
      case RewardCategory.fashion:
        return 'Fashion';
      case RewardCategory.health:
        return 'Health';
      case RewardCategory.sports:
        return 'Sports';
    }
  }

  Color _getCategoryColor(RewardCategory category) {
    switch (category) {
      case RewardCategory.voucher:
        return Colors.blue;
      case RewardCategory.coupon:
        return Colors.green;
      case RewardCategory.merchandise:
        return Colors.orange;
      case RewardCategory.electronics:
        return Colors.purple;
      case RewardCategory.giftCard:
        return Colors.red;
      case RewardCategory.experience:
        return Colors.teal;
      case RewardCategory.food:
        return Colors.brown;
      case RewardCategory.entertainment:
        return Colors.pink;
      case RewardCategory.travel:
        return Colors.cyan;
      case RewardCategory.fashion:
        return Colors.indigo;
      case RewardCategory.health:
        return Colors.lightGreen;
      case RewardCategory.sports:
        return Colors.deepOrange;
    }
  }

  IconData _getCategoryIcon(RewardCategory category) {
    switch (category) {
      case RewardCategory.voucher:
        return Icons.receipt;
      case RewardCategory.coupon:
        return Icons.local_offer;
      case RewardCategory.merchandise:
        return Icons.shopping_bag;
      case RewardCategory.electronics:
        return Icons.devices;
      case RewardCategory.giftCard:
        return Icons.card_giftcard;
      case RewardCategory.experience:
        return Icons.explore;
      case RewardCategory.food:
        return Icons.restaurant;
      case RewardCategory.entertainment:
        return Icons.movie;
      case RewardCategory.travel:
        return Icons.flight;
      case RewardCategory.fashion:
        return Icons.checkroom;
      case RewardCategory.health:
        return Icons.favorite;
      case RewardCategory.sports:
        return Icons.sports;
    }
  }

  Color _getStatusColor(dynamic status) {
    // This will be implemented when we have the redemption model
    return AppColors.primaryColor;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildRecommendedSection(RewardProvider rewardProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: AppColors.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recommended for You',
                style: AppTextStyles.bodyTextStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          Text(
            'Based on your ${rewardProvider.userBalance} points balance',
            style: AppTextStyles.smallTextStyle.copyWith(
              color: AppColors.lightGreyColor,
            ),
          ),
          SizedBox(
            height: _size.height*0.27, // Fixed height for horizontal scroll
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: rewardProvider.recommendedRewards.length,
              itemBuilder: (context, index) {
                final reward = rewardProvider.recommendedRewards[index];
                return Container(
                  width: _size.width*0.8,
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildRecommendedRewardCard(reward, rewardProvider),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedRewardCard(Reward reward, RewardProvider rewardProvider) {
    final canAfford = rewardProvider.canAffordReward(reward);
    final hasReachedLimit = rewardProvider.hasReachedRedemptionLimit(reward);
    final canRedeem = canAfford && !hasReachedLimit && reward.canBeRedeemed;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: reward.isFeatured 
            ? Border.all(color: AppColors.primaryColor.withValues(alpha: 0.5), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          // Image
          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _getCategoryColor(reward.category).withValues(alpha: 0.1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: reward.imageUrl != null
                  ? Image.network(
                      reward.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(reward.category),
                    )
                  : _buildPlaceholderIcon(reward.category),
            ),
          ),

          // Title
          Text(
            reward.title,
            style: AppTextStyles.smallBoldTextStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Points cost
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${reward.pointsCost} points',
              style: AppTextStyles.smallTextStyle.copyWith(
                color: AppColors.primaryColor,
                fontSize: 10,
              ),
            ),
          ),

          // Redeem button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canRedeem ? () => _navigateToRewardDetail(reward.id) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canRedeem
                    ? AppColors.primaryColor
                    : AppColors.darkGreyColor,
                foregroundColor: AppColors.whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 6),
              ),
              child: Text(
                _getButtonText(canAfford, hasReachedLimit, reward),
                style: AppTextStyles.smallTextStyle.copyWith(
                  color: canRedeem
                      ? AppColors.whiteColor
                      : AppColors.lightGreyColor,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}