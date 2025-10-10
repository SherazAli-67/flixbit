import 'package:cached_network_image/cached_network_image.dart';
import 'package:flixbit/src/res/app_icons.dart';
import 'package:flixbit/src/routes/router_enum.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';

class SellerProfileSettingsPage extends StatefulWidget {
  const SellerProfileSettingsPage({super.key});

  @override
  State<SellerProfileSettingsPage> createState() => _SellerProfileSettingsPageState();
}

class _SellerProfileSettingsPageState extends State<SellerProfileSettingsPage> {
  bool isDarkTheme = true;

  @override
  Widget build(BuildContext context) {
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
        title: Text('Settings', style: AppTextStyles.headingTextStyle3),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 25,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 35,
                  backgroundImage: CachedNetworkImageProvider(AppIcons.icDummyProfileUrl),
                ),
                title: Text("Ethan Carter"),
                subtitle: Text("ethancarter@gmail.com"),
              ),
              _buildSectionTitleWidget(
                  title: 'ACCOUNT',
                  children: [
                    _buildSectionItemWidget(title: 'Edit Seller Profile', onTap: (){}),
                    _buildSectionItemWidget(title: 'Linked Accounts', onTap: _onLinkedAccountsTap),
                  ]),

              _buildSectionTitleWidget(
                  title: 'PREFERENCES',
                  children: [
                    _buildSectionItemWidget(title: 'Language', onTap: () {}, trailingText: 'English'),
                    _SwitchTile(
                        title: 'Dark Theme',
                        value: isDarkTheme,
                        onChanged: (val) => setState(() => isDarkTheme = val)),
                  ]),

              _buildSectionTitleWidget(
                  title: 'MANAGEMENT',
                  children: [
                    _buildSectionItemWidget(title: 'Push Notifications', onTap: ()=> context.push(RouterEnum.sellerPushNotificationsView.routeName)),
                    _buildSectionItemWidget(title: 'QR Code Tracking', onTap: ()=> context.push(RouterEnum.sellerQRCodeTrackingView.routeName) ),
                    _buildSectionItemWidget(title: 'Referral Management', onTap: ()=> context.push(RouterEnum.sellerReferralManagementView.routeName) ),
                    _buildSectionItemWidget(title: 'Prize Management', onTap: () {}, ),
                  ]),
              _buildSectionTitleWidget(
                  title: 'SUPPORT',
                  children: [
                    _buildSectionItemWidget(title: 'Help Center', onTap: (){}),
                    _buildSectionItemWidget(title: 'Contact Us', onTap: (){}),
                    _buildSectionItemWidget(title: 'Privacy Policy', onTap: (){}),
                  ]),
            ],
          ),
        ),
      ),
    );
  }

  void _onLinkedAccountsTap(){
    context.push(RouterEnum.linkedAccountsView.routeName);
  }
  Widget _buildSectionItemWidget({required String title, required VoidCallback onTap, String? trailingText}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTextStyles.tileTitleTextStyle,),
                Row(
                  children: [
                    if(trailingText != null)
                      Text(trailingText, style: AppTextStyles.smallTextStyle.copyWith(color: AppColors.unSelectedGreyColor),),
                    Icon(Icons.navigate_next_rounded)
                  ],
                )
              ],
            ),
          ),
          Container(
            height: 1,
            width: double.infinity,
            color: AppColors.cardBgColor,
          )
        ],
      ),
    );
  }

  _buildSectionTitleWidget({required String title, required List<Widget> children}) {
    return Column(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.subHeadingTextStyle.copyWith(color: AppColors.unSelectedGreyColor),),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardDarkBgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        )
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: AppTextStyles.tileTitleTextStyle)),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.whiteColor,
            activeTrackColor: AppColors.primaryColor,
            inactiveThumbColor: AppColors.whiteColor,
            inactiveTrackColor: AppColors.darkGreyColor,
          ),
        ],
      ),
    );
  }
}


