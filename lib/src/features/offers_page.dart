import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../models/offer_model.dart';
import '../providers/offers_provider.dart';
import '../routes/router_enum.dart';
import '../res/app_colors.dart';
import '../res/apptextstyles.dart';
import '../../l10n/app_localizations.dart';

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
        _loadOffersForTab(_tabController.index);
      }
    });

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOffersForTab(0);
    });
  }

  void _loadOffersForTab(int index) {
    final provider = Provider.of<OffersProvider>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    switch (index) {
      case 0: // All
        provider.loadActiveOffers(category: _selectedCategory);
        break;
      case 1: // Nearby
        // TODO: Get user location and load nearby offers
        // For now, load all offers
        provider.loadActiveOffers(category: _selectedCategory);
        break;
      case 2: // Followed
        if (userId != null) {
          provider.loadFollowedSellersOffers(userId);
        }
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
            
            // Tab Bar
            _buildTabBar(l10n),
            
            // Category Filter
            _buildCategoryFilter(),
            
            // Offers List
            Expanded(
              child: _buildOffersList(),
            ),
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
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.whiteColor,
              size: 24,
            ),
          ),
          Expanded(
            child: Text(
              l10n.offers,
              textAlign: TextAlign.center,
              style: AppTextStyles.subHeadingTextStyle,
            ),
          ),
          IconButton(
            onPressed: _showSearchDialog,
            icon: const Icon(
              Icons.search,
              color: AppColors.whiteColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primaryColor,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.primaryColor,
        unselectedLabelColor: AppColors.unSelectedGreyColor,
        labelStyle: AppTextStyles.bodyTextStyle.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.bodyTextStyle,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Nearby'),
          Tab(text: 'Followed'),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      'All',
      'Food',
      'Fashion',
      'Electronics',
      'Health',
      'Sports',
      'Entertainment',
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == (category == 'All' ? null : category);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(()=> _selectedCategory = category == 'All' ? null : category);
                _loadOffersForTab(_selectedTabIndex);
              },
              backgroundColor: AppColors.cardBgColor,
              selectedColor: AppColors.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.whiteColor : AppColors.unSelectedGreyColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOffersList() {
    return Consumer<OffersProvider>(
      builder: (context, provider, child) {
        if (provider.loading && provider.offers.isEmpty) {
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
                  onPressed: () => _loadOffersForTab(_selectedTabIndex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final offers = _getOffersForCurrentTab(provider);

        if (offers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  color: AppColors.unSelectedGreyColor,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'No offers available',
                  style: AppTextStyles.subHeadingTextStyle.copyWith(
                    color: AppColors.unSelectedGreyColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getEmptyStateMessage(),
                  style: AppTextStyles.bodyTextStyle.copyWith(
                    color: AppColors.unSelectedGreyColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.refresh(category: _selectedCategory);
          },
          color: AppColors.primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              return _buildOfferCard(offers[index]);
            },
          ),
        );
      },
    );
  }

  List<Offer> _getOffersForCurrentTab(OffersProvider provider) {
    switch (_selectedTabIndex) {
      case 0:
        return provider.filteredOffers;
      case 1:
        return provider.nearbyOffers;
      case 2:
        return provider.followedOffers;
      default:
        return provider.offers;
    }
  }

  String _getEmptyStateMessage() {
    switch (_selectedTabIndex) {
      case 0:
        return _selectedCategory != null
            ? 'No offers in this category'
            : 'Check back later for new offers';
      case 1:
        return 'No offers nearby at the moment';
      case 2:
        return 'Follow sellers to see their offers here';
      default:
        return 'No offers available';
    }
  }

  Widget _buildOfferCard(Offer offer) {
    return GestureDetector(
      onTap: () {
        context.push('${RouterEnum.offerDetailView.routeName}?offerId=${offer.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            _buildOfferImage(offer),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Discount Badge & Category
                  Row(
                    children: [
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
                      const SizedBox(width: 8),
                      if (offer.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.darkGreyColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            offer.category!,
                            style: AppTextStyles.captionTextStyle.copyWith(
                              color: AppColors.whiteColor,
                            ),
                          ),
                        ),
                    ],
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
                  
                  // Footer (Expiry & Stats)
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        offer.validityStatus,
                        style: AppTextStyles.captionTextStyle.copyWith(
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const Spacer(),
                      if (offer.maxRedemptions != null)
                        Row(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 16,
                              color: AppColors.unSelectedGreyColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${offer.currentRedemptions}/${offer.maxRedemptions}',
                              style: AppTextStyles.captionTextStyle.copyWith(
                                color: AppColors.unSelectedGreyColor,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferImage(Offer offer) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: offer.imageUrl != null
          ? Image.network(
              offer.imageUrl!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderImage(offer);
              },
            )
          : _buildPlaceholderImage(offer),
    );
  }

  Widget _buildPlaceholderImage(Offer offer) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getGradientForType(offer.type),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          _getIconForType(offer.type),
          color: AppColors.whiteColor,
          size: 64,
        ),
      ),
    );
  }

  List<Color> _getGradientForType(OfferType type) {
    switch (type) {
      case OfferType.discount:
        return [const Color(0xff4A90E2), const Color(0xff7BB3F0)];
      case OfferType.freeItem:
        return [const Color(0xff2E8B57), const Color(0xff3CB371)];
      case OfferType.buyOneGetOne:
        return [const Color(0xffFF6B6B), const Color(0xffFF8E8E)];
      case OfferType.cashback:
        return [const Color(0xffFFB347), const Color(0xffFFCC70)];
      case OfferType.points:
        return [const Color(0xff9B59B6), const Color(0xffBB8FCE)];
      case OfferType.voucher:
        return [const Color(0xff34495E), const Color(0xff5D6D7E)];
    }
  }

  IconData _getIconForType(OfferType type) {
    switch (type) {
      case OfferType.discount:
        return Icons.local_offer;
      case OfferType.freeItem:
        return Icons.card_giftcard;
      case OfferType.buyOneGetOne:
        return Icons.shopping_bag;
      case OfferType.cashback:
        return Icons.attach_money;
      case OfferType.points:
        return Icons.stars;
      case OfferType.voucher:
        return Icons.receipt_long;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBgColor,
        title: Text(
          'Search Offers',
          style: AppTextStyles.subHeadingTextStyle,
        ),
        content: TextField(
          controller: _searchController,
          style: AppTextStyles.bodyTextStyle,
          decoration: InputDecoration(
            hintText: 'Search by title, description...',
            hintStyle: AppTextStyles.bodyTextStyle.copyWith(
              color: AppColors.unSelectedGreyColor,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.primaryColor,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.unSelectedGreyColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.unSelectedGreyColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyTextStyle.copyWith(
                color: AppColors.unSelectedGreyColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final query = _searchController.text.trim();
              if (query.isNotEmpty) {
                Provider.of<OffersProvider>(context, listen: false)
                    .searchOffers(query);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}
