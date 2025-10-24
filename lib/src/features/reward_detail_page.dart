import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/reward_model.dart';
import '../models/reward_redemption_model.dart';
import '../providers/reward_provider.dart';
import '../res/app_colors.dart';
import '../res/apptextstyles.dart';

class RewardDetailPage extends StatefulWidget {
  final String rewardId;

  const RewardDetailPage({
    super.key,
    required this.rewardId,
  });

  @override
  State<RewardDetailPage> createState() => _RewardDetailPageState();
}

class _RewardDetailPageState extends State<RewardDetailPage> {
  Reward? _reward;
  bool _isLoading = true;
  String? _error;
  bool _isRedeeming = false;

  @override
  void initState() {
    super.initState();
    _loadReward();
  }

  Future<void> _loadReward() async {
    try {
      final rewardProvider = context.read<RewardProvider>();
      final reward = await rewardProvider.getRewardById(widget.rewardId);
      
      if (mounted) {
        setState(() {
          _reward = reward;
          _isLoading = false;
          _error = reward == null ? 'Reward not found' : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load reward: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              )
            : _error != null
                ? _buildErrorState()
                : _reward != null
                    ? _buildRewardDetail()
                    : _buildNotFoundState(),
      ),
    );
  }

  Widget _buildErrorState() {
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
            _error!,
            style: AppTextStyles.subHeadingTextStyle,
            textAlign: TextAlign.center,
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadReward();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
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
            'Reward not found',
            style: AppTextStyles.subHeadingTextStyle,
          ),
          Text(
            'This reward may have been removed or is no longer available.',
            style: AppTextStyles.smallTextStyle,
            textAlign: TextAlign.center,
          ),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardDetail() {
    return Consumer<RewardProvider>(
      builder: (context, rewardProvider, child) {
        final canAfford = rewardProvider.canAffordReward(_reward!);
        final hasReachedLimit = rewardProvider.hasReachedRedemptionLimit(_reward!);
        final canRedeem = canAfford && !hasReachedLimit && _reward!.canBeRedeemed;

        return Column(
          children: [
            // Header
            _buildHeader(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  spacing: 24,
                  children: [
                    // Image and basic info
                    _buildImageAndInfo(),
                    
                    // Description
                    _buildDescription(),
                    
                    // Terms and conditions
                    if (_reward!.termsAndConditions.isNotEmpty)
                      _buildTermsAndConditions(),
                    
                    // Delivery info (for physical rewards)
                    if (_reward!.deliveryInfo != null)
                      _buildDeliveryInfo(),
                    
                    // Stock and availability
                    _buildAvailabilityInfo(),
                    
                    // Redemption limit info
                    if (_reward!.maxRedemptionsPerUser != null)
                      _buildRedemptionLimitInfo(rewardProvider),
                  ],
                ),
              ),
            ),
            
            // Bottom action bar
            _buildBottomActionBar(canRedeem, rewardProvider),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              'Reward Details',
              textAlign: TextAlign.center,
              style: AppTextStyles.subHeadingTextStyle,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildImageAndInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        spacing: 16,
        children: [
          // Image
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _getCategoryColor(_reward!.category).withValues(alpha: 0.1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _reward!.imageUrl != null
                  ? Image.network(
                      _reward!.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
          ),
          
          // Title and category
          Column(
            spacing: 8,
            children: [
              Row(
                children: [
                  if (_reward!.isFeatured)
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(_reward!.category).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getCategoryDisplayName(_reward!.category),
                      style: AppTextStyles.smallTextStyle.copyWith(
                        color: _getCategoryColor(_reward!.category),
                      ),
                    ),
                  ),
                ],
              ),
              
              Text(
                _reward!.title,
                style: AppTextStyles.headingTextStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          
          // Points cost
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor.withValues(alpha: 0.8),
                  AppColors.primaryColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_reward!.pointsCost} Flixbit Points',
              style: AppTextStyles.subHeadingTextStyle.copyWith(
                color: AppColors.whiteColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(
            'Description',
            style: AppTextStyles.subHeadingTextStyle,
          ),
          Text(
            _reward!.description,
            style: AppTextStyles.smallTextStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(
            'Terms & Conditions',
            style: AppTextStyles.subHeadingTextStyle,
          ),
          ...(_reward!.termsAndConditions.map((term) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    term,
                    style: AppTextStyles.smallTextStyle,
                  ),
                ),
              ],
            ),
          ))),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    final deliveryInfo = _reward!.deliveryInfo!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(
            'Delivery Information',
            style: AppTextStyles.subHeadingTextStyle,
          ),
          if (deliveryInfo.estimatedDays != null)
            _buildInfoRow('Estimated Delivery', '${deliveryInfo.estimatedDays} days'),
          if (deliveryInfo.shippingCost != null)
            _buildInfoRow('Shipping Cost', '\$${deliveryInfo.shippingCost!.toStringAsFixed(2)}'),
          if (deliveryInfo.availableCountries.isNotEmpty)
            _buildInfoRow('Available Countries', deliveryInfo.availableCountries.join(', ')),
          if (deliveryInfo.shippingProvider != null)
            _buildInfoRow('Shipping Provider', deliveryInfo.shippingProvider!),
        ],
      ),
    );
  }

  Widget _buildAvailabilityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(
            'Availability',
            style: AppTextStyles.subHeadingTextStyle,
          ),
          _buildInfoRow('Status', _reward!.stockStatus),
          _buildInfoRow('Stock Available', '${_reward!.stockQuantity} items'),
          _buildInfoRow('Total Redemptions', '${_reward!.redemptionCount}'),
          if (_reward!.expiryDate != null)
            _buildInfoRow('Expires', _formatDate(_reward!.expiryDate!)),
        ],
      ),
    );
  }

  Widget _buildRedemptionLimitInfo(RewardProvider rewardProvider) {
    final userCount = rewardProvider.getUserRedemptionCount(_reward!.id);
    final limit = _reward!.maxRedemptionsPerUser!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(
            'Redemption Limit',
            style: AppTextStyles.subHeadingTextStyle,
          ),
          _buildInfoRow('Your Redemptions', '$userCount / $limit'),
          if (userCount >= limit)
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
                      'You have reached the maximum redemption limit for this reward.',
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

  Widget _buildBottomActionBar(bool canRedeem, RewardProvider rewardProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        border: Border(
          top: BorderSide(
            color: AppColors.darkGreyColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        spacing: 12,
        children: [
          // Balance info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Balance:',
                style: AppTextStyles.smallTextStyle,
              ),
              Text(
                '${rewardProvider.userBalance} points',
                style: AppTextStyles.smallBoldTextStyle.copyWith(
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          
          // Redeem button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canRedeem ? () => _showRedemptionDialog() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canRedeem 
                    ? AppColors.primaryColor 
                    : AppColors.darkGreyColor,
                foregroundColor: AppColors.whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isRedeeming
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.whiteColor,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _getButtonText(canRedeem, rewardProvider),
                      style: AppTextStyles.subHeadingTextStyle.copyWith(
                        color: canRedeem 
                            ? AppColors.whiteColor 
                            : AppColors.lightGreyColor,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.smallTextStyle.copyWith(
            color: AppColors.lightGreyColor,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.smallTextStyle,
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getCategoryColor(_reward!.category).withValues(alpha: 0.8),
            _getCategoryColor(_reward!.category),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        _getCategoryIcon(_reward!.category),
        color: AppColors.whiteColor,
        size: 80,
      ),
    );
  }

  void _showRedemptionDialog() {
    final rewardProvider = context.read<RewardProvider>();
    final newBalance = rewardProvider.userBalance - _reward!.pointsCost;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBgColor,
        title: Text(
          'Confirm Redemption',
          style: AppTextStyles.subHeadingTextStyle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Text(
              'Are you sure you want to redeem "${_reward!.title}"?',
              style: AppTextStyles.smallTextStyle,
              textAlign: TextAlign.center,
            ),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkBgColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                spacing: 8,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Current Balance:', style: AppTextStyles.smallTextStyle),
                      Text('${rewardProvider.userBalance} points', style: AppTextStyles.smallTextStyle),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cost:', style: AppTextStyles.smallTextStyle),
                      Text('-${_reward!.pointsCost} points', style: AppTextStyles.smallTextStyle.copyWith(color: AppColors.errorColor)),
                    ],
                  ),
                  const Divider(color: AppColors.darkGreyColor),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('New Balance:', style: AppTextStyles.smallBoldTextStyle),
                      Text('$newBalance points', style: AppTextStyles.smallBoldTextStyle.copyWith(color: AppColors.primaryColor)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.smallTextStyle.copyWith(color: AppColors.lightGreyColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              _redeemReward();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.whiteColor,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _redeemReward() async {
    setState(() => _isRedeeming = true);
    
    try {
      final rewardProvider = context.read<RewardProvider>();
      final redemption = await rewardProvider.redeemReward(
        rewardId: _reward!.id,
        deliveryAddress: _reward!.deliveryInfo?.requiresAddress == true 
            ? null // TODO: Collect delivery address for physical rewards
            : null,
      );
      
      if (redemption != null && mounted) {
        _showRedemptionSuccess(redemption);
      } else if (mounted) {
        _showError('Failed to redeem reward. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isRedeeming = false);
      }
    }
  }

  void _showRedemptionSuccess(RewardRedemption redemption) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBgColor,
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.successColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Redemption Successful!',
              style: AppTextStyles.subHeadingTextStyle,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Text(
              'You have successfully redeemed "${_reward!.title}"!',
              style: AppTextStyles.smallTextStyle,
              textAlign: TextAlign.center,
            ),
            
            Container(
              padding: const EdgeInsets.all(16),
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
                    'Your Redemption Code',
                    style: AppTextStyles.smallBoldTextStyle.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                  Text(
                    redemption.redemptionCode,
                    style: AppTextStyles.headingTextStyle.copyWith(
                      color: AppColors.primaryColor,
                      letterSpacing: 2,
                    ),
                  ),
                  if (redemption.expiresAt != null)
                    Text(
                      'Expires: ${_formatDate(redemption.expiresAt!)}',
                      style: AppTextStyles.smallTextStyle.copyWith(
                        color: AppColors.lightGreyColor,
                      ),
                    ),
                ],
              ),
            ),
            
            if (_reward!.rewardType == RewardType.digital)
              Text(
                'Show this code to the merchant to redeem your reward.',
                style: AppTextStyles.smallTextStyle.copyWith(
                  color: AppColors.lightGreyColor,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              context.pop();
              context.pop(); // Go back to rewards page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.whiteColor,
            ),
            child: const Text('View My Rewards'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getButtonText(bool canRedeem, RewardProvider rewardProvider) {
    if (!_reward!.canBeRedeemed) return 'Unavailable';
    if (rewardProvider.hasReachedRedemptionLimit(_reward!)) return 'Limit Reached';
    if (!rewardProvider.canAffordReward(_reward!)) return 'Insufficient Points';
    return 'Redeem Now';
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
