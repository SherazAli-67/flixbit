import 'package:flixbit/src/widgets/primary_btn.dart';
import 'package:flutter/material.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

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
        title: const Text(
          'Wallet',
          style: AppTextStyles.headingTextStyle3,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // User Profile Section
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Avatar with verification badge
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.avatarBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: AppColors.whiteColor,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // User name
                  const Text(
                    'Ethan Carter',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.whiteColor,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Balance label
                  Text(
                    'Flixbit Balance',
                    style: AppTextStyles.bodyTextStyle.copyWith(
                      color: AppColors.lightGreyColor,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Balance amount
                  const Text(
                    '1,250',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.whiteColor,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Buy and Sell Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      children: [
                        Expanded(
                          child: PrimaryBtn(btnText: "Buy", icon: '', onTap: (){}, borderRadius: 20,),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        Expanded(
                          child: PrimaryBtn(btnText: "Sell", icon: '', onTap: (){}, borderRadius: 20, bgColor: AppColors.primaryColor.withValues(alpha: 0.12),),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
            
            // Transactions Section
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transactions',
                      style: AppTextStyles.subHeadingTextStyle,
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Transactions List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final transactions = [
                      {
                        'icon': Icons.trending_up,
                        'title': 'Sold Flixbits',
                        'date': '2024-03-15',
                        'amount': '-500',
                        'isPositive': false,
                      },
                      {
                        'icon': Icons.trending_down,
                        'title': 'Bought Flixbits',
                        'date': '2024-03-10',
                        'amount': '+1000',
                        'isPositive': true,
                      },
                      {
                        'icon': Icons.card_giftcard,
                        'title': 'Redeemed Points',
                        'date': '2024-03-05',
                        'amount': '-250',
                        'isPositive': false,
                      },
                      {
                        'icon': Icons.trending_up,
                        'title': 'Sold Flixbits',
                        'date': '2024-02-28',
                        'amount': '-750',
                        'isPositive': false,
                      },
                      {
                        'icon': Icons.trending_down,
                        'title': 'Bought Flixbits',
                        'date': '2024-02-25',
                        'amount': '+2000',
                        'isPositive': true,
                      },
                      {
                        'icon': Icons.card_giftcard,
                        'title': 'Redeemed Points',
                        'date': '2024-02-20',
                        'amount': '-100',
                        'isPositive': false,
                      },
                    ];
                    
                    if (index < transactions.length) {
                      final transaction = transactions[index];
                      return _buildTransactionItem(
                        icon: transaction['icon'] as IconData,
                        title: transaction['title'] as String,
                        date: transaction['date'] as String,
                        amount: transaction['amount'] as String,
                        isPositive: transaction['isPositive'] as bool,
                      );
                    }
                    return null;
                  },
                  childCount: 6, // Number of transactions
                ),
              ),
            ),
            
            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required String title,
    required String date,
    required String amount,
    required bool isPositive,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryColor,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.tileTitleTextStyle,
                ),
                Text(
                  date,
                  style: AppTextStyles.captionTextStyle.copyWith(
                    color: AppColors.lightGreyColor,
                  ),
                ),
              ],
            ),
          ),
          
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isPositive ? AppColors.greenColor : AppColors.redColor,
            ),
          ),
        ],
      ),
    );
  }
}


