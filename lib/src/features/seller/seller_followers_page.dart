import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flixbit/src/res/app_colors.dart';
import 'package:flixbit/src/res/apptextstyles.dart';
import 'package:flixbit/src/service/seller_follower_service.dart';
import 'package:flixbit/src/models/seller_follower_model.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SellerFollowersPage extends StatefulWidget {
  const SellerFollowersPage({super.key});

  @override
  State<SellerFollowersPage> createState() => _SellerFollowersPageState();
}

class _SellerFollowersPageState extends State<SellerFollowersPage> {
  final SellerFollowerService _followerService = SellerFollowerService();
  String? _sellerId;
  String _filterSource = 'all';

  @override
  void initState() {
    super.initState();
    _sellerId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    if (_sellerId == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBgColor,
        body: const Center(
          child: Text(
            'Please sign in to view followers',
            style: AppTextStyles.bodyTextStyle,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Filter Chips
            _buildFilterChips(),

            // Followers List
            Expanded(
              child: StreamBuilder<List<SellerFollower>>(
                stream: _followerService.getSellerFollowers(_sellerId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: AppTextStyles.bodyTextStyle,
                      ),
                    );
                  }

                  var followers = snapshot.data ?? [];

                  // Apply filter
                  if (_filterSource != 'all') {
                    followers = followers
                        .where((f) => f.followSource == _filterSource)
                        .toList();
                  }

                  if (followers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppColors.unSelectedGreyColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _filterSource == 'all'
                                ? 'No followers yet'
                                : 'No followers from $_filterSource',
                            style: AppTextStyles.subHeadingTextStyle.copyWith(
                              color: AppColors.unSelectedGreyColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: followers.length,
                    itemBuilder: (context, index) {
                      return _buildFollowerCard(followers[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: ()=> context.pop(),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.whiteColor,
              size: 20,
            ),
          ),
          const Expanded(
            child: Text(
              'My Followers',
              style: AppTextStyles.headingTextStyle3,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'value': 'all', 'label': 'All'},
      {'value': 'qr_scan', 'label': 'QR Scan'},
      {'value': 'manual', 'label': 'Manual'},
      {'value': 'offer_redemption', 'label': 'Offer'},
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _filterSource == filter['value'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filterSource = filter['value']!;
                });
              },
              backgroundColor: AppColors.cardBgColor,
              selectedColor: AppColors.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.whiteColor : AppColors.unSelectedGreyColor,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFollowerCard(SellerFollower follower) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.person,
                    color: AppColors.primaryColor,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User ID: ${follower.userId.substring(0, 8)}...',
                      style: AppTextStyles.tileTitleTextStyle,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getSourceIcon(follower.followSource),
                          size: 14,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getSourceLabel(follower.followSource),
                          style: AppTextStyles.captionTextStyle.copyWith(
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                follower.notificationsEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: follower.notificationsEnabled
                    ? Colors.green
                    : AppColors.unSelectedGreyColor,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.darkBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Followed on',
                      style: AppTextStyles.captionTextStyle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(follower.followedAt),
                      style: AppTextStyles.bodyTextStyle,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Time',
                      style: AppTextStyles.captionTextStyle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeFormat.format(follower.followedAt),
                      style: AppTextStyles.bodyTextStyle,
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

  IconData _getSourceIcon(String source) {
    switch (source) {
      case 'qr_scan':
        return Icons.qr_code_scanner;
      case 'manual':
        return Icons.person_add;
      case 'offer_redemption':
        return Icons.local_offer;
      default:
        return Icons.help_outline;
    }
  }

  String _getSourceLabel(String source) {
    switch (source) {
      case 'qr_scan':
        return 'QR Scan';
      case 'manual':
        return 'Manual Follow';
      case 'offer_redemption':
        return 'Offer Redemption';
      default:
        return source;
    }
  }
}

