import 'package:flutter/material.dart';
import '../res/app_colors.dart';
import '../res/apptextstyles.dart';

class OffersPage extends StatelessWidget {
  const OffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 24,
            children: [
              // Header
              _buildHeader(context),
              
              // Featured Offers Section
              _buildFeaturedOffersSection(),
              
              // Nearby Offers Section
              _buildNearbyOffersSection(),
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
            'Offers',
            textAlign: TextAlign.center,
            style: AppTextStyles.subHeadingTextStyle,
          ),
        ),
        const SizedBox(width: 48), // Balance the back button
      ],
    );
  }

  Widget _buildFeaturedOffersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        const Text(
          'Featured Offers',
          style: AppTextStyles.subHeadingTextStyle,
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: index < 2 ? 16 : 0),
                child: _buildFeaturedOfferCard(index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedOfferCard(int index) {
    final offers = [
      {
        'title': '20% off at The Grill House',
        'validity': 'Valid until July 31st',
        'imageType': 'restaurant',
      },
      {
        'title': 'Buy One Get One Free',
        'validity': 'Valid until August 15th',
        'imageType': 'clothing',
      },
      {
        'title': 'Free Delivery on Orders',
        'validity': 'Valid until August 30th',
        'imageType': 'delivery',
      },
    ];

    final offer = offers[index];
    
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                color: AppColors.unSelectedGreyColor,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: _buildFeaturedImage(offer['imageType']!),
              ),
            ),
          ),
          // Text content
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    offer['title']!,
                    style: AppTextStyles.rewardTitleStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    offer['validity']!,
                    style: AppTextStyles.expiryTextStyle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedImage(String imageType) {
    switch (imageType) {
      case 'restaurant':
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff8B4513), Color(0xffD2691E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.restaurant,
            color: AppColors.whiteColor,
            size: 60,
          ),
        );
      case 'clothing':
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff4A90E2), Color(0xff7BB3F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.checkroom,
            color: AppColors.whiteColor,
            size: 60,
          ),
        );
      case 'delivery':
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff2E8B57), Color(0xff3CB371)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.delivery_dining,
            color: AppColors.whiteColor,
            size: 60,
          ),
        );
      default:
        return Container(
          color: AppColors.unSelectedGreyColor,
          child: const Icon(
            Icons.image,
            color: AppColors.whiteColor,
            size: 60,
          ),
        );
    }
  }

  Widget _buildNearbyOffersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        const Text(
          'Nearby Offers',
          style: AppTextStyles.subHeadingTextStyle,
        ),
        Column(
          spacing: 16,
          children: [
            _buildNearbyOfferCard(
              'Local Bookstore',
              '15% off at Local Bookstore',
              'Valid at the downtown location',
              'Expires in 3 days',
              'bookstore',
            ),
            _buildNearbyOfferCard(
              'Italian Bistro',
              'Free Appetizer at Italian Bistro',
              'With purchase of an entree',
              'Expires in 7 days',
              'restaurant',
            ),
            _buildNearbyOfferCard(
              'Fitness Gear',
              '10% off at Fitness Gear',
              'On all activewear',
              'Expires in 14 days',
              'fitness',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNearbyOfferCard(
    String businessName,
    String title,
    String description,
    String expiry,
    String imageType,
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
          // Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.unSelectedGreyColor,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildNearbyImage(imageType),
            ),
          ),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  expiry,
                  style: AppTextStyles.captionTextStyle.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  title,
                  style: AppTextStyles.rewardTitleStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  description,
                  style: AppTextStyles.rewardDescStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle view details action
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.whiteColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'View Details',
                      style: AppTextStyles.captionTextStyle.copyWith(
                        color: AppColors.whiteColor,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildNearbyImage(String imageType) {
    switch (imageType) {
      case 'bookstore':
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff8B4513), Color(0xffDEB887)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.menu_book,
            color: AppColors.whiteColor,
            size: 40,
          ),
        );
      case 'restaurant':
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff2E8B57), Color(0xff90EE90)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.restaurant_menu,
            color: AppColors.whiteColor,
            size: 40,
          ),
        );
      case 'fitness':
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff4169E1), Color(0xff87CEEB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.fitness_center,
            color: AppColors.whiteColor,
            size: 40,
          ),
        );
      default:
        return Container(
          color: AppColors.unSelectedGreyColor,
          child: const Icon(
            Icons.image,
            color: AppColors.whiteColor,
            size: 40,
          ),
        );
    }
  }
}


