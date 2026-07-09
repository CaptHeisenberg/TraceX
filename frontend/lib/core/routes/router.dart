import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/dashboard/screens/home_screen.dart';
import '../../features/alerts/screens/alerts_screen.dart';
import '../../features/alerts/screens/alert_details_screen.dart';
import '../../features/boards/screens/boards_screen.dart';
import '../../features/boards/screens/board_details_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/navigation/screens/main_navigation_shell.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/notifications/screens/notifications_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authState,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToSignup = state.matchedLocation == '/signup';
      final isGoingToForgot = state.matchedLocation == '/forgot-password';

      if (!isLoggedIn) {
        if (isGoingToLogin || isGoingToSignup || isGoingToForgot) {
          return null;
        }
        return '/login';
      }

      if (isLoggedIn && (isGoingToLogin || isGoingToSignup || isGoingToForgot)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/alerts',
            builder: (context, state) => const AlertsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final alertId = state.pathParameters['id']!;
                  return AlertDetailsScreen(defectId: alertId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/boards',
            builder: (context, state) => const BoardsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final boardId = state.pathParameters['id']!;
                  return BoardDetailsScreen(boardId: boardId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
