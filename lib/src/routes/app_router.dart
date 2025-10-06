import 'package:firebase_auth/firebase_auth.dart';
import 'package:flixbit/src/features/authentication/login_page.dart';
import 'package:flixbit/src/features/authentication/signup_page.dart';
import 'package:flixbit/src/features/main_menu/qr_scanner_page.dart';
import 'package:flixbit/src/features/referral_page.dart';
import 'package:flixbit/src/features/rewards_page.dart';
import 'package:flixbit/src/features/subscription_plans_page.dart';
import 'package:flixbit/src/features/wheel_of_fortune_page.dart';
import 'package:flixbit/src/features/video_ads/video_ads_list_page.dart';
import 'package:flixbit/src/routes/router_enum.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flixbit/src/features/main_menu_page.dart';
import 'package:flixbit/src/features/main_menu/dashboard_flow/dashboard_page.dart';
import 'package:flixbit/src/features/offers_page.dart';
import 'package:flixbit/src/features/main_menu/wallet_page.dart';
import 'package:flixbit/src/features/main_menu/profile_page.dart';
import 'package:flixbit/src/features/welcome_page.dart';

import '../features/game_prediction/game_prediction_page.dart';
import '../features/game_prediction/tournament_matches_page.dart';
import '../features/game_prediction/make_prediction_page.dart';
import '../models/match_model.dart';
import '../models/tournament_model.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: RouterEnum.homeView.routeName,
  routes: <RouteBase>[
    GoRoute(
      path: RouterEnum.welcomeView.routeName,
      builder: (BuildContext context, GoRouterState state) => const WelcomePage(),
    ),
    GoRoute(
      path: RouterEnum.loginView.routeName,
      builder: (BuildContext context, GoRouterState state) => const LoginPage(),
    ),
    GoRoute(
      path: RouterEnum.signupView.routeName,
      builder: (BuildContext context, GoRouterState state) => const SignupPage(),
    ),
    GoRoute(
      path: RouterEnum.subscriptionView.routeName,
      builder: (BuildContext context, GoRouterState state) => const SubscriptionPlansPage(),
    ),
    GoRoute(
      path: RouterEnum.rewardsView.routeName,
      builder: (BuildContext context, GoRouterState state) => const RewardsPage(),
    ),
    GoRoute(
      path: RouterEnum.offersView.routeName,
      builder: (BuildContext context, GoRouterState state) => const OffersPage(),
    ),
    GoRoute(
      path: RouterEnum.videoAdsView.routeName,
      builder: (BuildContext context, GoRouterState state) => const VideoAdsListPage(),
    ),
    GoRoute(
      path: RouterEnum.referralView.routeName,
      builder: (BuildContext context, GoRouterState state) => const ReferralPage(),
    ),
    GoRoute(
      path: RouterEnum.wheelOfFortuneView.routeName,
      builder: (BuildContext context, GoRouterState state) => const WheelOfFortunePage(),
    ),
    GoRoute(
      path: RouterEnum.gamePredictionView.routeName,
      builder: (BuildContext context, GoRouterState state) => const GamePredicationPage(),
    ),
    GoRoute(
      path: RouterEnum.tournamentMatchesView.routeName,
      builder: (BuildContext context, GoRouterState state) {
        final tournamentId = state.uri.queryParameters['tournamentId'] ?? '';
        return TournamentMatchesPage(tournamentId: tournamentId);
      },
    ),
    GoRoute(
      path: RouterEnum.makePredictionView.routeName,
      builder: (BuildContext context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>;
        return MakePredictionPage(
          match: extra['match'] as Match,
          tournament: extra['tournament'] as Tournament,
        );
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) {
        return MainMenuPage(navigationShell: navigationShell);
      },
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: RouterEnum.homeView.routeName,
              builder: (BuildContext context, GoRouterState state) => const DashboardPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: RouterEnum.qrScannerView.routeName,
              builder: (BuildContext context, GoRouterState state) => const ScannerPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: RouterEnum.walletView.routeName,
              builder: (BuildContext context, GoRouterState state) => const WalletPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: RouterEnum.profileView.routeName,
              builder: (BuildContext context, GoRouterState state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
  ],
  redirect: (context, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final goingTo = state.matchedLocation;

    // Routes that don't require auth
    final publicPaths = [
      RouterEnum.loginView.routeName,
      RouterEnum.welcomeView.routeName,
      RouterEnum.signupView.routeName,
    ];

    if (!loggedIn && !publicPaths.contains(goingTo)) {
      // Not logged in and trying to access a private route
      return RouterEnum.loginView.routeName;
    }

    if (loggedIn && publicPaths.contains(goingTo)) {
      // Logged in and trying to access public route (e.g., login or welcome)
      return RouterEnum.homeView.routeName;
    }

    return null;
  },
  errorBuilder: (BuildContext context, GoRouterState state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text(state.error?.toString() ?? 'Page not found')),
    );
  },
);
