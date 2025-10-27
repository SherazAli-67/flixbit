import 'package:firebase_auth/firebase_auth.dart';
import 'package:flixbit/src/models/notification_preferences_model.dart';
import 'package:flixbit/src/res/app_colors.dart';
import 'package:flixbit/src/res/apptextstyles.dart';
import 'package:flutter/material.dart';

import '../../../service/notification_preferences_service.dart';

class NotificationPreferencesItemWidget extends StatelessWidget{
  const NotificationPreferencesItemWidget({
    super.key,
    required String title,
    required String subTitle,
    required IconData leadingIcon,
    required bool isEnabled,
    NotificationPreferences? preferences,
    required String notificationType,
    bool isPushNotification = false,
    bool isSeller = false,
    String? sellerID
  })
      : _title = title,
        _subTitle = subTitle,
        _leadingIcon = leadingIcon,
  _isEnabled = isEnabled,
  _preferences = preferences,
  _notificationType = notificationType,
  _isPushNotification = isPushNotification,
  _isSeller = isSeller,
  _sellerID = sellerID
  ;
  
  final String _title;
  final String _subTitle;
  final IconData _leadingIcon;
  final bool _isEnabled;
  final NotificationPreferences? _preferences;
  final String _notificationType;
  final bool _isPushNotification;
  final bool _isSeller;
  final String? _sellerID;
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(value: _isEnabled,
      onChanged: (val) => _isPushNotification ? _onValChange(val, context) : _isSeller
          ? _toggleSellerNotification(_sellerID!, val, context)
          : _toggleNotificationType(_notificationType, val, context),
      contentPadding: EdgeInsets.symmetric(horizontal: 10),
      secondary: Icon(_leadingIcon, color: AppColors.primaryColor,),
      title: Text(_title, style: AppTextStyles.tileTitleTextStyle,),
      subtitle: Text(_subTitle, style: AppTextStyles.smallTextStyle,),);
  }


  Future<void> _onValChange(bool val, BuildContext context) async {
    final updated = _preferences?.copyWith(
      pushNotificationsEnabled: val,
      updatedAt: DateTime.now(),
    );

    debugPrint("Updating push notification: ${updated == null}");
    if (updated == null) return;

    String currentUID = FirebaseAuth.instance.currentUser!.uid;
    final NotificationPreferencesService preferencesService = NotificationPreferencesService();

    final success = await preferencesService.updatePreferences(currentUID, updated);
    if (success) {
      // setState(()=> _preferences = updated);
      _showSuccessSnackBar('Notification settings updated', context);
    } else {
      _showErrorSnackBar('Failed to update settings', context);
    }
  }

  void _showSuccessSnackBar(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleNotificationType(String type, bool value, BuildContext context) async {
    final NotificationPreferencesService preferencesService = NotificationPreferencesService();

    final success = await preferencesService.toggleNotificationType(type, value);
    if (success) {
      _showSuccessSnackBar('Notification preference updated', context);
    } else {
      _showErrorSnackBar('Failed to update preference', context);
    }
  }

  Future<void> _toggleSellerNotification(String sellerId, bool value, BuildContext context) async {
    final NotificationPreferencesService preferencesService = NotificationPreferencesService();

    final success = await preferencesService.setPerSellerPreference(sellerId, value);
    if (success) {
      _showSuccessSnackBar('Seller notification updated', context);
    } else {
      _showErrorSnackBar('Failed to update seller notification', context);
    }
  }

}