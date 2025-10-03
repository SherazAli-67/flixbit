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
  initialLocation: RouterEnum.homeView.routeName,
  routes: <RouteBase>[
    GoRoute(
      path: RouterEnum.welcomeView.routeName,
      name: 'welcome',
      builder: (BuildContext context, GoRouterState state) => const WelcomePage(),
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
  errorBuilder: (BuildContext context, GoRouterState state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text(state.error?.toString() ?? 'Page not found')),
    );
  },
);


