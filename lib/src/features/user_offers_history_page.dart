import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/offer_model.dart';
import '../providers/offers_provider.dart';
import '../service/offer_service.dart';
import '../res/app_colors.dart';
import '../res/apptextstyles.dart';
import '../../l10n/app_localizations.dart';

class UserOffersHistoryPage extends StatefulWidget {
  const UserOffersHistoryPage({super.key});

  @override
  State<UserOffersHistoryPage> createState() => _UserOffersHistoryPageState();
}

class _UserOffersHistoryPageState extends State<UserOffersHistoryPage> {
  final OfferService _offerService = OfferService();
  Map<String, Offer> _offersCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRedemptions();
    });
  }

  void _loadRedemptions() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final provider = Provider.of<OffersProvider>(context, listen: false);
      provider.loadUserRedemptions(userId);
    }
  }

  Future<Offer?> _getOffer(String offerId) async {
    if (_offersCache.containsKey(offerId)) {
      return _offersCache[offerId];
    }

    final offer = await _offerService.getOfferById(offerId);
    if (offer != null) {
      setState(() {
        _offersCache[offerId] = offer;
      });
    }
    return offer;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Redemptions',
          style: AppTextStyles.subHeadingTextStyle,
        ),
        centerTitle: true,
      ),
      body: Consumer<OffersProvider>(
        builder: (context, provider, child) {
          final redemptions = provider.redemptions;

          if (provider.loading && redemptions.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            );
          }

          if (redemptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.unSelectedGreyColor,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Redemptions Yet',
                    style: AppTextStyles.subHeadingTextStyle.copyWith(
                      color: AppColors.unSelectedGreyColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start redeeming offers to see them here',
                    style: AppTextStyles.bodyTextStyle.copyWith(
                      color: AppColors.unSelectedGreyColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadRedemptions();
            },
            color: AppColors.primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: redemptions.length,
              itemBuilder: (context, index) {
                return _buildRedemptionCard(redemptions[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRedemptionCard(OfferRedemption redemption) {
    return FutureBuilder<Offer?>(
      future: _getOffer(redemption.offerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }

        final offer = snapshot.data!;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.cardBgColor,
            borderRadius: BorderRadius.circular(12),
            border: redemption.isUsed
                ? null
                : Border.all(
                    color: AppColors.primaryColor,
                    width: 2,
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: redemption.isUsed
                      ? AppColors.darkGreyColor
                      : AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      redemption.isUsed ? Icons.check_circle : Icons.local_offer,
                      color: redemption.isUsed
                          ? AppColors.unSelectedGreyColor
                          : AppColors.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      redemption.isUsed ? 'Used' : 'Ready to Use',
                      style: AppTextStyles.bodyTextStyle.copyWith(
                        color: redemption.isUsed
                            ? AppColors.unSelectedGreyColor
                            : AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(redemption.redeemedAt),
                      style: AppTextStyles.captionTextStyle.copyWith(
                        color: AppColors.unSelectedGreyColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Offer details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Discount badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        offer.displayDiscount,
                        style: AppTextStyles.captionTextStyle.copyWith(
                          color: AppColors.whiteColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Title
                    Text(
                      offer.title,
                      style: AppTextStyles.rewardTitleStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Description
                    Text(
                      offer.description,
                      style: AppTextStyles.rewardDescStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // Points earned
                    if (redemption.pointsEarned > 0)
                      Row(
                        children: [
                          Icon(
                            Icons.stars,
                            color: AppColors.primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Earned ${redemption.pointsEarned} points',
                            style: AppTextStyles.captionTextStyle.copyWith(
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        if (!redemption.isUsed)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _markAsUsed(redemption.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Mark as Used',
                                style: AppTextStyles.buttonTextStyle,
                              ),
                            ),
                          ),
                        if (!redemption.isUsed) const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // TODO: Navigate to offer details
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.primaryColor,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'View Details',
                              style: AppTextStyles.buttonTextStyle.copyWith(
                                color: AppColors.primaryColor,
                              ),
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
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _markAsUsed(String redemptionId) async {
    try {
      final provider = Provider.of<OffersProvider>(context, listen: false);
      await provider.markRedemptionAsUsed(redemptionId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marked as used'),
          backgroundColor: AppColors.primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark as used: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

