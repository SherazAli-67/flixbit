import 'package:flutter/material.dart';
import '../../../res/app_colors.dart';
import '../../../res/apptextstyles.dart';
import '../../../../l10n/app_localizations.dart';

class BuyFlixbitPointsPage extends StatefulWidget {
  const BuyFlixbitPointsPage({super.key});

  @override
  State<BuyFlixbitPointsPage> createState() => _BuyFlixbitPointsPageState();
}

class _BuyFlixbitPointsPageState extends State<BuyFlixbitPointsPage> {
  String selectedPaymentMethod = 'Credit Card';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.whiteColor,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.buyFlixbitPoints,
                    style: AppTextStyles.subHeadingTextStyle,
                  ),
                  const Spacer(),
                  const SizedBox(width: 24), // Balance the close button
                ],
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Payment Method Section
                    Text(
                      'Payment Method',
                      style: AppTextStyles.tileTitleTextStyle,
                    ),
                    const SizedBox(height: 16),
                    
                    // Payment Options
                    _buildPaymentOption('Credit Card', 'Credit Card'),
                    const SizedBox(height: 12),
                    _buildPaymentOption('PayPal', 'PayPal'),
                    const SizedBox(height: 12),
                    _buildPaymentOption('Apple Pay', 'Apple Pay'),
                    
                    const SizedBox(height: 32),
                    
                    // Order Summary Section
                    Text(
                      'Order Summary',
                      style: AppTextStyles.tileTitleTextStyle,
                    ),
                    const SizedBox(height: 16),
                    
                    // Order Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.orderSummaryBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildOrderRow('Flixbit Points', '1000'),
                          const SizedBox(height: 12),
                          _buildOrderRow('Subtotal', '\$10.00'),
                          const SizedBox(height: 12),
                          _buildOrderRow('Taxes', '\$1.00'),
                          const SizedBox(height: 12),
                          const Divider(
                            color: AppColors.darkGreyColor,
                            thickness: 1,
                          ),
                          const SizedBox(height: 12),
                          _buildOrderRow('Total', '\$11.00', isTotal: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Pay Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle payment
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Pay \$11.00',
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

  Widget _buildPaymentOption(String title, String value) {
    final isSelected = selectedPaymentMethod == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.selectedPaymentMethodBgColor 
              : AppColors.paymentMethodBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: AppTextStyles.bodyTextStyle,
            ),
            const Spacer(),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primaryColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primaryColor : AppColors.unSelectedGreyColor,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: AppColors.whiteColor,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal ? AppTextStyles.tileTitleTextStyle : AppTextStyles.bodyTextStyle,
        ),
        Text(
          value,
          style: isTotal ? AppTextStyles.tileTitleTextStyle : AppTextStyles.bodyTextStyle,
        ),
      ],
    );
  }
}