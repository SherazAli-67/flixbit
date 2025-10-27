import 'package:firebase_auth/firebase_auth.dart';
import 'package:flixbit/src/features/main_menu/profile_page/notification_preferences_item_widget.dart';
import 'package:flixbit/src/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../res/app_colors.dart';
import '../../../res/apptextstyles.dart';
import '../../../models/notification_preferences_model.dart';
import '../../../service/notification_preferences_service.dart';

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  State<NotificationPreferencesPage> createState() => _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState extends State<NotificationPreferencesPage> {
  final NotificationPreferencesService _preferencesService = NotificationPreferencesService();

  NotificationPreferences? _preferences;
  List<Map<String, dynamic>> _followedSellers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: ()=> context.pop(),
        ),
      ),
      body: StreamBuilder(stream: _preferencesService.getUserPreferencesStream(), builder: (_, snapshot){
        if(snapshot.connectionState == ConnectionState.waiting){
          return LoadingWidget();
        }else if(snapshot.hasError){
          return  Center(child: Text('Failed to load preferences: ${snapshot.error.toString()}'));
        }else if(snapshot.hasData && snapshot.data != null){
          _preferences = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                  color: AppColors.cardBgColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: NotificationPreferencesItemWidget(
                    title: 'Push Notifications',
                    subTitle: "Enable or disable all push notifications",
                    leadingIcon: Icons.notifications,
                    isEnabled: _preferences!.pushNotificationsEnabled,
                    notificationType: 'push_notification',
                    isPushNotification: true,
                  )),
              // _buildMasterToggle(),
              const SizedBox(height: 24),
              _buildQRNotificationsSection(),
              const SizedBox(height: 24),
              _buildOtherNotificationsSection(),
              const SizedBox(height: 24),
              FutureBuilder(future: _preferencesService.getFollowedSellers(FirebaseAuth.instance.currentUser!.uid), builder: (_, snapshot){
                if(snapshot.hasData){
                  _followedSellers = snapshot.requireData;
                  return _buildPerSellerSection();
                }else if(snapshot.hasError){
                  return const Text("Failed to load followed sellers");
                }else if(snapshot.connectionState == ConnectionState.waiting){
                  return LoadingWidget();
                }

                return SizedBox();
              })
            ],
          );
        }

        return SizedBox();
      })
    );
  }


  Widget _buildQRNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text('QR System Notifications', style: AppTextStyles.tileTitleTextStyle),
        Card(
          color: AppColors.cardBgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              NotificationPreferencesItemWidget(
                  title: 'Welcome Notifications',
                  subTitle: 'After redeeming an offer',
                  leadingIcon: Icons.waving_hand,
                  isEnabled: _preferences?.qrWelcomeEnabled ?? true,
                  notificationType: 'welcome'),
              const Divider(height: 1, color: Colors.white12),
              NotificationPreferencesItemWidget(
                  title: 'Thank You Notifications',
                  subTitle: 'When offers are expiring soon',
                  leadingIcon: Icons.alarm,
                  isEnabled: _preferences?.qrThankYouEnabled ?? true,
                  notificationType: 'thank_you'),
              const Divider(height: 1, color: Colors.white12),
              NotificationPreferencesItemWidget(
                  title: 'Offer Reminders',
                  subTitle: 'After scanning a QR code',
                  leadingIcon: Icons.volunteer_activism,
                  isEnabled: _preferences?.qrOfferReminderEnabled ?? true,
                  notificationType: 'offer_reminder'),

              const Divider(height: 1, color: Colors.white12),
              NotificationPreferencesItemWidget(
                  title: 'Re-engagement',
                  subTitle: 'When you haven\'t visited in a while',
                  leadingIcon: Icons.favorite,
                  isEnabled: _preferences?.qrReEngagementEnabled ?? true,
                  notificationType: 're_engagement'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtherNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text('Other Notifications', style: AppTextStyles.tileTitleTextStyle),
        Card(
          color: AppColors.cardBgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              NotificationPreferencesItemWidget(
                title: 'Reward Notifications',
                subTitle: 'Updates about rewards',
                leadingIcon: Icons.card_giftcard,
                isEnabled: _preferences?.rewardNotificationsEnabled ?? true,
                notificationType: 'reward_redemption',
              ),
              const Divider(height: 1, color: Colors.white12),
              NotificationPreferencesItemWidget(
                title: 'Tournament Notifications',
                subTitle: 'Tournament results and wins',
                leadingIcon: Icons.emoji_events,
                isEnabled: _preferences?.tournamentNotificationsEnabled ?? true,
                notificationType: 'tournament_win',
              ),
              const Divider(height: 1, color: Colors.white12),
              NotificationPreferencesItemWidget(
                title: 'Offer Notifications',
                subTitle: 'New offers available',
                leadingIcon: Icons.local_offer,
                isEnabled:  _preferences?.offerNotificationsEnabled ?? true,
                notificationType: 'offer_available',
              ),
              const Divider(height: 1, color: Colors.white12),
              NotificationPreferencesItemWidget(
                title: 'Points Notifications',
                subTitle: 'When you earn points',
                leadingIcon: Icons.stars,
                isEnabled: _preferences?.pointsNotificationsEnabled ?? true,
                notificationType: 'points_earned',
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildPerSellerSection() {
    if (_followedSellers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Per-Seller Notifications', style: AppTextStyles.tileTitleTextStyle),

          ],
        ),
        Card(
          color: AppColors.cardBgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: _followedSellers.asMap().entries.map((entry) {
              final index = entry.key;
              final seller = entry.value;
              final sellerId = seller['sellerId'] as String;
              final sellerName = seller['sellerName'] as String;
              final isEnabled = _preferences?.isSellerNotificationEnabled(sellerId) ?? true;

              return Column(
                children: [
                  if (index > 0) const Divider(height: 1, color: Colors.white12),
                  NotificationPreferencesItemWidget(
                      title: sellerName,
                      subTitle: '',
                      leadingIcon: Icons.store,
                      isEnabled: isEnabled,
                      notificationType: 'seller',
                    isSeller: true,
                    sellerID: sellerId,
                  )
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

}