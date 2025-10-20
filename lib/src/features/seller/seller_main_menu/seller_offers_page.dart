import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/offer_model.dart';
import '../../../providers/seller_offers_provider.dart';
import '../../../res/app_colors.dart';
import '../../../res/apptextstyles.dart';
import '../../../../l10n/app_localizations.dart';
import '../create_edit_offer_page.dart';

class SellerOffersPage extends StatefulWidget {
  const SellerOffersPage({super.key});

  @override
  State<SellerOffersPage> createState() => _SellerOffersPageState();
}

class _SellerOffersPageState extends State<SellerOffersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });

    // Load seller's offers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOffers();
    });
  }

  void _loadOffers() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final provider = Provider.of<SellerOffersProvider>(context, listen: false);
      provider.loadMyOffers(userId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, l10n),

            // Summary Stats
            _buildSummaryStats(),

            // Tab Bar
            _buildTabBar(l10n),

            // Offers List
            Expanded(
              child: _buildOffersList(),
            ),

            // Create New Offer Button
            _buildCreateButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
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
          Expanded(
            child: Text(
              l10n.offers,
              style: AppTextStyles.headingTextStyle3,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    return Consumer<SellerOffersProvider>(
      builder: (context, provider, child) {
        return FutureBuilder<Map<String, dynamic>>(
          future: provider.getSummaryAnalytics(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final stats = snapshot.data!;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.2),
                    AppColors.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Active',
                    '${stats['activeOffers'] ?? 0}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatItem(
                    'Pending',
                    '${stats['pendingOffers'] ?? 0}',
                    Icons.pending,
                    Colors.orange,
                  ),
                  _buildStatItem(
                    'Redemptions',
                    '${stats['totalRedemptions'] ?? 0}',
                    Icons.shopping_bag,
                    AppColors.primaryColor,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.subHeadingTextStyle.copyWith(
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.captionTextStyle.copyWith(
            color: AppColors.unSelectedGreyColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.vibrantBlueColor,
        indicatorWeight: 3,
        labelColor: AppColors.vibrantBlueColor,
        unselectedLabelColor: AppColors.unSelectedGreyColor,
        labelStyle: AppTextStyles.bodyTextStyle.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.bodyTextStyle,
        tabs: const [
          Tab(text: 'Active'),
          Tab(text: 'Pending'),
          Tab(text: 'Expired'),
        ],
      ),
    );
  }

  Widget _buildOffersList() {
    return Consumer<SellerOffersProvider>(
      builder: (context, provider, child) {
        if (provider.loading && provider.allOffers.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.unSelectedGreyColor,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  style: AppTextStyles.bodyTextStyle.copyWith(
                    color: AppColors.unSelectedGreyColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadOffers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final offers = _getOffersForTab(provider);

        if (offers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getEmptyStateIcon(),
                  color: AppColors.unSelectedGreyColor,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyStateMessage(),
                  style: AppTextStyles.subHeadingTextStyle.copyWith(
                    color: AppColors.unSelectedGreyColor,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            if (userId != null) {
              await provider.refresh(userId);
            }
          },
          color: AppColors.primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              return _buildOfferCard(offers[index], provider);
            },
          ),
        );
      },
    );
  }

  List<Offer> _getOffersForTab(SellerOffersProvider provider) {
    switch (_selectedTabIndex) {
      case 0:
        return provider.activeOffers;
      case 1:
        return provider.pendingOffers;
      case 2:
        return provider.expiredOffers;
      default:
        return provider.activeOffers;
    }
  }

  IconData _getEmptyStateIcon() {
    switch (_selectedTabIndex) {
      case 0:
        return Icons.local_offer_outlined;
      case 1:
        return Icons.pending_outlined;
      case 2:
        return Icons.history_outlined;
      default:
        return Icons.local_offer_outlined;
    }
  }

  String _getEmptyStateMessage() {
    switch (_selectedTabIndex) {
      case 0:
        return 'No active offers';
      case 1:
        return 'No pending offers';
      case 2:
        return 'No expired offers';
      default:
        return 'No offers';
    }
  }

  Widget _buildOfferCard(Offer offer, SellerOffersProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(8),
        border: offer.isPending
            ? Border.all(color: Colors.orange, width: 2)
            : null,
      ),
      child: Column(
        children: [
          // Status Banner (for pending offers)
          if (offer.isPending)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pending, color: AppColors.whiteColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Pending Admin Approval',
                    style: AppTextStyles.captionTextStyle.copyWith(
                      color: AppColors.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Offer Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      colors: [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      offer.displayDiscount,
                      style: AppTextStyles.captionTextStyle.copyWith(
                        color: AppColors.whiteColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Offer Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.title,
                        style: AppTextStyles.tileTitleTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: offer.isExpired
                                ? Colors.red
                                : AppColors.unSelectedGreyColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            offer.validityStatus,
                            style: AppTextStyles.expiryTextStyle.copyWith(
                              color: offer.isExpired
                                  ? Colors.red
                                  : AppColors.unSelectedGreyColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 14,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${offer.currentRedemptions} redemptions',
                            style: AppTextStyles.captionTextStyle.copyWith(
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Menu
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.unSelectedGreyColor,
                  ),
                  color: AppColors.cardBgColor,
                  onSelected: (value) {
                    _handleMenuAction(value, offer, provider);
                  },
                  itemBuilder: (context) => [
                    if (offer.isApproved) ...[
                      PopupMenuItem(
                        value: 'toggle_status',
                        child: Row(
                          children: [
                            Icon(
                              offer.isActive ? Icons.pause : Icons.play_arrow,
                              color: AppColors.whiteColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              offer.isActive ? 'Pause Offer' : 'Activate Offer',
                              style: AppTextStyles.bodyTextStyle,
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'analytics',
                        child: Row(
                          children: [
                            Icon(Icons.analytics, color: AppColors.whiteColor, size: 20),
                            SizedBox(width: 12),
                            Text('View Analytics', style: AppTextStyles.bodyTextStyle),
                          ],
                        ),
                      ),
                    ],
                    const PopupMenuItem(
                      value: 'clone',
                      child: Row(
                        children: [
                          Icon(Icons.copy, color: AppColors.whiteColor, size: 20),
                          SizedBox(width: 12),
                          Text('Clone Offer', style: AppTextStyles.bodyTextStyle),
                        ],
                      ),
                    ),
                    if (!offer.isApproved)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 12),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
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
  }

  void _handleMenuAction(String action, Offer offer, SellerOffersProvider provider) async {
    switch (action) {
      case 'toggle_status':
        final newStatus = !offer.isActive;
        final success = await provider.toggleOfferStatus(offer.id, newStatus);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newStatus ? 'Offer activated' : 'Offer paused'),
              backgroundColor: AppColors.primaryColor,
            ),
          );
        }
        break;

      case 'analytics':
        // TODO: Navigate to analytics page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analytics page coming soon'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
        break;

      case 'clone':
        _showCloneConfirmation(offer, provider);
        break;

      case 'delete':
        _showDeleteConfirmation(offer, provider);
        break;
    }
  }

  void _showCloneConfirmation(Offer offer, SellerOffersProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBgColor,
        title: Text('Clone Offer', style: AppTextStyles.subHeadingTextStyle),
        content: Text(
          'Create a copy of "${offer.title}"?',
          style: AppTextStyles.bodyTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.bodyTextStyle),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                final cloned = await provider.cloneOffer(userId, offer);
                if (cloned != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Offer cloned successfully'),
                      backgroundColor: AppColors.primaryColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text('Clone'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Offer offer, SellerOffersProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBgColor,
        title: Text('Delete Offer', style: AppTextStyles.subHeadingTextStyle),
        content: Text(
          'Are you sure you want to delete "${offer.title}"? This action cannot be undone.',
          style: AppTextStyles.bodyTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.bodyTextStyle),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteOffer(offer.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Offer deleted'),
                    backgroundColor: AppColors.primaryColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateEditOfferPage(),
              ),
            );
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
    );
  }
}
