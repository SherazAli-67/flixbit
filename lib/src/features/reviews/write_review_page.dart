import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';
import '../../models/review_model.dart';
import '../../providers/reviews_provider.dart';
import '../reviews/widgets/rating_widget.dart';

class WriteReviewPage extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final String? verificationMethod;
  final String? offerId;
  final ReviewType reviewType;

  const WriteReviewPage({
    super.key,
    required this.sellerId,
    required this.sellerName,
    this.verificationMethod,
    this.offerId,
    this.reviewType = ReviewType.seller,
  });

  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  double _rating = 0.0;
  List<File> _selectedImages = [];
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          'Write Review',
          style: AppTextStyles.subHeadingTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitReview,
            child: Text(
              'Submit',
              style: AppTextStyles.bodyTextStyle.copyWith(
                color: _isSubmitting 
                    ? AppColors.unSelectedGreyColor 
                    : AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seller Info Card
              _buildSellerInfoCard(),
              
              const SizedBox(height: 24),
              
              // Rating Section
              _buildRatingSection(),
              
              const SizedBox(height: 24),
              
              // Comment Section
              _buildCommentSection(),
              
              const SizedBox(height: 24),
              
              // Photo Section
              _buildPhotoSection(),
              
              const SizedBox(height: 24),
              
              // Verification Info
              if (widget.verificationMethod != null)
                _buildVerificationInfo(),
              
              const SizedBox(height: 24),
              
              // Points Reward Info
              _buildPointsInfo(),
              
              const SizedBox(height: 24),
              
              // Error Message
              if (_error != null)
                _buildErrorMessage(),
              
              const SizedBox(height: 24),
              
              // Submit Button
              _buildSubmitButton(),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSellerInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.business,
              color: AppColors.primaryColor,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.sellerName,
                  style: AppTextStyles.bodyTextStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getReviewTypeLabel(),
                  style: AppTextStyles.smallTextStyle.copyWith(
                    color: AppColors.unSelectedGreyColor,
                  ),
                ),
                if (widget.verificationMethod != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Verified Interaction',
                      style: AppTextStyles.captionTextStyle.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating *',
          style: AppTextStyles.bodyTextStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: RatingWidget(
            initialRating: _rating,
            isInteractive: true,
            size: 40,
            onRatingChanged: (rating) {
              setState(() {
                _rating = rating;
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _getRatingText(),
            style: AppTextStyles.smallTextStyle.copyWith(
              color: AppColors.unSelectedGreyColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comment (Optional)',
          style: AppTextStyles.bodyTextStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.unSelectedGreyColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _commentController,
            maxLines: 5,
            maxLength: 500,
            style: AppTextStyles.bodyTextStyle,
            decoration: InputDecoration(
              hintText: 'Share your experience with this seller...',
              hintStyle: AppTextStyles.bodyTextStyle.copyWith(
                color: AppColors.unSelectedGreyColor,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterStyle: AppTextStyles.captionTextStyle.copyWith(
                color: AppColors.unSelectedGreyColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos (Optional)',
          style: AppTextStyles.bodyTextStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                return GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.unSelectedGreyColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          color: AppColors.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add Photo',
                          style: AppTextStyles.captionTextStyle.copyWith(
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add photos to earn extra Flixbit points!',
          style: AppTextStyles.captionTextStyle.copyWith(
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified,
            color: AppColors.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your interaction with this seller has been verified',
              style: AppTextStyles.smallTextStyle.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsInfo() {
    int points = 5; // Base points for rating
    if (_commentController.text.isNotEmpty) points += 5;
    if (_selectedImages.isNotEmpty) points += 10;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.stars,
            color: AppColors.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'You will earn $points Flixbit points for this review',
            style: AppTextStyles.smallTextStyle.copyWith(
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: AppTextStyles.smallTextStyle.copyWith(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReview,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.whiteColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: AppColors.whiteColor,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Submit Review',
                style: AppTextStyles.bodyTextStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  String _getReviewTypeLabel() {
    switch (widget.reviewType) {
      case ReviewType.seller:
        return 'Seller Review';
      case ReviewType.offer:
        return 'Offer Review';
      case ReviewType.videoAd:
        return 'Video Ad Review';
      case ReviewType.referral:
        return 'Referral Review';
    }
  }

  String _getRatingText() {
    if (_rating == 0) return 'Tap to rate';
    if (_rating <= 1) return 'Poor';
    if (_rating <= 2) return 'Fair';
    if (_rating <= 3) return 'Good';
    if (_rating <= 4) return 'Very Good';
    return 'Excellent';
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showError(String message) {
    setState(() {
      _error = message;
    });
  }

  void _clearError() {
    setState(() {
      _error = null;
    });
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      _showError('Please select a rating');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _clearError();
    });

    try {
      final reviewsProvider = context.read<ReviewsProvider>();
      
      // Convert images to URLs (in real app, upload to storage first)
      List<String>? imageUrls;
      if (_selectedImages.isNotEmpty) {
        // TODO: Upload images to Firebase Storage and get URLs
        imageUrls = _selectedImages.map((file) => file.path).toList();
      }

      final success = await reviewsProvider.submitReview(
        userId: 'current_user_id', // TODO: Get from auth provider
        sellerId: widget.sellerId,
        rating: _rating.round(),
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        imageUrls: imageUrls,
        type: widget.reviewType,
        offerId: widget.offerId,
        verificationMethod: widget.verificationMethod,
      );

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Review submitted successfully!'),
            backgroundColor: AppColors.primaryColor,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Navigate back to seller profile
                Navigator.of(context).pop();
              },
            ),
          ),
        );
        
        // Navigate back
        Navigator.of(context).pop();
      } else {
        _showError(reviewsProvider.error ?? 'Failed to submit review');
      }
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

