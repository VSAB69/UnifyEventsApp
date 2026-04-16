import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
             SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DIRECTORY',
                      style: GoogleFonts.spaceMono(
                        color: Colors.white54,
                        fontSize: 10,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'EXPLORE NODES',
                      style: GoogleFonts.bebasNeue(
                        color: Colors.white,
                        fontSize: 48,
                        height: 1.0,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 120),
                child: Column(
                  children: [
                    _buildNeonDomainCard(
                      context, 
                      'PHASE SHIFT', 'TECH SYMPOSIUM', 
                      [const Color(0xFF00E5FF), const Color(0xFF0055FF)], 
                      Icons.bolt, '/events-list?type=phaseshift'
                    ),
                    _buildNeonDomainCard(
                      context, 
                      'UTSAV', 'CULTURAL FEST', 
                      [const Color(0xFFFF1C7C), const Color(0xFFFF8A00)], 
                      Icons.auto_awesome, '/events-list?type=utsav'
                    ),
                    _buildNeonDomainCard(
                      context, 
                      'CLUB EVENTS', 'STUDENT GUILDS', 
                      [const Color(0xFF39FF14), const Color(0xFF00AA00)], 
                      Icons.group_work, '/events-list?type=regular'
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeonDomainCard(
    BuildContext context, 
    String title, 
    String subtitle, 
    List<Color> gradientColors, 
    IconData icon, 
    String route
  ) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        width: double.infinity,
        height: 160,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF13131D),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.08),
              blurRadius: 30,
              spreadRadius: -5,
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Glowing Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 40),
            ),
            
            const SizedBox(width: 24),
            
            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceMono(
                      color: gradientColors.first,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: GoogleFonts.bebasNeue(
                      color: Colors.white,
                      fontSize: 36,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'ENTER NODE',
                        style: GoogleFonts.spaceMono(
                          color: Colors.white54,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 16, color: gradientColors.first),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
