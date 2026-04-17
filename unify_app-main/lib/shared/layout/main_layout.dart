import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../widgets/cyber_grid_background.dart';

class MainLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout>
    with TickerProviderStateMixin {
  DateTime? _lastPressedAt;

  void _onTap(int index, List<String> availableRoutes) {
    // Map visual index to route
    final route = availableRoutes[index];

    if (route == 'scan') {
      context.push('/scan');
      return;
    }

    int shellIndex = 0;

    // Find the corresponding shell index for the route
    if (route == 'home')
      shellIndex = 0;
    else if (route == 'events')
      shellIndex = 1;
    else if (route == 'cart')
      shellIndex = 2;
    else if (route == 'bookings')
      shellIndex = 3;
    else if (route == 'manage')
      shellIndex = 4;
    else if (route == 'profile')
      shellIndex = 5;

    widget.navigationShell.goBranch(
      shellIndex,
      initialLocation: shellIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isManager = user?.isAdmin == true || user?.isOrganiser == true;

    // Define available tabs based on role
    final List<Map<String, dynamic>> tabs = [
      {
        'route': 'home',
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home,
        'label': 'Home',
      },
      {
        'route': 'events',
        'icon': Icons.explore_outlined,
        'activeIcon': Icons.explore,
        'label': 'Events',
      },
      {
        'route': 'cart',
        'icon': Icons.shopping_cart_outlined,
        'activeIcon': Icons.shopping_cart,
        'label': 'Cart',
      },
      {
        'route': 'bookings',
        'icon': Icons.calendar_today_outlined,
        'activeIcon': Icons.calendar_today,
        'label': 'Bookings',
      },
      if (isManager)
        {
          'route': 'scan',
          'icon': Icons.qr_code_scanner_outlined,
          'activeIcon': Icons.qr_code_scanner,
          'label': 'Scan',
        },
      if (isManager)
        {
          'route': 'manage',
          'icon': Icons.dashboard_customize_outlined,
          'activeIcon': Icons.dashboard_customize,
          'label': 'Manage',
        },
      {
        'route': 'profile',
        'icon': Icons.person_outline,
        'activeIcon': Icons.person,
        'label': 'Profile',
      },
    ];

    final availableRoutes = tabs.map((t) => t['route'] as String).toList();

    // Determine the visual index based on the current shell index
    String currentRoute = 'home';
    final idx = widget.navigationShell.currentIndex;
    if (idx == 0)
      currentRoute = 'home';
    else if (idx == 1)
      currentRoute = 'events';
    else if (idx == 2)
      currentRoute = 'cart';
    else if (idx == 3)
      currentRoute = 'bookings';
    else if (idx == 4)
      currentRoute = 'manage';
    else if (idx == 5)
      currentRoute = 'profile';

    final currentIndex = availableRoutes.indexOf(currentRoute) != -1
        ? availableRoutes.indexOf(currentRoute)
        : 0;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        final currentIndex = widget.navigationShell.currentIndex;

        // If already on Home → allow exit
        if (currentIndex == 0) {
          final now = DateTime.now();
          if (_lastPressedAt == null ||
              now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
            _lastPressedAt = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          SystemNavigator.pop();
          return;
        }

        // Otherwise → go to Home tab
        widget.navigationShell.goBranch(0);
      },
      child: Scaffold(
        backgroundColor:
            Colors.transparent, // Color is managed by CyberGridBackground
        body: CyberGridBackground(
          child: Stack(
            children: [
              widget.navigationShell,

              // Floating Navbar
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: _buildFloatingNavbar(
                  tabs,
                  currentIndex,
                  availableRoutes,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavbar(
    List<Map<String, dynamic>> tabs,
    int currentIndex,
    List<String> availableRoutes,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF13131D).withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE81CFF).withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: -5,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _onTap(index, availableRoutes),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutQuart,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: isSelected ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            isSelected ? tab['activeIcon'] : tab['icon'],
                            color: isSelected
                                ? const Color(0xFF00E5FF)
                                : Colors.white24,
                            size: 24,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 16,
                            height: 3,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF00E5FF),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
