import 'package:flixbit/src/constants/app_constants.dart';
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: appRouter,
    );
  }
}
