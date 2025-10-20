import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/offer_model.dart';
import '../providers/offers_provider.dart';
import '../service/offer_service.dart';
import '../service/seller_follower_service.dart';
import '../res/app_colors.dart';
import '../res/apptextstyles.dart';
import '../../l10n/app_localizations.dart';

class OfferDetailPage extends StatefulWidget {
  final String offerId;

  const OfferDetailPage({
    super.key,
    required this.offerId,
  });

  @override
  State<OfferDetailPage> createState() => _OfferDetailPageState();
}

class _OfferDetailPageState extends State<OfferDetailPage> {
  final OfferService _offerService = OfferService();
  final SellerFollowerService _followerService = SellerFollowerService();
  
  Offer? _offer;
  bool _loading = true;
  bool _isFollowing = false;
  bool _hasRedeemed = false;
  bool _redeeming = false;

  @override
  void initState() {
    super.initState();
    _loadOfferDetails();
  }

  Future<void> _loadOfferDetails() async {
    try {
      final offer = await _offerService.getOfferById(widget.offerId);
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (offer != null) {
        // Increment view count
        await _offerService.incrementViewCount(widget.offerId);

        if (userId != null) {
          // Check if user is following seller
          final following = await _followerService.isFollowing(userId, offer.sellerId);
          
          // Check if user has redeemed
          final redeemed = await _offerService.hasUserRedeemed(userId, widget.offerId);

          setState(() {
            _offer = offer;
            _isFollowing = following;
            _hasRedeemed = redeemed;
            _loading = false;
          });
        } else {
          setState(() {
            _offer = offer;
            _loading = false;
          });
        }
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading offer details: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.darkBgColor,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryColor,
          ),
        ),
      );
    }

    if (_offer == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBgColor,
        appBar: AppBar(
          backgroundColor: AppColors.darkBgColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.whiteColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            'Offer not found',
            style: AppTextStyles.subHeadingTextStyle,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          _buildSliverAppBar(),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Discount Badge & Category
                  _buildBadges(),
                  
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    _offer!.title,
                    style: AppTextStyles.headingTextStyle3,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    _offer!.description,
                    style: AppTextStyles.bodyTextStyle,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Validity Info
                  _buildValidityInfo(),
                  
                  const SizedBox(height: 24),
                  
                  // Follow Seller Button
                  _buildFollowSellerButton(),
                  
                  const SizedBox(height: 24),
                  
                  // Terms & Conditions
                  if (_offer!.termsAndConditions.isNotEmpty)
                    _buildTermsAndConditions(),
                  
                  const SizedBox(height: 24),
                  
                  // Redemption Section
                  if (!_hasRedeemed && _offer!.canBeRedeemed)
                    _buildRedemptionSection(),
                  
                  if (_hasRedeemed)
                    _buildAlreadyRedeemedSection(),
                  
                  if (!_offer!.canBeRedeemed && !_hasRedeemed)
                    _buildUnavailableSection(),
                    
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: AppColors.darkBgColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.darkBgColor.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: AppColors.whiteColor),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.darkBgColor.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share, color: AppColors.whiteColor),
          ),
          onPressed: () {
            // TODO: Implement share functionality
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _offer!.imageUrl != null
            ? Image.network(
                _offer!.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage();
                },
              )
            : _buildPlaceholderImage(),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xff4A90E2), const Color(0xff7BB3F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_offer,
          color: AppColors.whiteColor.withOpacity(0.5),
          size: 100,
        ),
      ),
    );
  }

  Widget _buildBadges() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _offer!.displayDiscount,
            style: AppTextStyles.bodyTextStyle.copyWith(
              color: AppColors.whiteColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (_offer!.category != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _offer!.category!,
              style: AppTextStyles.bodyTextStyle.copyWith(
                color: AppColors.whiteColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildValidityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: AppColors.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                _offer!.validityStatus,
                style: AppTextStyles.bodyTextStyle.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_offer!.maxRedemptions != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people_outline, color: AppColors.whiteColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Redeemed ${_offer!.currentRedemptions} of ${_offer!.maxRedemptions}',
                  style: AppTextStyles.bodyTextStyle,
                ),
              ],
            ),
          ],
          if (_offer!.minPurchaseAmount != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.shopping_cart_outlined, color: AppColors.whiteColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Min. purchase: \$${_offer!.minPurchaseAmount!.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyTextStyle,
                ),
              ],
            ),
          ],
          if (_offer!.reviewPointsReward > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.stars, color: AppColors.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Earn ${_offer!.reviewPointsReward} Flixbit points on redemption',
                  style: AppTextStyles.bodyTextStyle.copyWith(
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFollowSellerButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _toggleFollowSeller,
        icon: Icon(
          _isFollowing ? Icons.favorite : Icons.favorite_border,
          color: _isFollowing ? AppColors.primaryColor : AppColors.whiteColor,
        ),
        label: Text(
          _isFollowing ? 'Following Seller' : 'Follow Seller',
          style: AppTextStyles.buttonTextStyle.copyWith(
            color: _isFollowing ? AppColors.primaryColor : AppColors.whiteColor,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: _isFollowing ? AppColors.primaryColor : AppColors.unSelectedGreyColor,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Terms & Conditions',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _offer!.termsAndConditions.map((term) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.whiteColor)),
                    Expanded(
                      child: Text(
                        term,
                        style: AppTextStyles.bodyTextStyle,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRedemptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Redeem This Offer',
          style: AppTextStyles.subHeadingTextStyle,
        ),
        const SizedBox(height: 16),
        
        // QR Code Section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              QrImageView(
                data: _offer!.qrCodeData,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: AppColors.whiteColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Show this QR code to the seller',
                style: AppTextStyles.bodyTextStyle.copyWith(
                  color: AppColors.darkBgColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Digital Coupon Code (if available)
        if (_offer!.discountCode != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryColor,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coupon Code',
                        style: AppTextStyles.captionTextStyle.copyWith(
                          color: AppColors.unSelectedGreyColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _offer!.discountCode!,
                        style: AppTextStyles.subHeadingTextStyle.copyWith(
                          color: AppColors.primaryColor,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _offer!.discountCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Coupon code copied!'),
                        backgroundColor: AppColors.primaryColor,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, color: AppColors.primaryColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Redeem Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _redeeming ? null : _redeemOffer,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _redeeming
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.whiteColor,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Redeem Now',
                    style: AppTextStyles.buttonTextStyle,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlreadyRedeemedSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Already Redeemed',
            style: AppTextStyles.subHeadingTextStyle.copyWith(
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have already redeemed this offer',
            style: AppTextStyles.bodyTextStyle.copyWith(
              color: AppColors.unSelectedGreyColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.unSelectedGreyColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Offer Unavailable',
            style: AppTextStyles.subHeadingTextStyle.copyWith(
              color: AppColors.unSelectedGreyColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _offer!.validityStatus,
            style: AppTextStyles.bodyTextStyle.copyWith(
              color: AppColors.unSelectedGreyColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFollowSeller() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final newState = await _followerService.toggleFollow(
        userId,
        _offer!.sellerId,
        'manual',
      );

      setState(() {
        _isFollowing = newState;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newState ? 'Following seller' : 'Unfollowed seller'),
          backgroundColor: AppColors.primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update follow status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _redeemOffer() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to redeem offers'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _redeeming = true;
    });

    try {
      final provider = Provider.of<OffersProvider>(context, listen: false);
      final redemption = await provider.redeemOffer(
        userId: userId,
        offerId: widget.offerId,
        method: 'digital',
      );

      if (redemption != null) {
        setState(() {
          _hasRedeemed = true;
          _redeeming = false;
        });

        // Show success dialog
        _showSuccessDialog(redemption.pointsEarned);
      } else {
        setState(() {
          _redeeming = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to redeem offer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _redeeming = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(int pointsEarned) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'Offer Redeemed!',
              style: AppTextStyles.headingTextStyle3.copyWith(
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You earned $pointsEarned Flixbit points',
              style: AppTextStyles.bodyTextStyle.copyWith(
                color: AppColors.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Show this offer at the store to claim your discount',
              style: AppTextStyles.bodyTextStyle.copyWith(
                color: AppColors.unSelectedGreyColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to offers list
            },
            child: Text(
              'Done',
              style: AppTextStyles.buttonTextStyle.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

