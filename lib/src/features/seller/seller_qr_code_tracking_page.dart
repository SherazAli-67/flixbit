import 'package:cached_network_image/cached_network_image.dart';
import 'package:flixbit/src/res/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flixbit/src/res/app_colors.dart';
import 'package:flixbit/src/res/apptextstyles.dart';

class SellerQRCodeTrackingPage extends StatelessWidget {
  const SellerQRCodeTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sellers = <Map<String, dynamic>>[
      {"name": "Alex", "followers": 120},
      {"name": "Sarah", "followers": 85},
      {"name": "Michael", "followers": 205},
      {"name": "Emily", "followers": 150},
      {"name": "David", "followers": 95},
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top AppBar-like header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.whiteColor),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Seller QR Code Tracking',
                      style: AppTextStyles.subHeadingTextStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Page Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Seller Groups',
                  style: AppTextStyles.headingTextStyle3.copyWith(color: AppColors.whiteColor),
                ),
              ),
            ),

            // List of seller groups
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sellers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final seller = sellers[index];
                  return _SellerGroupCard(
                    name: seller['name'] as String,
                    followers: seller['followers'] as int,
                  );
                },
              ),
            ),

            // Bottom create group button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.add, color: AppColors.whiteColor),
                  label: const Text(
                    'Create Group',
                    style: AppTextStyles.buttonTextStyle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerGroupCard extends StatelessWidget {
  const _SellerGroupCard({
    required this.name,
    required this.followers,
  });

  final String name;
  final int followers;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.avatarBgColor,
            backgroundImage: CachedNetworkImageProvider(AppIcons.icDummyProfileUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seller: $name',
                  style: AppTextStyles.tileTitleTextStyle,
                ),
                const SizedBox(height: 4),
                Text(
                  '$followers followers',
                  style: AppTextStyles.lightGrayRegular14,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: AppColors.whiteColor),
          ),
        ],
      ),
    );
  }
}