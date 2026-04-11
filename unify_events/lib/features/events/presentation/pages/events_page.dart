import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            expandedHeight: 120,
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 20, bottom: 20),
              title: Text(
                'Explore Events',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Color(0xFF7C3AED), blurRadius: 10)],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10).copyWith(bottom: 120),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Choose your experience',
                      style: TextStyle(color: Colors.white60, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildCategoryCard(
                    context,
                    title: 'PhaseShift',
                    subtitle: 'Tech • Innovation • Code',
                    gradientColors: [const Color(0xFF1E3A8A), const Color(0xFF7C3AED)],
                    icon: Icons.memory,
                    type: 'phaseshift',
                  ),
                  _buildCategoryCard(
                    context,
                    title: 'Utsav',
                    subtitle: 'Culture • Art • Expression',
                    gradientColors: [const Color(0xFFEA580C), const Color(0xFFE11D48)],
                    icon: Icons.color_lens,
                    type: 'utsav',
                  ),
                  _buildCategoryCard(
                    context,
                    title: 'Regular Events',
                    subtitle: 'Explore everything else',
                    gradientColors: [const Color(0xFF374151), const Color(0xFF4B5563)],
                    icon: Icons.event,
                    type: 'regular',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required IconData icon,
    required String type,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradientColors.map((c) => c.withOpacity(0.8)).toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/events-list?type=$type'),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  icon,
                  size: 120,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
