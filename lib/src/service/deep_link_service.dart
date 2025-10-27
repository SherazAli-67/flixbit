import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../routes/app_router.dart';
import '../routes/router_enum.dart';

/// Service for handling deep links (custom schemes and universal links)
class DeepLinkService {
  // Singleton pattern
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  // Stream subscriptions
  StreamSubscription? _uniLinksSubscription;
  StreamSubscription? _appLinksSubscription;

  // App links instance for universal links
  final AppLinks _appLinks = AppLinks();

  // SharedPreferences key for storing pending referral code
  static const String _pendingReferralCodeKey = 'pending_referral_code';
  static const String _referralAttributionSourceKey = 'referral_attribution_source';
  static const String _referralDeepLinkTimestampKey = 'referral_deeplink_timestamp';

  // Callback for when deep link is handled
  Function(String route, Map<String, dynamic> data)? _onDeepLinkReceived;

  /// Initialize deep link listeners
  Future<void> initialize() async {
    try {
      // Listen to custom scheme links (flixbit://)
      _uniLinksSubscription = linkStream.listen(
        (String? link) {
          if (link != null) {
            debugPrint('🔗 Received custom scheme link: $link');
            _handleDeepLink(Uri.parse(link), source: 'custom_scheme');
          }
        },
        onError: (err) {
          debugPrint('❌ Error listening to custom scheme links: $err');
        },
      );

      // Listen to universal links (https://)
      _appLinksSubscription = _appLinks.uriLinkStream.listen(
        (Uri? uri) {
          if (uri != null) {
            debugPrint('🔗 Received universal link: $uri');
            _handleDeepLink(uri, source: 'universal_link');
          }
        },
        onError: (err) {
          debugPrint('❌ Error listening to universal links: $err');
        },
      );

      // Check if app was launched via a deep link
      await _checkInitialLink();

      debugPrint('✅ DeepLinkService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing DeepLinkService: $e');
    }
  }

  /// Check if app was launched with an initial deep link
  Future<void> _checkInitialLink() async {
    try {
      // Check for initial custom scheme link
      final String? initialLink = await getInitialLink();
      if (initialLink != null) {
        debugPrint('🔗 App launched with custom scheme link: $initialLink');
        _handleDeepLink(Uri.parse(initialLink), source: 'custom_scheme_initial');
        return;
      }

      // Check for initial universal link
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('🔗 App launched with universal link: $initialUri');
        _handleDeepLink(initialUri, source: 'universal_link_initial');
      }
    } catch (e) {
      debugPrint('❌ Error checking initial link: $e');
    }
  }

  /// Handle incoming deep link
  Future<void> _handleDeepLink(Uri uri, {String? source}) async {
    try {
      debugPrint('📥 Processing deep link: $uri');
      debugPrint('📊 Source: $source');

      // Extract path and query parameters
      final path = uri.path;
      final queryParams = uri.queryParameters;

      debugPrint('📍 Path: $path');
      debugPrint('📋 Query params: $queryParams');

      // Handle referral deep links
      if (path.contains('/referral') || uri.host == 'referral') {
        await _handleReferralDeepLink(uri, source: source);
        return;
      }

      // Handle other deep link types (can be extended)
      debugPrint('⚠️ Unknown deep link type: $path');
    } catch (e) {
      debugPrint('❌ Error handling deep link: $e');
    }
  }

  /// Handle referral-specific deep links
  Future<void> _handleReferralDeepLink(Uri uri, {String? source}) async {
    try {
      // Extract referral code from query parameters
      final referralCode = extractReferralCode(uri);

      if (referralCode == null || referralCode.isEmpty) {
        debugPrint('⚠️ No referral code found in deep link');
        return;
      }

      debugPrint('🎟️ Extracted referral code: $referralCode');

      // Check if user is already authenticated
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User is already logged in
        debugPrint('ℹ️ User already authenticated, showing info message');
        _notifyAlreadyRegistered();
        return;
      }

      // Save referral code for later use during signup
      await savePendingReferralCode(referralCode);

      // Save attribution source
      if (source != null) {
        await _saveAttributionSource(source);
      }

      // Save timestamp
      await _saveDeepLinkTimestamp();

      debugPrint('✅ Referral code saved, navigating to signup');

      // Navigate to signup page
      await Future.delayed(const Duration(milliseconds: 500));
      appRouter.go(RouterEnum.signupView.routeName);

      // Notify listeners
      _onDeepLinkReceived?.call(
        RouterEnum.signupView.routeName,
        {'referralCode': referralCode, 'source': source},
      );
    } catch (e) {
      debugPrint('❌ Error handling referral deep link: $e');
    }
  }

  /// Extract referral code from URI query parameters
  String? extractReferralCode(Uri uri) {
    // Try 'code' parameter
    String? code = uri.queryParameters['code'];
    if (code != null && code.isNotEmpty) {
      return code.trim().toUpperCase();
    }

    // Try 'referralCode' parameter
    code = uri.queryParameters['referralCode'];
    if (code != null && code.isNotEmpty) {
      return code.trim().toUpperCase();
    }

    // Try 'ref' parameter
    code = uri.queryParameters['ref'];
    if (code != null && code.isNotEmpty) {
      return code.trim().toUpperCase();
    }

    return null;
  }

  /// Save pending referral code to SharedPreferences
  Future<void> savePendingReferralCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingReferralCodeKey, code);
      debugPrint('💾 Saved pending referral code: $code');
    } catch (e) {
      debugPrint('❌ Error saving pending referral code: $e');
    }
  }

  /// Get pending referral code from SharedPreferences
  Future<String?> getPendingReferralCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_pendingReferralCodeKey);
      debugPrint('📖 Retrieved pending referral code: $code');
      return code;
    } catch (e) {
      debugPrint('❌ Error getting pending referral code: $e');
      return null;
    }
  }

  /// Clear pending referral code from SharedPreferences
  Future<void> clearPendingReferralCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingReferralCodeKey);
      await prefs.remove(_referralAttributionSourceKey);
      await prefs.remove(_referralDeepLinkTimestampKey);
      debugPrint('🗑️ Cleared pending referral code');
    } catch (e) {
      debugPrint('❌ Error clearing pending referral code: $e');
    }
  }

  /// Save attribution source
  Future<void> _saveAttributionSource(String source) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_referralAttributionSourceKey, source);
      debugPrint('💾 Saved attribution source: $source');
    } catch (e) {
      debugPrint('❌ Error saving attribution source: $e');
    }
  }

  /// Get attribution source
  Future<String?> getAttributionSource() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_referralAttributionSourceKey);
    } catch (e) {
      debugPrint('❌ Error getting attribution source: $e');
      return null;
    }
  }

  /// Save deep link timestamp
  Future<void> _saveDeepLinkTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _referralDeepLinkTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      debugPrint('💾 Saved deep link timestamp');
    } catch (e) {
      debugPrint('❌ Error saving deep link timestamp: $e');
    }
  }

  /// Get deep link timestamp
  Future<DateTime?> getDeepLinkTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_referralDeepLinkTimestampKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting deep link timestamp: $e');
      return null;
    }
  }

  /// Calculate time elapsed since deep link was clicked
  Future<Duration?> getTimeSinceDeepLink() async {
    try {
      final timestamp = await getDeepLinkTimestamp();
      if (timestamp != null) {
        return DateTime.now().difference(timestamp);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error calculating time since deep link: $e');
      return null;
    }
  }

  /// Check if there's a pending referral code
  Future<bool> hasPendingReferralCode() async {
    final code = await getPendingReferralCode();
    return code != null && code.isNotEmpty;
  }

  /// Set callback for deep link received
  void setDeepLinkCallback(Function(String route, Map<String, dynamic> data) callback) {
    _onDeepLinkReceived = callback;
  }

  /// Notify that user is already registered
  void _notifyAlreadyRegistered() {
    // This could show a dialog or snackbar
    // For now, just log it
    debugPrint('ℹ️ User already has an account');
  }

  /// Validate referral code format (client-side validation)
  bool isValidReferralCodeFormat(String code) {
    // Expected format: 2-4 uppercase letters + 4 digits
    // Example: JOHN1234, SARA5678
    final regex = RegExp(r'^[A-Z]{2,4}\d{4}$');
    return regex.hasMatch(code);
  }

  /// Generate test deep links (for debugging)
  String generateTestDeepLink(String referralCode) {
    return 'flixbit://referral?code=$referralCode';
  }

  String generateTestUniversalLink(String referralCode) {
    return 'https://flixbit.app/referral?code=$referralCode';
  }

  /// Dispose subscriptions
  void dispose() {
    _uniLinksSubscription?.cancel();
    _appLinksSubscription?.cancel();
    debugPrint('🧹 DeepLinkService disposed');
  }
}

