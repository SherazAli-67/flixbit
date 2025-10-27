import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for handling social media sharing with deep links
class ShareService {
  // Singleton pattern
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  /// Generate deep link for referral code
  String generateDeepLink(String referralCode) {
    // Custom scheme deep link
    return 'flixbit://referral?code=$referralCode';
  }

  /// Generate universal link (HTTPS) for referral code
  String generateUniversalLink(String referralCode) {
    // Universal link - requires domain setup
    return 'https://flixbit.app/referral?code=$referralCode';
  }

  /// Generate compelling share message
  String generateShareMessage(String referralCode, String userName) {
    final deepLink = generateDeepLink(referralCode);
    final universalLink = generateUniversalLink(referralCode);
    
    return '''🎮 Join me on Flixbit! 

Hey! I've been having a blast predicting games and earning rewards on Flixbit. 

Use my referral code: $referralCode

Download the app and start earning Flixbit points:
$universalLink

Or use this link: $deepLink

Let's compete together! 🏆''';
  }

  /// Generate short share message for platforms with character limits
  String generateShortShareMessage(String referralCode) {
    final universalLink = generateUniversalLink(referralCode);
    
    return '''🎮 Join Flixbit! Use my code: $referralCode
$universalLink''';
  }

  /// Share via WhatsApp
  Future<bool> shareViaWhatsApp(String referralCode, String userName) async {
    try {
      final message = generateShareMessage(referralCode, userName);
      
      // Try WhatsApp-specific URL first
      final whatsappUrl = 'whatsapp://send?text=${Uri.encodeComponent(message)}';
      final uri = Uri.parse(whatsappUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      } else {
        // Fallback to generic share
        await Share.share(message, subject: 'Join me on Flixbit!');
        return true;
      }
    } catch (e) {
      debugPrint('Error sharing via WhatsApp: $e');
      return false;
    }
  }

  /// Share via Facebook
  Future<bool> shareViaFacebook(String referralCode, String userName) async {
    try {
      final message = generateShareMessage(referralCode, userName);
      
      // Try Facebook-specific URL
      final facebookUrl = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(generateUniversalLink(referralCode))}&quote=${Uri.encodeComponent(message)}';
      final uri = Uri.parse(facebookUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        // Fallback to generic share
        await Share.share(message, subject: 'Join me on Flixbit!');
        return true;
      }
    } catch (e) {
      debugPrint('Error sharing via Facebook: $e');
      return false;
    }
  }

  /// Share via Telegram
  Future<bool> shareViaTelegram(String referralCode, String userName) async {
    try {
      final message = generateShareMessage(referralCode, userName);
      
      // Try Telegram-specific URL
      final telegramUrl = 'https://t.me/share/url?url=${Uri.encodeComponent(generateUniversalLink(referralCode))}&text=${Uri.encodeComponent(message)}';
      final uri = Uri.parse(telegramUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        // Fallback to generic share
        await Share.share(message, subject: 'Join me on Flixbit!');
        return true;
      }
    } catch (e) {
      debugPrint('Error sharing via Telegram: $e');
      return false;
    }
  }

  /// Share via Instagram
  Future<bool> shareViaInstagram(String referralCode, String userName) async {
    try {
      final message = generateShortShareMessage(referralCode);
      
      // Instagram doesn't support direct text sharing, use generic share
      await Share.share(message, subject: 'Join me on Flixbit!');
      return true;
    } catch (e) {
      debugPrint('Error sharing via Instagram: $e');
      return false;
    }
  }

  /// Share via Snapchat
  Future<bool> shareViaSnapchat(String referralCode, String userName) async {
    try {
      final message = generateShortShareMessage(referralCode);
      
      // Snapchat doesn't support direct text sharing, use generic share
      await Share.share(message, subject: 'Join me on Flixbit!');
      return true;
    } catch (e) {
      debugPrint('Error sharing via Snapchat: $e');
      return false;
    }
  }

  /// Generic share method (fallback)
  Future<bool> shareGeneric(String referralCode, String userName) async {
    try {
      final message = generateShareMessage(referralCode, userName);
      await Share.share(message, subject: 'Join me on Flixbit!');
      return true;
    } catch (e) {
      debugPrint('Error sharing generically: $e');
      return false;
    }
  }

  /// Share via specific app based on app name
  Future<bool> shareViaApp(String app, String referralCode, String userName) async {
    switch (app.toLowerCase()) {
      case 'whatsapp':
        return await shareViaWhatsApp(referralCode, userName);
      case 'facebook':
        return await shareViaFacebook(referralCode, userName);
      case 'telegram':
        return await shareViaTelegram(referralCode, userName);
      case 'instagram':
        return await shareViaInstagram(referralCode, userName);
      case 'snapchat':
        return await shareViaSnapchat(referralCode, userName);
      default:
        return await shareGeneric(referralCode, userName);
    }
  }

  /// Copy referral code to clipboard
  Future<bool> copyReferralCode(String referralCode) async {
    try {
      await Share.share(referralCode, subject: 'My Flixbit Referral Code');
      return true;
    } catch (e) {
      debugPrint('Error copying referral code: $e');
      return false;
    }
  }

  /// Get available sharing options
  List<String> getAvailableApps() {
    return ['whatsapp', 'facebook', 'telegram', 'instagram', 'snapchat'];
  }

  /// Check if specific app is available for sharing
  Future<bool> isAppAvailable(String app) async {
    try {
      switch (app.toLowerCase()) {
        case 'whatsapp':
          final uri = Uri.parse('whatsapp://send');
          return await canLaunchUrl(uri);
        case 'facebook':
          final uri = Uri.parse('https://www.facebook.com');
          return await canLaunchUrl(uri);
        case 'telegram':
          final uri = Uri.parse('https://t.me');
          return await canLaunchUrl(uri);
        case 'instagram':
          final uri = Uri.parse('instagram://app');
          return await canLaunchUrl(uri);
        case 'snapchat':
          final uri = Uri.parse('snapchat://app');
          return await canLaunchUrl(uri);
        default:
          return true; // Generic share always available
      }
    } catch (e) {
      debugPrint('Error checking app availability: $e');
      return false;
    }
  }
}
