import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/bookings_provider.dart';
import '../../domain/models/slot_info.dart';

class BookingsPage extends ConsumerWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Bookings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Usually embedded in MainLayout stack
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF7C3AED),
          backgroundColor: const Color(0xFF1B1B26),
          onRefresh: () async => ref.invalidate(myBookingsProvider),
          child: bookingsAsync.when(
            data: (bookings) {
              if (bookings.isEmpty) {
                return ListView(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.confirmation_number_outlined, color: Colors.white24, size: 80),
                          SizedBox(height: 16),
                          Text('No bookings yet', style: TextStyle(color: Colors.white54, fontSize: 18)),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20).copyWith(bottom: 120),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  // Animated staggered fade
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 400 + (index * 100).clamp(0, 800)),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, child) {
                      return Opacity(
                        opacity: val,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - val)),
                          child: BookingOrderCard(booking: booking),
                        ),
                      );
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))),
            error: (err, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  const Text('Error loading bookings', style: TextStyle(color: Colors.white)),
                  TextButton(onPressed: () => ref.invalidate(myBookingsProvider), child: const Text('RETRY'))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BookingOrderCard extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingOrderCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final bookedEvents = booking['booked_events'] as List<dynamic>? ?? [];
    final id = booking['id'] ?? 'Unknown';
    final totalAmount = booking['total_amount'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B26).withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.12),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF7C3AED).withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle, color: Color(0xFF7C3AED), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Booking Confirmed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Order #$id', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                Text('₹$totalAmount', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
          ),
          
          // Events List inside the Order
          ...bookedEvents.map((eventItem) => BookedEventSegment(eventItem: eventItem)),
        ],
      ),
    );
  }
}

class BookedEventSegment extends StatefulWidget {
  final Map<String, dynamic> eventItem;

  const BookedEventSegment({super.key, required this.eventItem});

  @override
  State<BookedEventSegment> createState() => _BookedEventSegmentState();
}

class _BookedEventSegmentState extends State<BookedEventSegment> {

  @override
  Widget build(BuildContext context) {
    final eventName = widget.eventItem['event_name'] ?? 'Unknown Event';
    final lineTotal = widget.eventItem['line_total'] ?? 0;
    final pCount = widget.eventItem['participants_count'] ?? 1;
    final slotInfo = widget.eventItem['slot_info'] ?? 'General Slot'; // Fallback mapping depending on backend
    final participants = widget.eventItem['participants'] as List<dynamic>? ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EVENT NAME
          Text(eventName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          // DATE + TIME (FULL WIDTH)
          _buildSlotInfoUI(widget.eventItem['slot_info']),

          const SizedBox(height: 10),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),

          // BOTTOM ROW (PRICE + BUTTON)
          Row(
            children: [
              // LEFT: TICKETS + PRICE
              Expanded(
                child: Text('Tickets: $pCount | ₹$lineTotal', style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              // RIGHT: BUTTON
              ElevatedButton(
                onPressed: () {
                  final id = widget.eventItem['id'];
                  if (id != null) context.push('/ticket/$id');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED).withOpacity(0.15),
                  elevation: 0,
                  side: BorderSide(color: const Color(0xFF7C3AED).withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.confirmation_number, size: 16, color: Color(0xFF38BDF8)),
                    SizedBox(width: 6),
                    Text('View Ticket', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
        ],
      ),
    );
  }

  Widget _buildSlotInfoUI(dynamic rawSlotInfo) {
    final slotInfo = SlotInfo.tryParse(rawSlotInfo);
    if (slotInfo == null) {
      return Row(
        children: [
          const Icon(Icons.access_time, color: Colors.white54, size: 14),
          const SizedBox(width: 6),
          Expanded(child: Text(rawSlotInfo?.toString() ?? 'General Slot', style: const TextStyle(color: Colors.white54, fontSize: 13))),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (slotInfo.date != null) ...[
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Date: ${slotInfo.date}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        if (slotInfo.startTime != null && slotInfo.endTime != null) ...[
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Time: ${formatTimeHHMM(slotInfo.startTime)} - ${formatTimeHHMM(slotInfo.endTime)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}
