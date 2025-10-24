import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';
import '../../res/firebase_constants.dart';
import '../../models/reward_model.dart';

class AdminRewardsPage extends StatefulWidget {
  const AdminRewardsPage({super.key});

  @override
  State<AdminRewardsPage> createState() => _AdminRewardsPageState();
}

class _AdminRewardsPageState extends State<AdminRewardsPage> {
  bool _isUploading = false;
  String _statusMessage = '';
  int _uploadedCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        title: const Text('Admin - Rewards Management'),
        backgroundColor: AppColors.darkBgColor,
        foregroundColor: AppColors.whiteColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 24,
            children: [
              // Header Section
              _buildHeader(),
              
              // Upload Section
              _buildUploadSection(),
              
              // Status Section
              if (_statusMessage.isNotEmpty) _buildStatusSection(),
              
              // Instructions Section
              _buildInstructionsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
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
                Icons.admin_panel_settings,
                color: AppColors.primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Admin Rewards Management',
                style: AppTextStyles.headingTextStyle3,
              ),
            ],
          ),
          Text(
            'Upload sample rewards to test the rewards system',
            style: AppTextStyles.bodyTextStyle.copyWith(
              color: AppColors.lightGreyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Text(
            'Upload Sample Rewards',
            style: AppTextStyles.tileTitleTextStyle,
          ),
          Text(
            'This will create 10 sample rewards in Firebase for testing purposes.',
            style: AppTextStyles.bodyTextStyle.copyWith(
              color: AppColors.lightGreyColor,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadSampleRewards,
              icon: _isUploading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.cloud_upload),
              label: Text(
                _isUploading ? 'Uploading...' : 'Upload Rewards',
                style: AppTextStyles.buttonTextStyle.copyWith(
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _uploadedCount > 0 
          ? AppColors.greenColor.withValues(alpha: 0.1)
          : AppColors.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _uploadedCount > 0 
            ? AppColors.greenColor.withValues(alpha: 0.3)
            : AppColors.errorColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _uploadedCount > 0 ? Icons.check_circle : Icons.error,
            color: _uploadedCount > 0 ? AppColors.greenColor : AppColors.errorColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusMessage,
              style: AppTextStyles.bodyTextStyle.copyWith(
                color: _uploadedCount > 0 ? AppColors.greenColor : AppColors.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection() {
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
            'Instructions',
            style: AppTextStyles.tileTitleTextStyle,
          ),
          _buildInstructionItem(
            '1. Tap "Upload Rewards" to create 10 sample rewards',
            Icons.upload,
          ),
          _buildInstructionItem(
            '2. Rewards will be added to Firebase Firestore',
            Icons.cloud,
          ),
          _buildInstructionItem(
            '3. Go to Rewards page to test the system',
            Icons.card_giftcard,
          ),
          _buildInstructionItem(
            '4. Test redemption flow with sample rewards',
            Icons.shopping_cart,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.primaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyTextStyle.copyWith(
              color: AppColors.lightGreyColor,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _uploadSampleRewards() async {
    setState(() {
      _isUploading = true;
      _statusMessage = '';
      _uploadedCount = 0;
    });

    try {
      final sampleRewards = _generateSampleRewards();
      final firestore = FirebaseFirestore.instance;
      
      int successCount = 0;
      
      for (final reward in sampleRewards) {
        try {
          await firestore
              .collection(FirebaseConstants.rewardsCollection)
              .add(reward.toFirestore());
          successCount++;
        } catch (e) {
          debugPrint('Error uploading reward ${reward.title}: $e');
        }
      }

      setState(() {
        _uploadedCount = successCount;
        _statusMessage = successCount > 0
            ? 'Successfully uploaded $successCount rewards to Firebase!'
            : 'Failed to upload rewards. Please try again.';
      });

      if (successCount > 0) {
        // Show success snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$successCount rewards uploaded successfully!'),
              backgroundColor: AppColors.greenColor,
            ),
          );
        }
      }

    } catch (e) {
      setState(() {
        _statusMessage = 'Error uploading rewards: ${e.toString()}';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  List<Reward> _generateSampleRewards() {
    final now = DateTime.now();
    
    return [
      Reward(
        id: '',
        title: "Amazon \$50 Gift Card",
        description: 'Digital gift card for Amazon.com. Use for any purchase on Amazon.',
        pointsCost: 1000,
        category: RewardCategory.giftCard,
        rewardType: RewardType.digital,
        imageUrl: 'https://images.unsplash.com/photo-1607082349566-187342175e2f?w=400',
        stockQuantity: 100,
        isActive: true,
        termsAndConditions: ['Valid for 90 days from redemption. Cannot be combined with other offers.'],
        expiryDate: now.add(const Duration(days: 90)),
        createdAt: now,
        updatedAt: now,
      ),
      
      Reward(
        id: '',
        title: "Starbucks \$10 Voucher",
        description: 'Coffee voucher for Starbucks. Perfect for your morning coffee!',
        pointsCost: 200,
        category: RewardCategory.food,
        rewardType: RewardType.digital,
        imageUrl: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400',
        stockQuantity: 500,
        isActive: true,
        termsAndConditions: ['Valid for 30 days. Can be used at any Starbucks location.'],
        expiryDate: now.add(const Duration(days: 30)),
        createdAt: now,
        updatedAt: now,
      ),
      
      Reward(
        id: '',
        title: 'Netflix 1 Month Subscription',
        description: 'One month of Netflix Premium subscription. Enjoy unlimited movies and shows.',
        pointsCost: 800,
        category: RewardCategory.entertainment,
        rewardType: RewardType.digital,
        imageUrl: 'https://images.unsplash.com/photo-1574375927938-d5a98e8ffe85?w=400',
        stockQuantity: 50,
        isActive: true,
        termsAndConditions: ['New subscribers only. Valid for 60 days from redemption.'],
        expiryDate: now.add(const Duration(days: 60)),
        createdAt: now,
        updatedAt: now,
      ),
      
      Reward(
        id: '',
        title: "Uber \$20 Credit",
        description: 'Ride credit for Uber. Use for rides or food delivery.',
        pointsCost: 400,
        category: RewardCategory.voucher,
        rewardType: RewardType.digital,
        imageUrl: 'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=400',
        stockQuantity: 200,
        isActive: true,
        termsAndConditions: ['Valid for 45 days. Cannot be transferred to other accounts.'],
        expiryDate: now.add(const Duration(days: 45)),
        createdAt: now,
        updatedAt: now,
      ),
      
      Reward(
        id: '',
        title: 'Apple AirPods Pro',
        description: 'Brand new Apple AirPods Pro with active noise cancellation.',
        pointsCost: 5000,
        category: RewardCategory.electronics,
        rewardType: RewardType.physical,
        imageUrl: 'https://images.unsplash.com/photo-1606220945770-b5b6c2c55bf1?w=400',
        stockQuantity: 10,
        isActive: true,
        termsAndConditions: ['Shipping included. 1-year warranty. Limited quantity.'],
        expiryDate: now.add(const Duration(days: 180)),
        deliveryInfo: DeliveryInfo(
          requiresAddress: true,
          estimatedDays: 7,
          availableCountries: ['US', 'CA', 'UK'],
        ),
        createdAt: now,
        updatedAt: now,
      ),
      
      Reward(
        id: '',
        title: "McDonald's \$15 Meal Voucher",
        description: "Meal voucher for McDonald's. Perfect for a quick lunch or dinner.",
        pointsCost: 300,
        category: RewardCategory.food,
        rewardType: RewardType.digital,
        imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
        stockQuantity: 300,
        isActive: true,
        termsAndConditions: ['Valid for 30 days. Cannot be used for delivery orders.'],
        expiryDate: now.add(const Duration(days: 30)),
        createdAt: now,
        updatedAt: now,
      ),
      
      Reward(
        id: '',
        title: 'Spotify Premium 3 Months',
        description: 'Three months of Spotify Premium. Ad-free music streaming.',
        pointsCost: 600,
        category: RewardCategory.entertainment,
        rewardType: RewardType.digital,
        imageUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400',
        stockQuantity: 75,
        isActive: true,
        termsAndConditions: ['New subscribers only. Valid for 90 days from redemption.'],
        expiryDate: now.add(const Duration(days: 90)),
        createdAt: now,
        updatedAt: now,
      ),
      
      Reward(
        id: '',
        title: 'Nike Air Max Sneakers',
        description: 'Comfortable Nike Air Max sneakers. Available in multiple sizes.',
        pointsCost: 3000,
        category: RewardCategory.fashion,
        rewardType: RewardType.physical,
        imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
        stockQuantity: 25,
        isActive: true,
        termsAndConditions: ['Shipping included. Size selection required. 30-day return policy.'],
        expiryDate: now.add(const Duration(days: 120)),
        deliveryInfo: DeliveryInfo(
          requiresAddress: true,
          estimatedDays: 5,
          availableCountries: ['US', 'CA', 'UK', 'AU'],
        ),
        createdAt: now,
        updatedAt: now,
      ),
      
      Reward(
        id: '',
        title: "Google Play \$25 Credit",
        description: 'Google Play Store credit. Use for apps, games, movies, and books.',
        pointsCost: 500,
        category: RewardCategory.giftCard,
        rewardType: RewardType.digital,
        imageUrl: 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=400',
        stockQuantity: 150,
        isActive: true,
        termsAndConditions: ['Valid for 60 days. Cannot be refunded or transferred.'],
        expiryDate: now.add(const Duration(days: 60)),
        createdAt: now,
        updatedAt: now,
      ),
      
      Reward(
        id: '',
        title: "Pizza Hut \$20 Voucher",
        description: 'Pizza voucher for Pizza Hut. Perfect for family dinner!',
        pointsCost: 400,
        category: RewardCategory.food,
        rewardType: RewardType.digital,
        imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
        stockQuantity: 200,
        isActive: true,
        termsAndConditions: ['Valid for 45 days. Can be used for delivery or pickup.'],
        expiryDate: now.add(const Duration(days: 45)),
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
