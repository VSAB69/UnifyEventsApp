import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class MainLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> with TickerProviderStateMixin {
  
  void _onTap(int index, List<String> availableRoutes) {
    // Map visual index to route
    final route = availableRoutes[index];
    int shellIndex = 0;
    
    // Find the corresponding shell index for the route
    if (route == 'home') shellIndex = 0;
    else if (route == 'events') shellIndex = 1;
    else if (route == 'cart') shellIndex = 2;
    else if (route == 'bookings') shellIndex = 3;
    else if (route == 'manage') shellIndex = 4;
    else if (route == 'profile') shellIndex = 5;

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
      {'route': 'home', 'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Home'},
      {'route': 'events', 'icon': Icons.explore_outlined, 'activeIcon': Icons.explore, 'label': 'Events'},
      {'route': 'cart', 'icon': Icons.shopping_cart_outlined, 'activeIcon': Icons.shopping_cart, 'label': 'Cart'},
      {'route': 'bookings', 'icon': Icons.calendar_today_outlined, 'activeIcon': Icons.calendar_today, 'label': 'Bookings'},
      if (isManager)
        {'route': 'manage', 'icon': Icons.dashboard_customize_outlined, 'activeIcon': Icons.dashboard_customize, 'label': 'Manage'},
      {'route': 'profile', 'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': 'Profile'},
    ];

    final availableRoutes = tabs.map((t) => t['route'] as String).toList();
    
    // Determine the visual index based on the current shell index
    String currentRoute = 'home';
    final idx = widget.navigationShell.currentIndex;
    if (idx == 0) currentRoute = 'home';
    else if (idx == 1) currentRoute = 'events';
    else if (idx == 2) currentRoute = 'cart';
    else if (idx == 3) currentRoute = 'bookings';
    else if (idx == 4) currentRoute = 'manage';
    else if (idx == 5) currentRoute = 'profile';

    final currentIndex = availableRoutes.indexOf(currentRoute) != -1 ? availableRoutes.indexOf(currentRoute) : 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          widget.navigationShell,
          
          // Floating Navbar
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _buildFloatingNavbar(tabs, currentIndex, availableRoutes),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavbar(List<Map<String, dynamic>> tabs, int currentIndex, List<String> availableRoutes) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B26).withOpacity(0.6),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: const Color(0xFF7C3AED).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              )
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
                            color: isSelected ? const Color(0xFF7C3AED) : Colors.white54,
                            size: 24,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF7C3AED),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF7C3AED),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            ),
                          )
                        ]
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
