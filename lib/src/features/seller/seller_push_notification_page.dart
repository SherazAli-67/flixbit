import 'package:flixbit/src/widgets/primary_btn.dart';
import 'package:flutter/material.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';

class SellerPushNotificationPage extends StatefulWidget {
  const SellerPushNotificationPage({super.key});

  @override
  State<SellerPushNotificationPage> createState() => _SellerPushNotificationPageState();
}

class _SellerPushNotificationPageState extends State<SellerPushNotificationPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  String selectedAudience = 'Followers';
  String selectedSchedule = 'Now';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 24,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.whiteColor,
                      size: 24,
                    ),
                  ),
                  const Text(
                    'New Notification',
                    style: AppTextStyles.headingTextStyle3,
                  ),
                  const SizedBox(width: 48), // Balance the close button
                ],
              ),
              
              // Title Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Title',
                    style: AppTextStyles.bodyTextStyle,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: AppColors.whiteColor),
                    decoration: InputDecoration(
                      hintText: 'Notification Title',
                      hintStyle: AppTextStyles.hintTextStyle,
                      filled: true,
                      fillColor: AppColors.inputFieldBgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Message Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Message',
                    style: AppTextStyles.bodyTextStyle,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    style: const TextStyle(color: AppColors.whiteColor),
                    decoration: InputDecoration(
                      hintText: 'Write your message here...',
                      hintStyle: AppTextStyles.hintTextStyle,
                      filled: true,
                      fillColor: AppColors.inputFieldBgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),

              //Audience Section
              Column(
                spacing: 12,
                children: [
                  // Audience Section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Audience',
                      style: AppTextStyles.subHeadingTextStyle,
                    ),
                  ),
                  _buildAudienceOption(
                    icon: Icons.group,
                    title: 'Followers',
                    subtitle: 'All followers',
                    isSelected: selectedAudience == 'Followers',
                    onTap: () => setState(() => selectedAudience = 'Followers'),
                  ),

                  _buildAudienceOption(
                    icon: Icons.groups,
                    title: 'Groups',
                    subtitle: 'Targeted groups',
                    isSelected: selectedAudience == 'Groups',
                    onTap: () => setState(() => selectedAudience = 'Groups'),
                  ),

                  _buildAudienceOption(
                    icon: Icons.person_add,
                    title: 'Custom',
                    subtitle: 'Demographics, interests, location',
                    isSelected: selectedAudience == 'Custom',
                    onTap: () => setState(() => selectedAudience = 'Custom'),
                  ),
                ],
              ),

              //Schedule Section
              Column(
                spacing: 12,
                children: [
                  // Schedule Section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Schedule',
                      style: AppTextStyles.subHeadingTextStyle,
                    ),
                  ),
                  // Schedule Options
                  _buildScheduleOption(
                    icon: Icons.access_time,
                    title: 'Now',
                    isSelected: selectedSchedule == 'Now',
                    onTap: () => setState(() => selectedSchedule = 'Now'),
                  ),

                  _buildScheduleOption(
                    icon: Icons.calendar_today,
                    title: 'Choose a specific date and time',
                    isSelected: selectedSchedule == 'Choose a specific date and time',
                    onTap: () => setState(() => selectedSchedule = 'Choose a specific date and time'),
                  ),
                ],
              ),

              
              // Send Notification Button
              PrimaryBtn(btnText: "Send Notification", icon: "", onTap: (){}, borderRadius: 99,)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudienceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.selectionItemBgColor,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.primaryColor, width: 2)
              : null,
        ),
        child: Row(
          spacing: 15,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryColor,
                size: 20,
              ),
            ),
            Expanded(
              child: Column(
                spacing: 2,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.tileTitleTextStyle,
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.hintTextStyle,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.unSelectedGreyColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleOption({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.selectionItemBgColor,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.primaryColor, width: 2)
              : null,
        ),
        child: Row(
          spacing: 15,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryColor,
                size: 20,
              ),
            ),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.tileTitleTextStyle,
              ),
            ),
            if (title == 'Now')
              Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.unSelectedGreyColor,
                size: 24,
              )
            else
              Icon(
                Icons.chevron_right,
                color: AppColors.unSelectedGreyColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}