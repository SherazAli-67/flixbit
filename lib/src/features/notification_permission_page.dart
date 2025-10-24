import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../res/app_colors.dart';
import '../res/apptextstyles.dart';
import '../service/fcm_service.dart';

class NotificationPermissionPage extends StatefulWidget {
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  const NotificationPermissionPage({
    super.key,
    this.onPermissionGranted,
    this.onPermissionDenied,
  });

  @override
  State<NotificationPermissionPage> createState() => _NotificationPermissionPageState();
}

class _NotificationPermissionPageState extends State<NotificationPermissionPage> {
  bool _isRequesting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active,
                  size: 60,
                  color: AppColors.primaryColor,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Stay Updated!',
                style: AppTextStyles.headingTextStyle.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                'Get instant notifications about your rewards, tournament wins, and special offers.',
                style: AppTextStyles.bodyTextStyle.copyWith(
                  color: AppColors.lightGreyColor,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Benefits list
              _buildBenefitsList(),
              
              const Spacer(),
              
              // Buttons
              Column(
                spacing: 16,
                children: [
                  // Enable notifications button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isRequesting ? null : _enableNotifications,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.whiteColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isRequesting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.whiteColor,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Enable Notifications',
                              style: AppTextStyles.subHeadingTextStyle.copyWith(
                                color: AppColors.whiteColor,
                              ),
                            ),
                    ),
                  ),
                  
                  // Maybe later button
                  TextButton(
                    onPressed: _isRequesting ? null : _skipNotifications,
                    child: Text(
                      'Maybe Later',
                      style: AppTextStyles.bodyTextStyle.copyWith(
                        color: AppColors.lightGreyColor,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitsList() {
    final benefits = [
      {
        'icon': Icons.card_giftcard,
        'title': 'Reward Updates',
        'description': 'Know when your rewards are ready to use',
      },
      {
        'icon': Icons.schedule,
        'title': 'Expiry Reminders',
        'description': 'Get warned before rewards expire',
      },
      {
        'icon': Icons.local_shipping,
        'title': 'Shipping Updates',
        'description': 'Track your physical rewards',
      },
      {
        'icon': Icons.emoji_events,
        'title': 'Tournament Wins',
        'description': 'Celebrate your victories instantly',
      },
    ];

    return Column(
      spacing: 16,
      children: benefits.map((benefit) => _buildBenefitItem(
        benefit['icon'] as IconData,
        benefit['title'] as String,
        benefit['description'] as String,
      )).toList(),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.darkGreyColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        spacing: 16,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryColor,
              size: 24,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyTextStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: AppTextStyles.smallTextStyle.copyWith(
                    color: AppColors.lightGreyColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enableNotifications() async {
    setState(() => _isRequesting = true);

    try {
      final fcmService = FCMService();
      final granted = await fcmService.requestPermission();

      if (granted) {
        // Initialize FCM if permission granted
        await fcmService.initialize();
        
        if (mounted) {
          widget.onPermissionGranted?.call();
          context.pop();
        }
      } else {
        if (mounted) {
          _showPermissionDeniedDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to enable notifications. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  void _skipNotifications() {
    widget.onPermissionDenied?.call();
    context.pop();
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBgColor,
        title: Text(
          'Notifications Disabled',
          style: AppTextStyles.subHeadingTextStyle,
        ),
        content: Text(
          'You can enable notifications later in your device settings to stay updated about your rewards and activities.',
          style: AppTextStyles.smallTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'OK',
              style: AppTextStyles.smallTextStyle.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBgColor,
        title: Text(
          'Error',
          style: AppTextStyles.subHeadingTextStyle,
        ),
        content: Text(
          message,
          style: AppTextStyles.smallTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'OK',
              style: AppTextStyles.smallTextStyle.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

