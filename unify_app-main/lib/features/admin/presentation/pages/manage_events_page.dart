import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/events/presentation/widgets/manage_event_card.dart';
import '../../../../features/events/presentation/providers/manage_events_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/events/presentation/widgets/manage_event_modals.dart';

class ManageEventsPage extends ConsumerWidget {
  const ManageEventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user != null && user.role == 'admin';
    final eventsAsync = ref.watch(manageEventsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(manageEventsProvider),
        color: const Color(0xFF7C3AED),
        backgroundColor: const Color(0xFF1B1B26),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              expandedHeight: 120,
              flexibleSpace: const FlexibleSpaceBar(
                titlePadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                title: Text(
                  'Manage Events',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
              actions: [
                if (isAdmin)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: () => ManageEventModals.showEventModal(context, ref),
                        icon: const Icon(Icons.add, size: 18, color: Colors.white),
                        label: const Text('Add Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )
              ],
            ),
            
            // Subtitle exactly mapping web requirement
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  'Here you can manage the structural architecture mapping directly to the endpoints.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ),
            
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),

            eventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text("No events assigned to you.", style: TextStyle(color: Colors.white54))),
                    ),
                  );
                }
                
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final event = events[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: ManageEventCard(event: event, isAdmin: isAdmin),
                        );
                      },
                      childCount: events.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))))),
              error: (err, _) => SliverToBoxAdapter(child: Center(child: Text("Failed to load: $err", style: TextStyle(color: Colors.redAccent)))),
            ),
          ],
        ),
      ),
    );
  }
}
