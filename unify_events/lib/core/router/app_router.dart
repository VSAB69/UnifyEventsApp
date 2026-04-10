import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/home_screen.dart';
import 'router_notifier.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier, // 🔥 KEY FIX

    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.isAuthenticated;

      if (isLoading) {
        if (state.uri.path == '/login') return null;
        return '/splash';
      }

      if (!isLoggedIn && state.uri.path != '/login') {
        return '/login';
      }

      if (isLoggedIn &&
          (state.uri.path == '/login' || state.uri.path == '/splash')) {
        return '/';
      }

      return null;
    },

    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
    ],
  );
});
