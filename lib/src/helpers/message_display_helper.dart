import 'package:flixbit/src/models/wallet_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../config/points_config.dart';
import '../res/app_colors.dart';
import '../res/apptextstyles.dart';
import '../routes/router_enum.dart';

class DisplayMessageHelper {
  static void showSnackbarMessage(BuildContext context, {required String title, IconData? icon, Color? backgroundColor, Color textIconColor = Colors.white}){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          spacing: 8,
          children: [
            if(icon != null)
              Icon(icon, color: textIconColor),
            Text(title),
          ],
        ),
        backgroundColor: backgroundColor,
      ),
    );
  }

  static Future<void> showOfferRedemptionSuccess(BuildContext context, {required String offerId, required int pointsEarned}) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 80,),
            const SizedBox(height: 16),
            Text('Offer Redeemed!', style: AppTextStyles.headingTextStyle3.copyWith(color: Colors.green,),),
            const SizedBox(height: 12),
            Text('You earned $pointsEarned Flixbit points', style: AppTextStyles.bodyTextStyle.copyWith(color: AppColors.primaryColor,), textAlign: TextAlign.center,),
            const SizedBox(height: 8),
            Text(
              'This offer has been added to your redemptions',
              style: AppTextStyles.bodyTextStyle.copyWith(color: AppColors.unSelectedGreyColor,),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: ()=> context.pop(),
            child: Text('View Details', style: AppTextStyles.buttonTextStyle.copyWith(color: AppColors.primaryColor,),),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('${RouterEnum.offerDetailView.routeName}?offerId=$offerId');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor,),
            child: const Text('View Offer'),
          ),
        ],
      ),
    );
  }

  static void showQRScannerInfoDialog(BuildContext context,) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBgColor,
        title: Text('QR Code Points', style: AppTextStyles.subHeadingTextStyle,),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Text('Earn points by scanning seller QR codes:', style: AppTextStyles.bodyTextStyle,),
            Column(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(icon: Icons.qr_code, text: '${PointsConfig.getPoints("qr_scan")} points per scan',),
                _buildInfoRow(icon: Icons.timer, text: '${PointsConfig.cooldowns["qr_scan"]} min cooldown',),
                _buildInfoRow(icon: Icons.calendar_today, text: 'Up to ${PointsConfig.dailyLimits["qr_scan"]} points daily',),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8),),
              child: Row(
                spacing: 8,
                children: [
                  Icon(Icons.info_outline, color: AppColors.primaryColor, size: 20),
                  Expanded(child: Text('Points are awarded instantly after scanning', style: AppTextStyles.smallTextStyle.copyWith(color: AppColors.primaryColor,),),),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: AppTextStyles.buttonTextStyle.copyWith(color: AppColors.primaryColor,),),
          ),
        ],
      ),
    );
  }

  static Widget _buildInfoRow({required IconData icon, required String text}) {
    return Row(
      spacing: 12,
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 20),
        Expanded(child: Text(text, style: AppTextStyles.bodyTextStyle,),),
      ],
    );
  }


  //Tournament messages helper
  static void showTournamentPointsInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBgColor,
        title: Row(
          spacing: 8,
          children: [
            Icon(Icons.emoji_events, color: AppColors.greenColor),
            Text('Tournament Earnings', style: AppTextStyles.headingTextStyle3,),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text('Tournament Points are Flixbit Points!', style: AppTextStyles.bodyTextStyle.copyWith(fontWeight: FontWeight.bold,),),
            Text(
              'The number shown here represents the total Flixbit points you\'ve earned specifically from tournament activities (predictions, qualifications, wins).',
              style: AppTextStyles.bodyTextStyle.copyWith(color: AppColors.lightGreyColor,),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.greenColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.greenColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                spacing: 8,
                children: [
                  Icon(Icons.info_outline, color: AppColors.greenColor, size: 20),
                  Expanded(
                    child: Text(
                      'These points are already included in your main Flixbit balance. No conversion needed!',
                      style: AppTextStyles.smallTextStyle.copyWith(color: AppColors.greenColor,),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it',style: TextStyle(color: AppColors.primaryColor),),
          ),
        ],
      ),
    );
  }

  //Wallet dialog
  static void showFilterDialog(
      BuildContext context, {
        TransactionType? selectedType,
        required Function(bool, TransactionType ) onTransactionTypeSelected,
        TransactionSource? selectedSource,
        required Function(bool, TransactionSource ) onTransactionSourceSelected,
        required VoidCallback onClearTap
      }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBgColor,
        title: Text(AppLocalizations.of(context)!.filterTransactions, style: AppTextStyles.headingTextStyle3,),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(AppLocalizations.of(context)!.transactionType, style: AppTextStyles.bodyTextStyle,),
                Wrap(
                  spacing: 8,
                  children: TransactionType.values.map((type) {
                    return ChoiceChip(
                        label: Text(type.toString().split('.').last),
                        selected: selectedType == type,
                        onSelected: (val){
                          onTransactionTypeSelected(val, type);
                          Navigator.pop(context);
                        }
                    );
                  }).toList(),
                ),
              ],
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(AppLocalizations.of(context)!.source, style: AppTextStyles.bodyTextStyle,),
                Wrap(
                  spacing: 8,
                  children: TransactionSource.values.map((source) {
                    return ChoiceChip(
                      label: Text(source.toString().split('.').last),
                      selected: selectedSource == source,
                      onSelected: (selected) {
                        onTransactionSourceSelected(selected, source);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),

          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              onClearTap();
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.clearAll),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }
}