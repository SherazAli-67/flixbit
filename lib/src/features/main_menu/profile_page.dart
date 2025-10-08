import 'package:flutter/material.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isDarkTheme = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgColor,
        elevation: 0,
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
            children: [
              _ProfileHeader(),
              const SizedBox(height: 24),
              _SectionTitle(title: 'ACCOUNT'),
              const SizedBox(height: 12),
              _SectionCard(
                children: [
                  _ArrowTile(title: 'Edit Profile'),
                  const _SectionDivider(),
                  _ArrowTile(title: 'Change Password'),
                  const _SectionDivider(),
                  _ArrowTile(title: 'Linked Accounts'),
                ],
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'PREFERENCES'),
              const SizedBox(height: 12),
              _SectionCard(
                children: [
                  _ArrowTile(title: 'Notifications'),
                  const _SectionDivider(),
                  _ValueArrowTile(title: 'Language', value: 'English'),
                  const _SectionDivider(),
                  _SwitchTile(
                    title: 'Dark Theme',
                    value: isDarkTheme,
                    onChanged: (v) => setState(() => isDarkTheme = v),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'SUPPORT'),
              const SizedBox(height: 12),
              _SectionCard(
                children: const [
                  _ArrowTile(title: 'Help Center'),
                  _SectionDivider(),
                  _ArrowTile(title: 'Contact Us'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.cardBgColor,
          child: CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.avatarBgColor,
            child: Icon(Icons.person, color: AppColors.darkGreyColor, size: 40),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Text('Ethan Carter', style: AppTextStyles.headingTextStyle3),
              Text(
                'ethan.carter@email.com',
                style: AppTextStyles.smallTextStyle.copyWith(
                  color: AppColors.unSelectedGreyColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.smallBoldTextStyle.copyWith(
        color: AppColors.unSelectedGreyColor,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 1,
      color: AppColors.darkGreyColor.withOpacity(0.3),
    );
  }
}

class _ArrowTile extends StatelessWidget {
  final String title;
  const _ArrowTile({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(title, style: AppTextStyles.tileTitleTextStyle),
        ),
        Icon(Icons.chevron_right, color: AppColors.unSelectedGreyColor),
      ],
    );
  }
}

class _ValueArrowTile extends StatelessWidget {
  final String title;
  final String value;
  const _ValueArrowTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Text(title, style: AppTextStyles.tileTitleTextStyle)),
        Row(spacing: 8, children: [
          Text(
            value,
            style: AppTextStyles.smallTextStyle.copyWith(color: AppColors.unSelectedGreyColor),
          ),
          Icon(Icons.chevron_right, color: AppColors.unSelectedGreyColor),
        ]),
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
    return Row(
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
    );
  }
}


