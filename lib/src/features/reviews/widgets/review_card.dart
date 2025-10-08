import 'package:flutter/material.dart';
import '../../../res/app_colors.dart';
import '../../../res/apptextstyles.dart';
import '../../../models/review_model.dart';
import 'rating_widget.dart';

class ReviewCard extends StatelessWidget {
  final Review review;
  final bool showSellerReply;
  final VoidCallback? onTap;
  final bool isCompact;

  const ReviewCard({
    super.key,
    required this.review,
    this.showSellerReply = true,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and rating
            Row(
              children: [
                // User avatar
                CircleAvatar(
                  radius: isCompact ? 16 : 20,
                  backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.person,
                    size: isCompact ? 16 : 20,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                // User name and rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User ${review.userId.substring(0, 8)}...', // Masked user ID
                        style: isCompact 
                            ? AppTextStyles.smallTextStyle.copyWith(fontWeight: FontWeight.w600)
                            : AppTextStyles.bodyTextStyle.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          RatingWidget(
                            initialRating: review.rating.toDouble(),
                            size: isCompact ? 14 : 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(review.createdAt),
                            style: AppTextStyles.captionTextStyle.copyWith(
                              color: AppColors.unSelectedGreyColor,
                            ),
                          ),
                          if (review.isVerified) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Verified',
                                style: AppTextStyles.captionTextStyle.copyWith(
                                  color: AppColors.primaryColor,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Review type indicator
                if (review.type != ReviewType.seller)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(review.type).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getTypeLabel(review.type),
                      style: AppTextStyles.captionTextStyle.copyWith(
                        color: _getTypeColor(review.type),
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Review comment
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.comment!,
                style: isCompact 
                    ? AppTextStyles.smallTextStyle
                    : AppTextStyles.bodyTextStyle,
                maxLines: isCompact ? 2 : null,
                overflow: isCompact ? TextOverflow.ellipsis : null,
              ),
            ],

            // Images
            if (review.imageUrls != null && review.imageUrls!.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.imageUrls!.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.unSelectedGreyColor,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          review.imageUrls![index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.unSelectedGreyColor,
                              child: const Icon(
                                Icons.image,
                                color: AppColors.whiteColor,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Seller reply
            if (showSellerReply && review.sellerReply != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.business,
                          size: 16,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Seller Response',
                          style: AppTextStyles.smallTextStyle.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const Spacer(),
                        if (review.sellerReplyDate != null)
                          Text(
                            _formatDate(review.sellerReplyDate!),
                            style: AppTextStyles.captionTextStyle.copyWith(
                              color: AppColors.unSelectedGreyColor,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review.sellerReply!,
                      style: AppTextStyles.smallTextStyle,
                    ),
                  ],
                ),
              ),
            ],

            // Points earned indicator
            if (review.pointsEarned > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.stars,
                    size: 16,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+${review.pointsEarned} Flixbit points',
                    style: AppTextStyles.captionTextStyle.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getTypeColor(ReviewType type) {
    switch (type) {
      case ReviewType.seller:
        return AppColors.primaryColor;
      case ReviewType.offer:
        return Colors.green;
      case ReviewType.videoAd:
        return Colors.blue;
      case ReviewType.referral:
        return Colors.orange;
    }
  }

  String _getTypeLabel(ReviewType type) {
    switch (type) {
      case ReviewType.seller:
        return 'Seller';
      case ReviewType.offer:
        return 'Offer';
      case ReviewType.videoAd:
        return 'Video Ad';
      case ReviewType.referral:
        return 'Referral';
    }
  }
}

class ReviewSummaryCard extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;
  final List<String> badges;

  const ReviewSummaryCard({
    super.key,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.badges,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall rating
          Row(
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: AppTextStyles.headingTextStyle3.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RatingWidget(
                    initialRating: averageRating,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalReviews reviews',
                    style: AppTextStyles.smallTextStyle.copyWith(
                      color: AppColors.unSelectedGreyColor,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Badges
              if (badges.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: badges.take(2).map((badge) => Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: AppTextStyles.captionTextStyle.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: 10,
                      ),
                    ),
                  )).toList(),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Rating distribution
          RatingDistributionWidget(
            ratingDistribution: ratingDistribution,
            totalReviews: totalReviews,
          ),
        ],
      ),
    );
  }
}
