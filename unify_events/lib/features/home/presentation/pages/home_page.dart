import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..forward();
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
      backgroundColor: const Color(0xFF06060A),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(eventsProvider);
          ref.invalidate(myBookingsProvider);
        },
        color: const Color(0xFF7C3AED),
        backgroundColor: const Color(0xFF1B1B26),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              expandedHeight: 100,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
                title: Text(
                  'Hello, ${user?.username ?? "Guest"} 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              actions: [
                Hero(
                  tag: 'profile_avatar',
                  child: GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: Container(
                      margin: const EdgeInsets.only(right: 20),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.5), width: 2),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFFE81CFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(user?.username.isNotEmpty == true ? user!.username[0].toUpperCase() : 'U', 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // QUICK ACTIONS
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.4)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _buildQuickAction(Icons.search, 'Browse\nEvents', () => context.go('/events'), const Color(0xFF7C3AED))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildQuickAction(Icons.shopping_cart, 'View\nCart', () => context.go('/cart'), const Color(0xFF38BDF8))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildQuickAction(Icons.history, 'My\nBookings', () => context.go('/bookings'), const Color(0xFFE81CFF))),
                    ],
                  ),
                ),
              ),
            ),

            // FEATURED EVENTS CAROUSEL
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: Text('Featured Events', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _animController, curve: const Interval(0.2, 0.6)),
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut)),
                  child: SizedBox(
                    height: 280,
                    child: eventsAsync.when(
                      data: (events) {
                        if (events.isEmpty) return const Center(child: Text("No events available.", style: TextStyle(color: Colors.white54)));
                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: events.length > 5 ? 5 : events.length,
                          itemBuilder: (context, index) {
                            return _buildFeaturedCard(context, events[index]);
                          },
                        );
                      },
                      loading: () => ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: 3,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (_, __) => Container(
                          width: 250,
                          decoration: BoxDecoration(color: const Color(0xFF1B1B26), borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                      error: (err, stack) => Center(child: Text('Failed: $err', style: const TextStyle(color: Colors.redAccent))),
                    ),
                  ),
                ),
              ),
            ),

            // RECENT BOOKINGS
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: Text('Recent Bookings', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),

            bookingsAsync.when(
              data: (bookingsList) {
                if (bookingsList.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text("No bookings yet. Start exploring!", style: TextStyle(color: Colors.white54)),
                    ),
                  );
                }
                final recent = bookingsList.take(2).toList();
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = recent[index];
                        return FadeTransition(
                          opacity: CurvedAnimation(parent: _animController, curve: const Interval(0.4, 0.8)),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF13131D),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.confirmation_num, color: Color(0xFF7C3AED)),
                              ),
                              title: Text(item['event_name'] ?? 'Event', maxLines: 1, overflow: TextOverflow.ellipsis, 
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Tickets: ${item['participants_count'] ?? 1}  |  ₹${item['line_total'] ?? 0}', 
                                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
                                onPressed: () {
                                  if (item['id'] != null) context.push('/ticket/${item['id']}');
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: recent.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap, Color accent) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF13131D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: accent.withOpacity(0.1), blurRadius: 15, spreadRadius: -5)],
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 28),
            const SizedBox(height: 10),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, EventModel event) {
    return Container(
      width: 260,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B26),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.15), blurRadius: 20, spreadRadius: -5)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/event-details/${event.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      R2ImageWidget(imageKey: event.bannerImage, height: double.infinity, borderRadius: 0),
                      Positioned(
                        top: 12, right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
                          child: Text(event.price != null && event.price! > 0 ? '₹${event.price}' : 'FREE', 
                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis, 
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 12, color: Color(0xFF7C3AED)),
                          const SizedBox(width: 4),
                          Text(event.date ?? 'Upcoming', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
