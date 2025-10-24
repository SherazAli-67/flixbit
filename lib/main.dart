import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flixbit/src/providers/authentication_provider.dart';
import 'package:flixbit/src/providers/linked_accounts_provider.dart';
import 'package:flixbit/src/providers/locale_provider.dart';
import 'package:flixbit/src/providers/profile_provider.dart';
import 'package:flixbit/src/providers/tab_change_provider.dart';
import 'package:flixbit/src/providers/reviews_provider.dart';
import 'package:flixbit/src/providers/wallet_provider.dart';
import 'package:flixbit/src/providers/offers_provider.dart';
import 'package:flixbit/src/providers/seller_offers_provider.dart';
import 'package:flixbit/src/providers/notification_provider.dart';
import 'package:flixbit/src/service/fcm_service.dart';
import 'package:flixbit/src/res/app_colors.dart';
import 'package:flixbit/src/res/app_constants.dart';
import 'package:flixbit/src/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize FCM
  await FCMService().initialize();
  
  // Setup background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool initialIsSeller = prefs.getBool('isSeller') ?? false;

  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_)=> LocaleProvider()),
        ChangeNotifierProvider(create: (_)=> MainMenuTabChangeProvider()),
        ChangeNotifierProvider(create: (_)=> AuthenticationProvider()),
        ChangeNotifierProvider(create: (_)=> ReviewsProvider()),
        ChangeNotifierProvider(create: (_)=> LinkedAccountsProvider(initialIsSellerAccount: initialIsSeller)),
        ChangeNotifierProvider(create: (_)=> ProfileProvider()),
        ChangeNotifierProvider(create: (_)=> WalletProvider()),
        ChangeNotifierProvider(create: (_)=> OffersProvider()),
        ChangeNotifierProvider(create: (_)=> SellerOffersProvider()),
        ChangeNotifierProvider(create: (_)=> NotificationProvider()),
      ],
      child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp.router(
          title: AppConstants.appTitle,
          themeMode: ThemeMode.dark,
          locale: localeProvider.currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LocaleProvider.supportedLocales,
          builder: (context, child) {
            return Directionality(
              textDirection: localeProvider.isArabic ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            );
          },
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: AppConstants.appFontFamily,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: AppColors.primaryColor,
          primary: AppColors.primaryColor,
          onPrimary: Colors.white,
          surface: AppColors.darkBgColor,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.darkBgColor,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkBgColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.darkBgColor,
          selectedItemColor: AppColors.primaryColor,
          unselectedItemColor: AppColors.unSelectedGreyColor,
          type: BottomNavigationBarType.fixed,
        ),
        iconTheme: IconThemeData(color: AppColors.unSelectedGreyColor),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: AppConstants.appFontFamily,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: AppColors.primaryColor,
          primary: AppColors.primaryColor,
          onPrimary: Colors.white,
          surface: AppColors.darkBgColor,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.darkBgColor,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkBgColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.darkBgColor,
          selectedItemColor: AppColors.primaryColor,
          unselectedItemColor: AppColors.unSelectedGreyColor,
          type: BottomNavigationBarType.fixed,
        ),
        iconTheme: IconThemeData(color: AppColors.unSelectedGreyColor),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
        );
      },
    );
  }
}
