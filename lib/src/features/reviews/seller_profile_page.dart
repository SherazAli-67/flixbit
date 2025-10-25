import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';
import '../../models/seller_model.dart';
import '../../models/review_model.dart';
import '../../providers/reviews_provider.dart';
import '../../service/seller_follower_service.dart';
import '../reviews/widgets/review_card.dart';
import 'write_review_page.dart';

class SellerProfilePage extends StatefulWidget {
  final String sellerId;
  final String? verificationMethod; // For review verification

  const SellerProfilePage({
    super.key,
    required this.sellerId,
    this.verificationMethod,
  });

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  late ReviewsProvider _reviewsProvider;
  Seller? _seller;
  List<Review> _reviews = [];
  ReviewSummary? _reviewSummary;
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowingLoading = false;

  @override
  void initState() {
    super.initState();
    _reviewsProvider = context.read<ReviewsProvider>();
    // Defer loading until after the initial build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSellerData();
    });
  }

  Future<void> _loadSellerData() async {
    setState(() => _isLoading = true);
    
    // Load seller data
    await _reviewsProvider.loadSellers();
    _seller = _reviewsProvider.sellers.firstWhere(
      (s) => s.id == widget.sellerId,
      orElse: () => Seller(
        id: widget.sellerId,
        name: 'Unknown Seller',
        category: 'Unknown',
        isVerified: false,
        isActive: true,
        createdAt: DateTime.now(),
      ),
    );

    // Load reviews
    await _reviewsProvider.loadReviewsForSeller(widget.sellerId);
    _reviews = _reviewsProvider.getReviewsForSeller(widget.sellerId);
    _reviewSummary = _reviewsProvider.getReviewSummaryForSeller(widget.sellerId);

    // Check follow status
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final followerService = SellerFollowerService();
      _isFollowing = await followerService.isFollowing(userId, widget.sellerId);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.darkBgColor,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryColor,
          ),
        ),
      );
    }

    if (_seller == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.unSelectedGreyColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Seller not found',
                style: AppTextStyles.headingTextStyle3,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.darkBgColor,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryColor.withValues(alpha: 0.8),
                      AppColors.darkBgColor,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Seller logo/avatar
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.whiteColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(
                                  color: AppColors.whiteColor.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: _seller!.logoUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(40),
                                      child: Image.network(
                                        _seller!.logoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.business,
                                            color: AppColors.whiteColor,
                                            size: 40,
                                          );
                                        },
                                      ),
                                    )
                                  : const Icon(
                                      Icons.business,
                                      color: AppColors.whiteColor,
                                      size: 40,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _seller!.name,
                                    style: AppTextStyles.headingTextStyle3.copyWith(
                                      color: AppColors.whiteColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _seller!.category,
                                    style: AppTextStyles.bodyTextStyle.copyWith(
                                      color: AppColors.whiteColor.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  if (_seller!.location != null) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: AppColors.whiteColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _seller!.location!,
                                          style: AppTextStyles.smallTextStyle.copyWith(
                                            color: AppColors.whiteColor.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating Summary
                  if (_reviewSummary != null) ...[
                    ReviewSummaryCard(
                      averageRating: _reviewSummary!.averageRating,
                      totalReviews: _reviewSummary!.totalReviews,
                      ratingDistribution: _reviewSummary!.ratingDistribution,
                      badges: _reviewSummary!.badges,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToWriteReview(),
                          icon: const Icon(Icons.star, size: 20),
                          label: const Text('Write Review'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: AppColors.whiteColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isFollowingLoading ? null : () => _toggleFollow(),
                          icon: Icon(
                            _isFollowing ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: _isFollowing ? Colors.red : AppColors.primaryColor,
                          ),
                          label: Text(
                            _isFollowing ? 'Following (${_seller!.followersCount})' : 'Follow (${_seller!.followersCount})',
                            style: TextStyle(
                              color: _isFollowing ? Colors.red : AppColors.primaryColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _isFollowing ? Colors.red : AppColors.primaryColor,
                            side: BorderSide(
                              color: _isFollowing ? Colors.red : AppColors.primaryColor,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Seller Description
                  if (_seller!.description != null && _seller!.description!.isNotEmpty) ...[
                    Text(
                      'About',
                      style: AppTextStyles.subHeadingTextStyle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _seller!.description!,
                      style: AppTextStyles.bodyTextStyle,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Contact Information
                  if (_seller!.phone != null || _seller!.email != null || _seller!.website != null) ...[
                    Text(
                      'Contact Information',
                      style: AppTextStyles.subHeadingTextStyle,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          if (_seller!.phone != null)
                            _buildContactItem(Icons.phone, _seller!.phone!),
                          if (_seller!.email != null)
                            _buildContactItem(Icons.email, _seller!.email!),
                          if (_seller!.website != null)
                            _buildContactItem(Icons.web, _seller!.website!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reviews (${_reviews.length})',
                        style: AppTextStyles.subHeadingTextStyle,
                      ),
                      TextButton(
                        onPressed: () => _showAllReviews(),
                        child: const Text('View All'),
                      ),
                    ],
                  ),

                  // Reviews List
                  if (_reviews.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.reviews,
                            size: 64,
                            color: AppColors.unSelectedGreyColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No reviews yet',
                            style: AppTextStyles.bodyTextStyle.copyWith(
                              color: AppColors.unSelectedGreyColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to review this seller!',
                            style: AppTextStyles.smallTextStyle.copyWith(
                              color: AppColors.unSelectedGreyColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._reviews.take(3).map((review) => ReviewCard(
                      review: review,
                      onTap: () => _showReviewDetails(review),
                    )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyTextStyle,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToWriteReview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WriteReviewPage(
          sellerId: widget.sellerId,
          sellerName: _seller!.name,
          verificationMethod: widget.verificationMethod,
        ),
      ),
    );
  }

  void _toggleFollow() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to follow sellers'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    setState(() => _isFollowingLoading = true);

    try {
      final followerService = SellerFollowerService();
      final newFollowStatus = await followerService.toggleFollow(
        userId,
        widget.sellerId,
        'manual',
      );

      if (mounted) {
        setState(() {
          _isFollowing = newFollowStatus;
          _isFollowingLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newFollowStatus 
                ? 'You are now following ${_seller?.name ?? 'this seller'}' 
                : 'You unfollowed ${_seller?.name ?? 'this seller'}'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFollowingLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  void _showAllReviews() {
    // TODO: Navigate to all reviews page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All reviews page coming soon!'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  void _showReviewDetails(Review review) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBgColor,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.unSelectedGreyColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Review Details',
                style: AppTextStyles.headingTextStyle3,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: ReviewCard(
                    review: review,
                    showSellerReply: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
