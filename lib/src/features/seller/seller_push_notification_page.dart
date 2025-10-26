import 'package:flixbit/src/widgets/primary_btn.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../res/app_colors.dart';
import '../../res/apptextstyles.dart';
import '../../models/qr_notification_campaign_model.dart';
import '../../service/qr_notification_service.dart';
import '../../service/notification_quota_service.dart';

class SellerPushNotificationPage extends StatefulWidget {
  const SellerPushNotificationPage({super.key});

  @override
  State<SellerPushNotificationPage> createState() => _SellerPushNotificationPageState();
}

class _SellerPushNotificationPageState extends State<SellerPushNotificationPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  NotificationAudience selectedAudience = NotificationAudience.allFollowers;
  String selectedSchedule = 'Now';
  DateTime? scheduledDateTime;
  bool _isLoading = false;
  int _audienceCount = 0;
  QuotaInfo? _quotaInfo;
  final QRNotificationService _notificationService = QRNotificationService();

  @override
  void initState() {
    super.initState();
    _updateAudienceCount();
    _loadQuotaInfo();
  }

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
                    onPressed: () => context.pop(),
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
                  
                  // Audience Count Display
                  if (_audienceCount > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.people,
                            color: AppColors.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Target Audience: $_audienceCount followers',
                            style: AppTextStyles.bodyTextStyle.copyWith(
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Quota Information Display
                  if (_quotaInfo != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _quotaInfo!.isNearLimit 
                            ? Colors.orange.withValues(alpha: 0.1)
                            : AppColors.successColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _quotaInfo!.isNearLimit 
                              ? Colors.orange.withValues(alpha: 0.3)
                              : AppColors.successColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        spacing: 8,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _quotaInfo!.isNearLimit ? Icons.warning : Icons.check_circle,
                                color: _quotaInfo!.isNearLimit ? Colors.orange : AppColors.successColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Notification Quota: ${_quotaInfo!.remainingDisplayText} remaining',
                                  style: AppTextStyles.bodyTextStyle.copyWith(
                                    color: _quotaInfo!.isNearLimit ? Colors.orange : AppColors.successColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Usage: ${_quotaInfo!.usageDisplayText}',
                                style: AppTextStyles.hintTextStyle,
                              ),
                              Text(
                                _quotaInfo!.resetDateDisplayText,
                                style: AppTextStyles.hintTextStyle,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  _buildAudienceOption(
                    icon: Icons.group,
                    title: 'All Followers',
                    subtitle: 'All followers',
                    isSelected: selectedAudience == NotificationAudience.allFollowers,
                    onTap: () => _selectAudience(NotificationAudience.allFollowers),
                  ),

                  _buildAudienceOption(
                    icon: Icons.qr_code,
                    title: 'QR Scan Followers',
                    subtitle: 'Followers from QR scans',
                    isSelected: selectedAudience == NotificationAudience.qrScanFollowers,
                    onTap: () => _selectAudience(NotificationAudience.qrScanFollowers),
                  ),

                  _buildAudienceOption(
                    icon: Icons.local_offer,
                    title: 'Offer Followers',
                    subtitle: 'Followers from offer redemptions',
                    isSelected: selectedAudience == NotificationAudience.offerFollowers,
                    onTap: () => _selectAudience(NotificationAudience.offerFollowers),
                  ),

                  _buildAudienceOption(
                    icon: Icons.person_add,
                    title: 'Recent Followers',
                    subtitle: 'Followers from last 30 days',
                    isSelected: selectedAudience == NotificationAudience.dateRangeFollowers,
                    onTap: () => _selectAudience(NotificationAudience.dateRangeFollowers),
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
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    )
                  : PrimaryBtn(
                      btnText: selectedSchedule == 'Now' ? "Send Notification" : "Schedule Notification",
                      icon: "",
                      onTap: _sendNotification,
                      borderRadius: 99,
                    )
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
                color: AppColors.primaryColor.withValues(alpha: 0.2),
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
                color: AppColors.primaryColor.withValues(alpha: 0.2),
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

  // Select audience and update count
  void _selectAudience(NotificationAudience audience) {
    setState(() => selectedAudience = audience);
    _updateAudienceCount();
  }

  // Update audience count based on selected audience
  Future<void> _updateAudienceCount() async {
    try {
      final sellerId = FirebaseAuth.instance.currentUser?.uid;
      if (sellerId == null) return;

      Map<String, dynamic>? filters;
      if (selectedAudience == NotificationAudience.dateRangeFollowers) {
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        filters = {
          'startDate': thirtyDaysAgo.toIso8601String(),
          'endDate': DateTime.now().toIso8601String(),
        };
      }

      final count = await _notificationService.getAudienceCount(
        sellerId: sellerId,
        audience: selectedAudience,
        filters: filters,
      );

      setState(() => _audienceCount = count);
    } catch (e) {
      debugPrint('Failed to get audience count: $e');
      setState(() => _audienceCount = 0);
    }
  }

  // Load quota information
  Future<void> _loadQuotaInfo() async {
    try {
      final sellerId = FirebaseAuth.instance.currentUser?.uid;
      if (sellerId == null) return;

      final quotaInfo = await _notificationService.getSellerQuota(sellerId);
      setState(() => _quotaInfo = quotaInfo);
    } catch (e) {
      debugPrint('Failed to load quota info: $e');
    }
  }

  // Send notification
  Future<void> _sendNotification() async {
    // Validate inputs
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a notification title');
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a notification message');
      return;
    }

    if (_audienceCount == 0) {
      _showErrorSnackBar('No followers found for the selected audience');
      return;
    }

    // Check quota availability
    if (_quotaInfo != null && _quotaInfo!.remainingQuota < _audienceCount) {
      _showErrorSnackBar('Insufficient quota. You have ${_quotaInfo!.remainingQuota} notifications remaining, but need $_audienceCount.');
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final sellerId = FirebaseAuth.instance.currentUser?.uid;
      if (sellerId == null) {
        throw Exception('User not authenticated');
      }

      Map<String, dynamic>? filters;
      if (selectedAudience == NotificationAudience.dateRangeFollowers) {
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        filters = {
          'startDate': thirtyDaysAgo.toIso8601String(),
          'endDate': DateTime.now().toIso8601String(),
        };
      }

      // Create campaign
      final campaignId = await _notificationService.createCampaign(
        sellerId: sellerId,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        audience: selectedAudience,
        filters: filters,
        scheduledFor: selectedSchedule == 'Choose a specific date and time' 
            ? scheduledDateTime 
            : null,
        actionRoute: '/offers_view',
        actionText: 'View Offers',
      );

      // Send or schedule campaign
      if (selectedSchedule == 'Now') {
        await _notificationService.sendCampaign(campaignId);
        _showSuccessSnackBar('Notification sent successfully to $_audienceCount followers');
      } else {
        if (scheduledDateTime == null) {
          throw Exception('Please select a date and time for scheduling');
        }
        await _notificationService.scheduleCampaign(campaignId, scheduledDateTime!);
        _showSuccessSnackBar('Notification scheduled for ${_formatDateTime(scheduledDateTime!)}');
      }

      // Navigate back
      context.pop();
    } catch (e) {
      _showErrorSnackBar('Failed to send notification: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Show confirmation dialog
  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBgColor,
        title: const Text(
          'Confirm Notification',
          style: TextStyle(color: AppColors.whiteColor),
        ),
        content: Text(
          'Send notification to $_audienceCount followers?',
          style: const TextStyle(color: AppColors.whiteColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    ) ?? false;
  }

  // Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Format datetime for display
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}