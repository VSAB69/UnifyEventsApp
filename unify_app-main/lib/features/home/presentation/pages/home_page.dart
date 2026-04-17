import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../../events/domain/models/event_model.dart';
import '../../../../shared/widgets/r2_image_widget.dart';
import '../../../bookings/presentation/providers/bookings_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final eventsAsync = ref.watch(eventsProvider);
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Let the main_layout grid shine through
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(eventsProvider);
            ref.invalidate(myBookingsProvider);
          },
          color: const Color(0xFF00E5FF),
          backgroundColor: const Color(0xFF1B1B26),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── SYSTEM HEADER ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'USER_DASHBOARD',
                        style: GoogleFonts.spaceMono(
                          color: Colors.white54,
                          fontSize: 10,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Welcome text & Avatar row horizontally centered
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'WELCOME, ',
                                    style: GoogleFonts.bebasNeue(
                                      color: Colors.white,
                                      fontSize: 48,
                                      height: 1.0,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        user?.username.toUpperCase() ?? "GUEST",
                                    style: GoogleFonts.bebasNeue(
                                      color: const Color(0xFFFF1C7C),
                                      fontSize: 48,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Avatar
                          Transform.translate(
                            offset: const Offset(0, -7),
                            child: Hero(
                              tag: 'profile_avatar',
                              child: GestureDetector(
                                onTap: () => context.go('/profile'),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(
                                        0xFF7C3AED,
                                      ).withOpacity(0.5),
                                      width: 2,
                                    ),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF7C3AED),
                                        Color(0xFFE81CFF),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF7C3AED,
                                        ).withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      (user?.username != null &&
                                              user!.username.isNotEmpty)
                                          ? user.username[0].toUpperCase()
                                          : 'G',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── SELECT DOMAIN (QUICK ACTIONS) ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text(
                    'SELECT DOMAIN',
                    style: GoogleFonts.bebasNeue(
                      color: Colors.white,
                      fontSize: 28,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _animController,
                    curve: const Interval(0.0, 0.4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildDomainCard(
                          context,
                          'PHASE SHIFT',
                          'TECH SYMPOSIUM',
                          [const Color(0xFF00E5FF), const Color(0xFF0055FF)],
                          Icons.bolt,
                          '/events-list?type=phaseshift',
                        ),
                        _buildDomainCard(
                          context,
                          'UTSAV',
                          'CULTURAL FEST',
                          [const Color(0xFFFF1C7C), const Color(0xFFFF8A00)],
                          Icons.auto_awesome,
                          '/events-list?type=utsav',
                        ),
                        _buildDomainCard(
                          context,
                          'CLUB EVENTS',
                          'STUDENT GUILDS',
                          [const Color(0xFF39FF14), const Color(0xFF00AA00)],
                          Icons.group_work,
                          '/events-list?type=regular',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── RECENT LOGS (BOOKINGS) ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Text(
                    'RECENT LOGS',
                    style: GoogleFonts.spaceMono(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),

              bookingsAsync.when(
                data: (bookingsList) {
                  if (bookingsList.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "NO LOGS FOUND. INITIALIZE A TRANSFER.",
                          style: GoogleFonts.spaceMono(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }
                  final recent = bookingsList.take(2).toList();
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = recent[index];
                        return FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _animController,
                            curve: const Interval(0.4, 0.8),
                          ),
                          child: _buildLogCard(context, item),
                        );
                      }, childCount: recent.length),
                    ),
                  );
                },
                loading: () => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: const Color(0xFF7C3AED)),
                    ),
                  ),
                ),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
              ),

              // ── AVAILABLE NODES (EVENTS) ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Text(
                    'AVAILABLE NODES',
                    style: GoogleFonts.spaceMono(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _animController,
                    curve: const Interval(0.2, 0.6),
                  ),
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0.1, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _animController,
                            curve: Curves.easeOut,
                          ),
                        ),
                    child: SizedBox(
                      height: 180,
                      child: eventsAsync.when(
                        data: (events) {
                          if (events.isEmpty)
                            return Center(
                              child: Text(
                                "NO NODES OBTAINED.",
                                style: GoogleFonts.spaceMono(
                                  color: Colors.white38,
                                ),
                              ),
                            );
                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: events.length > 5 ? 5 : events.length,
                            itemBuilder: (context, index) {
                              return _buildNodeTicket(context, events[index]);
                            },
                          );
                        },
                        loading: () => Center(
                          child: CircularProgressIndicator(
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                        error: (err, stack) => Center(
                          child: Text(
                            'ERROR_CODE: $err',
                            style: GoogleFonts.spaceMono(
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Padding for bottom nav bar
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDomainCard(
    BuildContext context,
    String title,
    String subtitle,
    List<Color> gradientColors,
    IconData icon,
    String route,
  ) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF13131D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.08),
              blurRadius: 15,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Row(
          children: [
            // Glowing Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),

            const SizedBox(width: 16),

            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.bebasNeue(
                      color: Colors.white,
                      fontSize: 24,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceMono(
                      color: gradientColors.first,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Enter Arrow Button
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: gradientColors.first.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: gradientColors.first,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        if (item['id'] != null) context.push('/ticket/${item['id']}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF4A0024).withOpacity(0.8),
              const Color(0xFF1B0014).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFFF1C7C).withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID_${item['id'] ?? 'XXX'}',
                  style: GoogleFonts.spaceMono(
                    color: const Color(0xFFFF1C7C),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '4/14/2026', // Ideally format timestamp from item
                  style: GoogleFonts.spaceMono(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'TRANSFER CONFIRMED',
              style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${item['line_total']?.toStringAsFixed(2) ?? '0.00'}',
              style: GoogleFonts.spaceMono(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeTicket(BuildContext context, EventModel event) {
    return GestureDetector(
      onTap: () => context.push('/event-details/${event.id}'),
      child: Container(
        width: 320,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF13131D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            // Left Main Section
            Expanded(
              flex: 7,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Dimmed Background image
                  Opacity(
                    opacity: 0.3,
                    child: R2ImageWidget(
                      imageKey: event.bannerImage,
                      height: double.infinity,
                      borderRadius: 0,
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.confirmation_num_outlined,
                              size: 14,
                              color: Color(0xFFFF1C7C),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'EVENT ACCESS TOKEN',
                              style: GoogleFonts.spaceMono(
                                color: Colors.white,
                                fontSize: 10,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          event.title.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.bebasNeue(
                            color: Colors.white,
                            fontSize: 32,
                            height: 1.1,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'STATUS',
                                  style: GoogleFonts.spaceMono(
                                    color: Colors.white38,
                                    fontSize: 8,
                                  ),
                                ),
                                Text(
                                  'VERIFIED_ENTRY',
                                  style: GoogleFonts.spaceMono(
                                    color: const Color(0xFF39FF14),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NODE_REF',
                                  style: GoogleFonts.spaceMono(
                                    color: Colors.white38,
                                    fontSize: 8,
                                  ),
                                ),
                                Text(
                                  '0X-EVT-${event.id}',
                                  style: GoogleFonts.spaceMono(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Dashed Divider
            Container(
              width: 1,
              child: Flex(
                direction: Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  20,
                  (_) => Container(width: 1, height: 4, color: Colors.white12),
                ),
              ),
            ),

            // Right Stub Section
            Expanded(
              flex: 3,
              child: Container(
                color: const Color(0xFF1E1E2C).withOpacity(0.5),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'VALUE',
                      style: GoogleFonts.spaceMono(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.price != null && event.price! > 0
                          ? '₹${event.price}'
                          : 'FREE',
                      style: GoogleFonts.bebasNeue(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'CLAIM SEAT',
                        style: GoogleFonts.spaceMono(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                      ),
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
}
