import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/cart_provider.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../../events/presentation/providers/event_details_provider.dart';

class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartDataProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Checkout Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: cartAsync.when(
          data: (cartData) {
            num grandTotal = 0;
            final eventsAsync = ref.watch(eventsProvider);
            final items = cartData['items'] as List<dynamic>? ?? [];

            for (var item in items) {
              final itemId = item['id'];
              final tempBookingsAsync = ref.watch(tempBookingsProvider(itemId));
              final bookingsCount = tempBookingsAsync.valueOrNull?.length ?? item['participants_count'] ?? 1;

              String eventId = '';
              if (item['event_id'] != null) eventId = item['event_id'].toString();
              else if (item['event'] is int) eventId = item['event'].toString();
              else if (item['event'] is Map) eventId = item['event']['id'].toString();

              num basePrice = 0;
              if (item['event_price'] != null) {
                basePrice = num.tryParse(item['event_price'].toString()) ?? 0;
              } else if (item['price'] != null) {
                basePrice = num.tryParse(item['price'].toString()) ?? 0;
              } else if (item['event'] is Map) {
                basePrice = num.tryParse(item['event']['price']?.toString() ?? item['event']['fee']?.toString() ?? '0') ?? 0;
              } else if (eventsAsync.valueOrNull != null) {
                final eventMatch = eventsAsync.value!.where((e) => e.id.toString() == eventId).firstOrNull;
                if (eventMatch != null) basePrice = eventMatch.price ?? 0;
              }

              grandTotal += basePrice * bookingsCount;
            }

            if (items.isEmpty) {
              return const Center(child: Text("Your cart is empty", style: TextStyle(color: Colors.white54, fontSize: 18)));
            }

            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return CheckoutItemCard(item: items[index]);
                          },
                          childCount: items.length,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(20).copyWith(bottom: 150),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B1B26),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Grand Total:', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('₹$grandTotal', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        context.push('/payment', extra: grandTotal);
                      },
                      child: const Text('Proceed to Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))),
          error: (err, _) => const Center(child: Text('Error loading checkout', style: TextStyle(color: Colors.redAccent))),
        ),
      ),
    );
  }
}

class CheckoutItemCard extends ConsumerWidget {
  final Map<String, dynamic> item;

  const CheckoutItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String eventName = 'Unknown Event';
    if (item['event_name'] != null) {
      eventName = item['event_name'];
    } else if (item['event'] is Map) {
      eventName = item['event']['name'] ?? 'Unknown Event';
    }

    String eventId = '';
    if (item['event_id'] != null) {
      eventId = item['event_id'].toString();
    } else if (item['event'] is int) {
      eventId = item['event'].toString();
    } else if (item['event'] is Map) {
      eventId = item['event']['id'].toString();
    }

    num basePrice = 0;
    if (item['event_price'] != null) {
      basePrice = num.tryParse(item['event_price'].toString()) ?? 0;
    } else if (item['price'] != null) {
      basePrice = num.tryParse(item['price'].toString()) ?? 0;
    } else if (item['event'] is Map) {
      basePrice = num.tryParse(item['event']['price']?.toString() ?? item['event']['fee']?.toString() ?? '0') ?? 0;
    }
    
    final itemId = item['id'];

    final tempBookingsAsync = ref.watch(tempBookingsProvider(itemId));
    final tempTimeslotsAsync = ref.watch(tempTimeslotsProvider(itemId));
    final slotsAsync = ref.watch(slotsProvider(eventId));
    
    final bookingsCount = tempBookingsAsync.valueOrNull?.length ?? item['participants_count'] ?? 1;
    final itemTotal = basePrice * bookingsCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(eventName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                Text('₹$itemTotal (${bookingsCount} × ₹$basePrice)', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          // Slot Details
          tempTimeslotsAsync.when(
            data: (tempSlots) {
              if (tempSlots.isEmpty) return const SizedBox();
              final selectedSlotId = tempSlots.first['slot'];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: slotsAsync.when(
                  data: (slots) {
                    try {
                      final matchingSlot = slots.firstWhere((s) => s.id == selectedSlotId);
                      return Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.white54, size: 16),
                          const SizedBox(width: 8),
                          Text('${matchingSlot.startTime} - ${matchingSlot.endTime}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      );
                    } catch (_) {
                       return const Text('Slot selected but unavailable', style: TextStyle(color: Colors.white54, fontSize: 14));
                    }
                  },
                  loading: () => const Text('Loading slot details...', style: TextStyle(color: Colors.white54, fontSize: 14)),
                  error: (_, __) => const Text('Error loading slot', style: TextStyle(color: Colors.white54, fontSize: 14)),
                ),
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          tempBookingsAsync.when(
            data: (bookings) {
              if (bookings.isEmpty) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: bookings.map((booking) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.white54, size: 16),
                        const SizedBox(width: 8),
                        Text(booking['name'] ?? 'Participant', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  )).toList(),
                ),
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}
