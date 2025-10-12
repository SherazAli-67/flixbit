import 'package:cached_network_image/cached_network_image.dart';
import 'package:flixbit/l10n/app_localizations.dart';
import 'package:flixbit/src/res/app_icons.dart';
import 'package:flixbit/src/routes/router_enum.dart';
import 'package:flixbit/src/widgets/primary_btn.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../res/app_colors.dart';
import '../../../res/apptextstyles.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title:  Text(
          AppLocalizations.of(context)!.wallet,
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
                spacing: 40,
                children: [
                  Column(
                    spacing: 8,
                    children: [

                      // Avatar with verification badge
                      Stack(
                        children: [
                          CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(AppIcons.icDummyProfileUrl),
                            radius: 45,
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


                      // User name
                      Text(
                          'Ethan Carter',
                          style: AppTextStyles.headingTextStyle3
                      ),

                      // Balance label
                      Text(
                        AppLocalizations.of(context)!.flixbitBalance,
                        style: AppTextStyles.bodyTextStyle.copyWith(
                          color: AppColors.lightGreyColor,
                        ),
                      ),
                      // Balance amount
                      const Text(
                        '1,250',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.whiteColor,
                        ),
                      ),
                    ],
                  ),

                  // Buy and Sell Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      spacing: 16,
                      children: [
                        Expanded(
                          child: PrimaryBtn(btnText: AppLocalizations.of(context)!.buy, icon: '', onTap: (){
                            context.push(RouterEnum.buyFlixbitPointsView.routeName);
                          }, borderRadius: 20,),
                        ),

                        Expanded(
                          child: PrimaryBtn(btnText: AppLocalizations.of(context)!.sell, icon: '', onTap: (){}, borderRadius: 20, bgColor: AppColors.primaryColor.withValues(alpha: 0.12),),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),

            // Transactions Section
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                     Text(
                       AppLocalizations.of(context)!.transactions,
                      style: AppTextStyles.subHeadingTextStyle,
                    ),

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
                        'title': AppLocalizations.of(context)!.soldFlixbit,
                        'date': '2024-03-15',
                        'amount': '-500',
                        'isPositive': false,
                      },
                      {
                        'icon': Icons.trending_down,
                        'title': AppLocalizations.of(context)!.boughtFlixbit,
                        'date': '2024-03-10',
                        'amount': '+1000',
                        'isPositive': true,
                      },
                      {
                        'icon': Icons.card_giftcard,
                        'title': AppLocalizations.of(context)!.redeemPoints,
                        'date': '2024-03-05',
                        'amount': '-250',
                        'isPositive': false,
                      },
                      {
                        'icon': Icons.trending_up,
                        'title': AppLocalizations.of(context)!.soldFlixbit,
                        'date': '2024-02-28',
                        'amount': '-750',
                        'isPositive': false,
                      },
                      {
                        'icon': Icons.trending_down,
                        'title': AppLocalizations.of(context)!.boughtFlixbit,
                        'date': '2024-02-25',
                        'amount': '+2000',
                        'isPositive': true,
                      },
                      {
                        'icon': Icons.card_giftcard,
                        'title': AppLocalizations.of(context)!.redeemPoints,
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
              color: AppColors.primaryColor.withValues(alpha: 0.2),
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


