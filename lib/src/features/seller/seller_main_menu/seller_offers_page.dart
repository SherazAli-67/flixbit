import 'package:flutter/material.dart';
import '../../../res/app_colors.dart';
import '../../../res/apptextstyles.dart';

class SellerOffersPage extends StatefulWidget {
  const SellerOffersPage({super.key});

  @override
  State<SellerOffersPage> createState() => _SellerOffersPageState();
}

class _SellerOffersPageState extends State<SellerOffersPage> {
  int selectedTabIndex = 0;
  final List<String> tabs = ['Active', 'Drafts', 'Expired'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.whiteColor,
                      size: 20,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Offers',
                      style: AppTextStyles.headingTextStyle3,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 40), // Balance the back button
                ],
              ),
            ),
            
            // Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: tabs.asMap().entries.map((entry) {
                  int index = entry.key;
                  String tab = entry.value;
                  bool isSelected = index == selectedTabIndex;
                  
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedTabIndex = index;
                        });
                      },
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              tab,
                              style: isSelected
                                  ? AppTextStyles.bodyTextStyle.copyWith(
                                      color: AppColors.vibrantBlueColor,
                                      fontWeight: FontWeight.w600,
                                    )
                                  : AppTextStyles.bodyTextStyle.copyWith(
                                      color: AppColors.unSelectedGreyColor,
                                    ),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              height: 2,
                              width: 30,
                              decoration: const BoxDecoration(
                                color: AppColors.vibrantBlueColor,
                                borderRadius: BorderRadius.all(Radius.circular(1)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Offer List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  _buildOfferItem(
                    '20% off on all items',
                    'Expires in 2 days',
                    'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=100&h=100&fit=crop',
                  ),
                  const SizedBox(height: 16),
                  _buildOfferItem(
                    'Buy 1 Get 1 Free',
                    'Expires in 1 week',
                    'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=100&h=100&fit=crop',
                  ),
                  const SizedBox(height: 16),
                  _buildOfferItem(
                    'Free shipping on orders over \$50',
                    'Expires in 1 month',
                    'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=100&h=100&fit=crop',
                  ),
                ],
              ),
            ),
            
            // Create New Offer Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle create new offer
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vibrantBlueColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.whiteColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppColors.vibrantBlueColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Create New Offer',
                        style: AppTextStyles.buttonTextStyle,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferItem(String title, String expiry, String imageUrl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.darkGreyColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: AppColors.unSelectedGreyColor,
                    size: 24,
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Offer Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.tileTitleTextStyle,
                ),
                const SizedBox(height: 4),
                Text(
                  expiry,
                  style: AppTextStyles.expiryTextStyle,
                ),
              ],
            ),
          ),
          
          // Arrow Icon
          const Icon(
            Icons.arrow_forward_ios,
            color: AppColors.unSelectedGreyColor,
            size: 16,
          ),
        ],
      ),
    );
  }
}