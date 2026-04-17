import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../events/domain/models/event_model.dart';
import '../../../events/domain/models/booking_models.dart';
import '../providers/event_details_provider.dart';
import '../providers/events_provider.dart';
import '../../../../shared/widgets/r2_image_widget.dart';
import '../widgets/add_to_cart_flow.dart';

class EventDetailPage extends ConsumerWidget {
  final String eventId;

  const EventDetailPage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventList = ref.watch(eventsProvider).valueOrNull ?? [];
    // Fallback if accessed directly
    final baseEvent = eventList.firstWhere(
      (e) => e.id.toString() == eventId,
      orElse: () => EventModel(
        id: int.tryParse(eventId) ?? 0,
        title: 'Loading...',
        description: '',
      ),
    );

    final detailsAsync = ref.watch(eventDetailsDataProvider(eventId));
    final constraintAsync = ref.watch(constraintProvider(eventId));
    final slotsAsync = ref.watch(slotsProvider(eventId));

    final isOrganiser = false; // We can check role via AuthState if needed.

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            expandedHeight: 300,
            pinned: true,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black, blurRadius: 10)],
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  R2ImageWidget(
                    imageKey: baseEvent.bannerImage,
                    height: 300,
                    borderRadius: 0,
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black87,
                          Colors.transparent,
                          Color(0xFF0A0A0F),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    baseEvent.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF7C3AED)),
                        ),
                        child: Text(
                          baseEvent.price != null && baseEvent.price! > 0
                              ? '\$${baseEvent.price}'
                              : 'Free',
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      constraintAsync.when(
                        data: (c) {
                          String text = "No rules";
                          if (c != null) {
                            if (c.bookingType == "single") {
                              text = "Single (1 participant)";
                            } else if (c.fixed) {
                              text = "Team size: ${c.upperLimit}";
                            } else {
                              text =
                                  "Team size: ${c.lowerLimit}-${c.upperLimit}";
                            }
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.pinkAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.pinkAccent),
                            ),
                            child: Text(
                              text,
                              style: const TextStyle(
                                color: Colors.pinkAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Details Section
                  detailsAsync.when(
                    data: (details) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (details['venue'] != null) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white54,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                details['venue'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (details['date'] != null) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.white54,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                details['date'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                        const Text(
                          'About',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          details['description'] ?? baseEvent.description,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                    error: (_, __) => const Text(
                      'Error loading details',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),

                  // Slots Warning Section
                  slotsAsync.when(
                    data: (slots) {
                      bool hasLowSlots = slots.any(
                        (s) =>
                            s.availableParticipants != null &&
                            s.availableParticipants! <= 5 &&
                            s.availableParticipants! > 0,
                      );
                      if (hasLowSlots) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Few slots left — book soon!',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),

                  const SizedBox(height: 100), // padding for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        color: const Color(0xFF1B1B26),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: isOrganiser
                ? null
                : () {
                    final constraint = constraintAsync.valueOrNull;
                    final slots = slotsAsync.valueOrNull ?? [];
                    if (constraint == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Constraints not loaded yet'),
                        ),
                      );
                      return;
                    }
                    AddToCartFlow.start(
                      context,
                      ref,
                      baseEvent,
                      constraint,
                      slots,
                    );
                  },
            child: const Text(
              'Book Now',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
