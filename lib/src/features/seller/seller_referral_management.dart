import 'package:flutter/material.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';

class SellerReferralManagement extends StatelessWidget {
  const SellerReferralManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Referral Management',
          style: AppTextStyles.subHeadingTextStyle,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Referral Overview Section
              const Text(
                'Referral Overview',
                style: AppTextStyles.subHeadingTextStyle,
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  _buildOverviewCard('Total Referrals', '1,250'),
                  const SizedBox(height: 12),
                  _buildOverviewCard('Active Referrals', '875'),
                  const SizedBox(height: 12),
                  _buildOverviewCard('Pending Rewards', '375'),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Referral Activity Section
              const Text(
                'Referral Activity',
                style: AppTextStyles.subHeadingTextStyle,
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  _buildActivityItem('Sophia', 'Referred by: Alex'),
                  const SizedBox(height: 12),
                  _buildActivityItem('Liam', 'Referred by: Ethan'),
                  const SizedBox(height: 12),
                  _buildActivityItem('Noah', 'Referred by: Olivia'),
                  const SizedBox(height: 12),
                  _buildActivityItem('Isabella', 'Referred by: Ava'),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Seller Profiles Section
              const Text(
                'Seller Profiles',
                style: AppTextStyles.subHeadingTextStyle,
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  _buildSellerItem('Harper', '2023-08-15'),
                  const SizedBox(height: 12),
                  _buildSellerItem('Elijah', '2023-09-22'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.lightGrayRegular14,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.whiteBold20,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String name, String referrerInfo) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.avatarBgColor,
            child: Text(
              name[0],
              style: const TextStyle(
                color: AppColors.darkBgColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.tileTitleTextStyle,
                ),
                const SizedBox(height: 4),
                Text(
                  referrerInfo,
                  style: AppTextStyles.lightGrayRegular14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerItem(String sellerName, String joinDate) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.avatarBgColor,
            child: Text(
              sellerName[0],
              style: const TextStyle(
                color: AppColors.darkBgColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seller: $sellerName',
                  style: AppTextStyles.tileTitleTextStyle,
                ),
                const SizedBox(height: 4),
                Text(
                  'Joined: $joinDate',
                  style: AppTextStyles.lightGrayRegular14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}