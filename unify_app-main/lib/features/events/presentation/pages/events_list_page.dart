import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../../events/domain/models/event_model.dart';
import '../../../../shared/widgets/r2_image_widget.dart';

class EventsListPage extends ConsumerWidget {
  final String type;

  const EventsListPage({super.key, required this.type});

  String get _title {
    if (type == 'phaseshift') return 'PhaseShift Events';
    if (type == 'utsav') return 'Utsav Events';
    return 'Regular Events';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredEventsAsync = ref.watch(filteredEventsProvider(type));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Color(0xFF7C3AED), blurRadius: 10)],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(filteredEventsProvider(type));
        },
        color: const Color(0xFF7C3AED),
        backgroundColor: const Color(0xFF1B1B26),
        child: filteredEventsAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.event_busy,
                          color: Colors.white24,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No events found for $_title',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ).copyWith(bottom: 120),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: events.length,
              itemBuilder: (context, index) {
                return _buildEventCard(context, events[index]);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
          ),
          error: (err, stack) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(filteredEventsProvider(type)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                        ),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/event-details/${event.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                R2ImageWidget(
                  imageKey: event.bannerImage,
                  height: 150,
                  borderRadius: 0,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.description.length > 80
                            ? '${event.description.substring(0, 80)}...'
                            : event.description,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
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

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFF13131D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2B2B36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFF0A0A0F),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: 200,
                  color: const Color(0xFF0A0A0F),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 14,
                  width: double.infinity,
                  color: const Color(0xFF0A0A0F),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 14,
                  width: 150,
                  color: const Color(0xFF0A0A0F),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
