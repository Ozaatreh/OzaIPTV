import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/diagnostics/presentation/screens/diagnostics_screen.dart';
import '../features/epg/presentation/screens/epg_screen.dart';
import '../features/favorites/presentation/screens/favorites_screen.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/live_tv/presentation/screens/live_tv_screen.dart';
import '../features/player/presentation/screens/player_screen.dart';
import '../features/search/presentation/screens/search_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import 'route_names.dart';
import 'shell_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Shell for bottom navigation
      ShellRoute(
        builder: (context, state, child) =>
            ShellScaffold(state: state, child: child),
        routes: [
          GoRoute(
            path: RoutePaths.home,
            name: RouteNames.home,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: RoutePaths.liveTv,
            name: RouteNames.liveTv,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LiveTvScreen()),
          ),
          GoRoute(
            path: RoutePaths.search,
            name: RouteNames.search,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SearchScreen()),
          ),
          GoRoute(
            path: RoutePaths.favorites,
            name: RouteNames.favorites,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FavoritesScreen()),
          ),
          GoRoute(
            path: RoutePaths.settings,
            name: RouteNames.settings,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
            routes: [
              GoRoute(
                path: 'diagnostics',
                name: RouteNames.diagnostics,
                builder: (context, state) => const DiagnosticsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Full-screen routes (outside shell)
      GoRoute(
        path: RoutePaths.player,
        name: RouteNames.player,
        builder: (context, state) {
          final channelId = state.pathParameters['channelId'] ?? '';
          return PlayerScreen(channelId: channelId);
        },
      ),
      GoRoute(
        path: RoutePaths.epg,
        name: RouteNames.epg,
        builder: (context, state) => const EpgScreen(),
      ),
      GoRoute(
        path: RoutePaths.history,
        name: RouteNames.history,
        builder: (context, state) => const HistoryScreen(),
      ),
    ],
  );
});
