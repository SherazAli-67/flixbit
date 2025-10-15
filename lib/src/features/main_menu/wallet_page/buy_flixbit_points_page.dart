import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flixbit/src/providers/wallet_provider.dart';
import 'package:flixbit/src/res/app_colors.dart';
import 'package:flixbit/src/res/apptextstyles.dart';
import 'package:flixbit/src/widgets/primary_btn.dart';
import 'package:flixbit/src/widgets/loading_indicator.dart';

class BuyFlixbitPointsPage extends StatefulWidget {
  const BuyFlixbitPointsPage({super.key});

  @override
  State<BuyFlixbitPointsPage> createState() => _BuyFlixbitPointsPageState();
}

class _BuyFlixbitPointsPageState extends State<BuyFlixbitPointsPage> {
  int? _selectedPackageIndex;
  bool _isProcessing = false;

  // Package options with pricing
  final List<Map<String, dynamic>> _packages = [
    {
      'points': 100,
      'price': 0.99,
      'popular': false,
      'bonus': 0,
    },
    {
      'points': 500,
      'price': 4.99,
      'popular': true,
      'bonus': 50, // 10% bonus
    },
    {
      'points': 1000,
      'price': 9.99,
      'popular': false,
      'bonus': 150, // 15% bonus
    },
    {
      'points': 5000,
      'price': 49.99,
      'popular': false,
      'bonus': 1000, // 20% bonus
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Buy Flixbit Points',
          style: AppTextStyles.headingTextStyle3,
        ),
        centerTitle: true,
      ),
      body: _isProcessing
          ? const Center(child: LoadingIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Purchase Flixbit points to unlock premium features, enter tournaments, and redeem exclusive offers!',
                              style: AppTextStyles.bodyTextStyle.copyWith(
                                color: AppColors.lightGreyColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Packages title
                    Text(
                      'Select Package',
                      style: AppTextStyles.subHeadingTextStyle,
                    ),

                    const SizedBox(height: 16),

                    // Package cards
                    ...List.generate(_packages.length, (index) {
                      final package = _packages[index];
                      final isSelected = _selectedPackageIndex == index;
                      final totalPoints = package['points'] + package['bonus'];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPackageIndex = index;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryColor.withValues(alpha: 0.1)
                                : AppColors.cardBgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Popular badge
                              if (package['popular'])
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primaryColor,
                                          AppColors.primaryColor.withValues(alpha: 0.7),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'POPULAR',
                                      style: AppTextStyles.captionTextStyle.copyWith(
                                        color: AppColors.whiteColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                              Row(
                                children: [
                                  // Radio indicator
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primaryColor
                                            : AppColors.unSelectedGreyColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Center(
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppColors.primaryColor,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),

                                  const SizedBox(width: 16),

                                  // Points info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '${package['points']} Points',
                                              style: AppTextStyles.tileTitleTextStyle.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (package['bonus'] > 0) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.greenColor.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '+${package['bonus']} Bonus',
                                                  style: AppTextStyles.captionTextStyle.copyWith(
                                                    color: AppColors.greenColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Total: $totalPoints Flixbit Points',
                                          style: AppTextStyles.bodyTextStyle.copyWith(
                                            color: AppColors.lightGreyColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Price
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '\$${package['price'].toStringAsFixed(2)}',
                                        style: AppTextStyles.headingTextStyle3.copyWith(
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'USD',
                                        style: AppTextStyles.captionTextStyle.copyWith(
                                          color: AppColors.lightGreyColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Payment info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Information',
                            style: AppTextStyles.tileTitleTextStyle,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.security, 'Secure payment processing'),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.receipt, 'Instant delivery'),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.payment, 'Google Play / Apple Pay'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Purchase button
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryBtn(
                        btnText: _selectedPackageIndex == null
                            ? 'Select a Package'
                            : 'Purchase for \$${_packages[_selectedPackageIndex!]['price'].toStringAsFixed(2)}',
                        icon: '',
                        onTap: _selectedPackageIndex == null ? () {} : () => _handlePurchase(),
                        bgColor: _selectedPackageIndex == null
                            ? AppColors.unSelectedGreyColor
                            : AppColors.primaryColor,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Terms
                    Text(
                      'By purchasing, you agree to our Terms of Service and Payment Policy. All sales are final.',
                      style: AppTextStyles.captionTextStyle.copyWith(
                        color: AppColors.lightGreyColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryColor),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTextStyles.bodyTextStyle.copyWith(
            color: AppColors.lightGreyColor,
          ),
        ),
      ],
    );
  }

  Future<void> _handlePurchase() async {
    if (_selectedPackageIndex == null) return;

    final package = _packages[_selectedPackageIndex!];
    final totalPoints = package['points'] + package['bonus'];

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBgColor,
        title: Text(
          'Confirm Purchase',
          style: AppTextStyles.headingTextStyle3,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to purchase:',
              style: AppTextStyles.bodyTextStyle,
            ),
            const SizedBox(height: 16),
            _buildPurchaseDetail('Points', '${package['points']}'),
            if (package['bonus'] > 0)
              _buildPurchaseDetail('Bonus', '+${package['bonus']}', isBonus: true),
            const Divider(color: AppColors.unSelectedGreyColor),
            _buildPurchaseDetail('Total', '$totalPoints Points', isTotal: true),
            const SizedBox(height: 8),
            _buildPurchaseDetail('Price', '\$${package['price'].toStringAsFixed(2)} USD', isTotal: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.lightGreyColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Purchase', style: TextStyle(color: AppColors.primaryColor)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      
      // TODO: Integrate actual payment gateway (Google Play / Apple Pay)
      // For now, simulate payment with mock payment ID
      final paymentId = 'payment_${DateTime.now().millisecondsSinceEpoch}';
      
      await context.read<WalletProvider>().purchasePoints(
        userId: userId,
        points: totalPoints,
        amountUSD: package['price'],
        paymentMethod: 'Mock Payment', // Replace with actual payment method
        paymentId: paymentId,
      );

      if (mounted) {
        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.whiteColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Successfully purchased $totalPoints Flixbit points!',
                    style: TextStyle(color: AppColors.whiteColor),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.greenColor,
            duration: const Duration(seconds: 3),
          ),
        );

        // Go back to wallet
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildPurchaseDetail(String label, String value, {bool isBonus = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyTextStyle.copyWith(
              color: isTotal ? AppColors.whiteColor : AppColors.lightGreyColor,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyTextStyle.copyWith(
              color: isBonus
                  ? AppColors.greenColor
                  : isTotal
                      ? AppColors.primaryColor
                      : AppColors.whiteColor,
              fontWeight: isTotal || isBonus ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
