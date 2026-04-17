import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/loading_screen.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/events/presentation/pages/events_page.dart';
import '../../features/events/presentation/pages/events_list_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/bookings/presentation/pages/bookings_page.dart';
import '../../features/bookings/presentation/pages/ticket_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/admin/presentation/pages/manage_events_page.dart';
import '../../features/events/presentation/pages/event_detail_page.dart';
import '../../features/cart/presentation/pages/checkout_page.dart';
import '../../features/cart/presentation/pages/payment_page.dart';
import '../../features/cart/presentation/pages/booking_success_page.dart';
import '../../features/scan/presentation/scan_screen.dart';
import '../../shared/layout/main_layout.dart';
import 'router_notifier.dart';

import '../navigation/navigation_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/loading',
    refreshListenable: notifier,

    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.isAuthenticated;

      if (isLoading) {
        if (state.uri.path == '/login') return null;
        if (state.uri.path == '/loading') return null;
        return '/loading';
      }

      if (!isLoggedIn && state.uri.path != '/login') {
        return '/login';
      }

      if (isLoggedIn &&
          (state.uri.path == '/login' || state.uri.path == '/loading')) {
        return '/home';
      }

      return null;
    },

    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/loading',
        builder: (context, state) => const LoadingScreen(),
      ),
      GoRoute(
        path: '/events-list',
        builder: (context, state) {
          final type = state.uri.queryParameters['type'] ?? 'regular';
          return EventsListPage(type: type);
        },
      ),

      GoRoute(
        path: '/event-details/:id',
        builder: (context, state) {
          return EventDetailPage(eventId: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/booking-success/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'Unknown';
          return BookingSuccessPage(bookingId: id);
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        path: '/ticket/:id',
        builder: (context, state) {
          return TicketPage(
            bookedEventId: int.tryParse(state.pathParameters['id'] ?? '0') ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) {
          final totalAmount = state.extra as num? ?? 0;
          return PaymentPage(totalAmount: totalAmount);
        },
      ),
      GoRoute(path: '/scan', builder: (context, state) => const ScanScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/events',
                builder: (context, state) => const EventsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cart',
                builder: (context, state) => const CartPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookings',
                builder: (context, state) => const BookingsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/manage',
                builder: (context, state) => const ManageEventsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
