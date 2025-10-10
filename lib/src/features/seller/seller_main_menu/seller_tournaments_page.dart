import 'package:flutter/material.dart';
import '../../../res/app_colors.dart';
import '../../../res/apptextstyles.dart';

class SellerTournamentPage extends StatelessWidget {
  const SellerTournamentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 24,
            children: [
              Column(
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Tournament & Group', style: AppTextStyles.smallBoldTextStyle),
                            Text('Management', style: AppTextStyles.subHeadingTextStyle),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Divider(color: AppColors.borderColor.withValues(alpha: 0.4)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 15,
                children: [
                  Text('Create New Tournament', style: AppTextStyles.headingTextStyle3),
                  _SectionCard(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 15,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Text('Tournament Name', style: AppTextStyles.smallBoldTextStyle),
                          _DarkInputField(hint: 'Enter tournament name'),
                        ],
                      ),
                      Row(
                        spacing: 12,
                        children: [
                          Expanded(child: _DarkDateField(hint: 'mm/dd/yyyy')),
                          Expanded(child: _DarkDateField(hint: 'mm/dd/yyyy')),
                        ],
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: Text('Create Tournament', style: AppTextStyles.smallBoldTextStyle),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      Divider(color: AppColors.borderColor.withValues(alpha: 0.4)),
                    ],
                  ),),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 15,
                children: [
                  Text('Manage Games & Teams', style: AppTextStyles.headingTextStyle3),
                  _SectionCard(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 16,
                    children: [
                      Text('Add a New Game', style: AppTextStyles.whiteBold18),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Team A', style: AppTextStyles.smallBoldTextStyle),
                                const SizedBox(height: 8),
                                _DarkInputField(hint: 'Enter Team A name'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Team B', style: AppTextStyles.smallBoldTextStyle),
                                const SizedBox(height: 8),
                                _DarkInputField(hint: 'Enter Team B name'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Game Date', style: AppTextStyles.smallBoldTextStyle),
                                const SizedBox(height: 8),
                                _DarkDateField(hint: 'mm/dd/yyyy'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Game Time', style: AppTextStyles.smallBoldTextStyle),
                                const SizedBox(height: 8),
                                _DarkTimeField(hint: '--:-- --'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                          label: Text('Add Game', style: AppTextStyles.buttonTextStyle),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor.withValues(alpha: 0.12),
                            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      Divider(color: AppColors.borderColor.withValues(alpha: 0.4)),
                    ],
                  ),),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 15,
                children: [
                  Text('Upcoming Games', style: AppTextStyles.headingTextStyle3),
                  _UpcomingGameTile(title: 'Team Alpha vs. Team Beta', subtitle: 'Oct 26, 2023 - 18:00'),
                  _UpcomingGameTile(title: 'Team Gamma vs. Team Delta', subtitle: 'Oct 27, 2023 - 20:00'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _DarkInputField extends StatelessWidget {
  final String hint;
  const _DarkInputField({required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: AppTextStyles.bodyTextStyle,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.hintTextStyle,
        filled: true,
        fillColor: AppColors.searchBarBgColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primaryColor),
        ),
      ),
    );
  }
}

class _DarkDateField extends StatelessWidget {
  final String hint;
  const _DarkDateField({required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      style: AppTextStyles.bodyTextStyle,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.hintTextStyle,
        suffixIcon: Icon(Icons.calendar_today, size: 18, color: AppColors.darkGreyColor),
        filled: true,
        fillColor: AppColors.searchBarBgColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primaryColor),
        ),
      ),
    );
  }
}

class _DarkTimeField extends StatelessWidget {
  final String hint;
  const _DarkTimeField({required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      style: AppTextStyles.bodyTextStyle,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.hintTextStyle,
        suffixIcon: Icon(Icons.access_time, size: 18, color: AppColors.darkGreyColor),
        filled: true,
        fillColor: AppColors.searchBarBgColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primaryColor),
        ),
      ),
    );
  }
}

class _UpcomingGameTile extends StatelessWidget {
  final String title;
  final String subtitle;
  const _UpcomingGameTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.tileTitleTextStyle),
                const SizedBox(height: 6),
                Text(subtitle, style: AppTextStyles.lightGrayRegular12),
              ],
            ),
          ),
          Row(
            children: const [
              Icon(Icons.edit, color: Colors.white70, size: 20),
              SizedBox(width: 12),
              Icon(Icons.delete_outline, color: Colors.white70, size: 22),
            ],
          ),
        ],
      ),
    );
  }
}