import 'package:flixbit/src/constants/app_constants.dart';
import 'package:flixbit/src/constants/app_colors.dart';
import 'package:flixbit/src/providers/tab_change_provider.dart';
import 'package:flixbit/src/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {

  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_)=> MainMenuTabChangeProvider()),
      ],
      child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appTitle,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        brightness: Brightness.dark,
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
  }
}
