import 'package:firebase_auth/firebase_auth.dart';
import 'package:flixbit/src/features/authentication/login_page.dart';
import 'package:flixbit/src/features/authentication/signup_page.dart';
import 'package:flixbit/src/routes/router_enum.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flixbit/src/features/main_menu_page.dart';
import 'package:flixbit/src/features/home_page.dart';
import 'package:flixbit/src/features/offers_page.dart';
import 'package:flixbit/src/features/wallet_page.dart';
import 'package:flixbit/src/features/profile_page.dart';
import 'package:flixbit/src/features/welcome_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: RouterEnum.loginView.routeName,
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
    StatefulShellRoute.indexedStack(
      builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) {
        return MainMenuPage(navigationShell: navigationShell);
      },
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: RouterEnum.homeView.routeName,
              builder: (BuildContext context, GoRouterState state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: RouterEnum.offersView.routeName,
              builder: (BuildContext context, GoRouterState state) => const OffersPage(),
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
  /*redirect: (context, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final goingTo = state.matchedLocation;

    // Routes that don't require auth
    final publicPaths = [
      RouterEnum.loginView.routeName,
      RouterEnum.welcomeView.routeName,
      RouterEnum.signupView.routeName,
      // Temporarily allow home for post-signup navigation before auth wiring
      RouterEnum.homeView.routeName,
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
  },*/
  errorBuilder: (BuildContext context, GoRouterState state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text(state.error?.toString() ?? 'Page not found')),
    );
  },
);


