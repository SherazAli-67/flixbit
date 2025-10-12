
import 'package:flixbit/src/providers/linked_accounts_provider.dart';
import 'package:flixbit/src/providers/tab_change_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../res/app_colors.dart';
import '../res/apptextstyles.dart';
import '../routes/router_enum.dart';
import '../../../l10n/app_localizations.dart';

class LinkedAccountsPage extends StatelessWidget{
  const LinkedAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LinkedAccountsProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.whiteColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(l10n.linkedAccounts, style: AppTextStyles.headingTextStyle3),
      ),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          spacing: 40,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select your preferred account", style: AppTextStyles.tileTitleTextStyle,),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 20,
              children: [
                _buildAccountItem("User Account", !provider.isSellerAccount, onTap: (){
                  provider.changeAccountType(isSeller: false);

                  context.read<MainMenuTabChangeProvider>().onTabChange(0);
                  context.go(RouterEnum.homeView.routeName);
                }),

                _buildAccountItem("Seller Account", provider.isSellerAccount, onTap: (){
                  provider.changeAccountType(isSeller: true);
                  context.read<MainMenuTabChangeProvider>().onTabChange(0);
                  context.go(RouterEnum.sellerHomeView.routeName);
                })
              ],
            )
          ],
        ),
      )),
    );
  }

  Widget _buildAccountItem(
      String title,
      bool isSelected, {
        void Function()? onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.cardBgColor,
        ),
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              child: Text(
                title, style: AppTextStyles.tileTitleTextStyle,
              ),
            ),
            Icon(
              isSelected
                  ? CupertinoIcons.smallcircle_fill_circle_fill
                  : CupertinoIcons.circle,
              color: isSelected ? AppColors.primaryColor : Colors.white,
            ),
          ],
        ),
      ),
    );
  }

}
/*
class ChangeLanguageScreen extends StatefulWidget {
  const ChangeLanguageScreen({super.key});

  @override
  State<ChangeLanguageScreen> createState() => _ChangeLanguageScreenState();
}

class _ChangeLanguageScreenState extends State<ChangeLanguageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppBackButton(),
                20.verticalSpace,
                AppText(
                  AppLocalizations.of(context)!.appLanguage,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                ),
                8.verticalSpace,
                AppText(
                  AppLocalizations.of(context)!.selectYourPreferredLanguage,
                  fontSize: 16.sp,
                ),
                20.verticalSpace,
                _buildLanguageItem(
                  AppLocalizations.of(context)!.english,
                  Get.find<MainController>().langCode.value == 'en',
                  onTap: () async {
                    Get.find<MainController>().updateLangCode('en');
                  },
                ),
                12.verticalSpace,
                _buildLanguageItem(
                  AppLocalizations.of(context)!.arabic,
                  Get.find<MainController>().langCode.value == 'ar',
                  onTap: () {
                    Get.find<MainController>().updateLangCode('ar');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageItem(
      String language,
      bool isSelected, {
        void Function()? onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: AppColors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: AppText(
                language,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            12.horizontalSpace,
            Icon(
              isSelected
                  ? CupertinoIcons.smallcircle_fill_circle_fill
                  : CupertinoIcons.circle,
              color: isSelected ? AppColors.primaryColor : AppColors.black,
            ),
          ],
        ),
      ),
    );
  }
}
*/
