import 'package:flixbit/src/res/apptextstyles.dart';
import 'package:flutter/material.dart';
import '../res/app_colors.dart';

class SubscriptionPlansPage extends StatelessWidget {
  const SubscriptionPlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 26,
            children: [
              // Header
              _buildHeader(context),
              
              // Subscription Plans
              Column(
                spacing: 16,
                children: [
                  _buildSubscriptionCard(
                    'Basic',
                    '\$9',
                    '.99/month',
                    'Choose Basic',
                    [
                      'Game Prediction Contests',
                      'QR Code Tracking',
                      'Push Notifications',
                    ],
                    false,
                  ),
                  _buildSubscriptionCard(
                    'Pro',
                    '\$19',
                    '.99/month',
                    'Choose Pro',
                    [
                      'All Basic Features',
                      'Advanced Analytics',
                      'Priority Support',
                    ],
                    true,
                  ),
                  _buildSubscriptionCard(
                    'Premium',
                    '\$29',
                    '.99/month',
                    'Choose Premium',
                    [
                      'All Pro Features',
                      'Exclusive Content',
                      '24/7 VIP Support',
                    ],
                    false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.whiteColor,
            size: 24,
          ),
        ),
        const Expanded(
          child: Text(
            'Subscription Plans',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.whiteColor,
            ),
          ),
        ),
        const SizedBox(width: 48), // Balance the back button
      ],
    );
  }

  Widget _buildSubscriptionCard(
    String planName,
    String price,
    String priceUnit,
    String buttonText,
    List<String> features,
    bool isPro,
  ) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: isPro ? Border.all(color: AppColors.primaryColor, width: 1) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 15,
            children: [
              // Plan Name
              Text(
                planName,
                style: AppTextStyles.headingTextStyle3
              ),

              // Choose Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle subscription selection
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPro ? AppColors.lightBlueColor : AppColors.buttonBlueColor,
                    foregroundColor: AppColors.whiteColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: AppTextStyles.buttonTextStyle.copyWith(fontWeight: FontWeight.w600)
                  ),
                ),
              ),
              // Features List
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: features.map((feature) => _buildFeatureItem(feature)).toList(),
              ),

              // Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.whiteColor,
                    ),
                  ),
                  Text(
                    priceUnit,
                    style: AppTextStyles.smallTextStyle
                  ),
                ],
              ),

            ],
          ),
        ),
        
        // Best Value Tag for Pro plan
        if (isPro)
          Positioned(
            top: -8,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.lightBlueColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child:  Text(
                'Best Value',
                style: AppTextStyles.captionTextStyle.copyWith(fontWeight: FontWeight.w600)
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Row(
      spacing: 12,
      children: [
        Icon(
          Icons.check_circle,
          color: AppColors.primaryColor,
          size: 20,
        ),
        Expanded(
          child: Text(
            feature,
            style: AppTextStyles.smallTextStyle
          ),
        ),
      ],
    );
  }
}