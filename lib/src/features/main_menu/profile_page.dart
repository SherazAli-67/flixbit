import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flixbit/src/res/app_icons.dart';
import 'package:flixbit/src/routes/router_enum.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';
import '../language_settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isDarkTheme = true;

  @override
  Widget build(BuildContext context) {
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
        title: Text(l10n.settings, style: AppTextStyles.headingTextStyle3),
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
                  title: AppLocalizations.of(context)!.account.toUpperCase(),
                  children: [
                    _buildSectionItemWidget(title: l10n.editProfile, onTap: (){}),
                    _buildSectionItemWidget(title: AppLocalizations.of(context)!.changePassword, onTap: (){}),
                    _buildSectionItemWidget(title: AppLocalizations.of(context)!.linkedAccounts, onTap: _onLinkedAccountsTap),
                  ]),

              _buildSectionTitleWidget(
                  title: AppLocalizations.of(context)!.preferences.toUpperCase(),
                  children: [
                    _buildSectionItemWidget(title: l10n.notifications, onTap: () {}),
                    _buildSectionItemWidget(
                      title: l10n.language, 
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LanguageSettingsPage(),
                          ),
                        );
                      }, 
                      trailingText: l10n.english
                    ),
                    _SwitchTile(
                        title: AppLocalizations.of(context)!.darkTheme,
                        value: isDarkTheme,
                        onChanged: (val) => setState(() => isDarkTheme = val)),
                  ]),

              _buildSectionTitleWidget(
                  title: 'QR SYSTEM',
                  children: [
                    _buildSectionItemWidget(
                      title: 'Scan History', 
                      onTap: ()=> context.push(RouterEnum.qrScanHistoryView.routeName),
                    ),
                  ]),

              _buildSectionTitleWidget(
                  title: AppLocalizations.of(context)!.support.toUpperCase(),
                  children: [
                    _buildSectionItemWidget(title: AppLocalizations.of(context)!.helpCenter, onTap: (){}),
                    _buildSectionItemWidget(title: AppLocalizations.of(context)!.contactUs, onTap: (){}),
                    _buildSectionItemWidget(title: AppLocalizations.of(context)!.privacyPolicy, onTap: (){}),
                  ]),

              // Admin Section (for testing purposes)
              _buildSectionTitleWidget(
                  title: 'ADMIN',
                  children: [
                    _buildSectionItemWidget(
                      title: 'Upload Sample Rewards', 
                      onTap: () => context.push(RouterEnum.adminRewardsView.routeName),
                    ),
                  ]),

              _buildSectionItemWidget(title: l10n.logout, onTap: _onLogoutTap),


            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onLogoutTap()async{
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      context.go(RouterEnum.loginView.routeName);
    }
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
      spacing: 20,
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


