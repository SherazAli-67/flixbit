import 'package:flixbit/src/routes/router_enum.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../res/app_colors.dart';
import '../../../res/apptextstyles.dart';
import '../../../../l10n/app_localizations.dart';

class SellerVideoAdsPage extends StatelessWidget {
  const SellerVideoAdsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.videoAds,
          style: AppTextStyles.whiteBold20,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload or Link Video Section
            const Text(
              'Upload or Link Video',
              style: AppTextStyles.whiteBold18,
            ),
            const SizedBox(height: 16),
            
            // Upload Video Button
            GestureDetector(
              onTap: ()=> context.push(RouterEnum.uploadVideoAdView.routeName),
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.upload_file,
                      color: AppColors.whiteColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Upload Video',
                      style: AppTextStyles.whiteBold16,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Embed Link Button
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.link,
                    color: AppColors.whiteColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Embed Link',
                    style: AppTextStyles.whiteBold16,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Manage Videos Section
            const Text(
              'Manage Videos',
              style: AppTextStyles.whiteBold18,
            ),
            const SizedBox(height: 16),
            
            // Video Cards
            _buildVideoCard(
              'Summer Sale Ad',
              'Uploaded 2 days ago',
              '1.2K views',
              'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=150&h=100&fit=crop',
            ),
            const SizedBox(height: 12),
            
            _buildVideoCard(
              'Product Demo',
              'Linked from YouTube',
              '876 views',
              'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=150&h=100&fit=crop',
            ),
            const SizedBox(height: 12),
            
            _buildVideoCard(
              'Customer Testimonial',
              'Uploaded 1 week ago',
              '2.5K views',
              null, // This will show a play icon placeholder
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(String title, String status, String views, String? imageUrl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 120,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: imageUrl == null ? AppColors.darkGreyColor : null,
            ),
            child: imageUrl == null
                ? const Icon(
                    Icons.play_circle_outline,
                    color: AppColors.whiteColor,
                    size: 32,
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.play_circle_outline,
                          color: AppColors.whiteColor,
                          size: 32,
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          
          // Video Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.whiteBold16,
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: AppTextStyles.lightGrayRegular14,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.visibility,
                      color: AppColors.lightGreyColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      views,
                      style: AppTextStyles.lightGrayRegular14,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Options Menu
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: AppColors.whiteColor,
            ),
            onPressed: () {
              // Handle options menu
            },
          ),
        ],
      ),
    );
  }

}

/*
*   Create backend control for sub-admin, to create flixbit_tournaments and groups of the flixbit_tournaments and update the scores of the games, with the rewarding system.
*   Sub-Admin Tournament & Group Management: This screen would enable sub-admins to create and manage flixbit_tournaments, organize groups within flixbit_tournaments, and update game scores, all integrated with the rewarding system.
* */