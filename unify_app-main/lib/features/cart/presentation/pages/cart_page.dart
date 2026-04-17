import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/cart_provider.dart';
import '../../../../shared/widgets/r2_image_widget.dart';
import '../widgets/cart_item_edit_modal.dart';
import '../../../events/presentation/providers/event_details_provider.dart';
import '../../../events/presentation/providers/events_provider.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartDataProvider);

    return cartAsync.when(
      data: (cartData) {
        num grandTotal = 0;
        final eventsAsync = ref.watch(eventsProvider);
        final items = cartData['items'] as List<dynamic>? ?? [];

        for (var item in items) {
          final itemId = item['id'];
          final tempBookingsAsync = ref.watch(tempBookingsProvider(itemId));
          final bookingsCount =
              tempBookingsAsync.valueOrNull?.length ??
              item['participants_count'] ??
              1;

          String eventId = '';
          if (item['event_id'] != null)
            eventId = item['event_id'].toString();
          else if (item['event'] is int)
            eventId = item['event'].toString();
          else if (item['event'] is Map)
            eventId = item['event']['id'].toString();

          num basePrice = 0;
          if (item['price'] != null) {
            basePrice = num.tryParse(item['price'].toString()) ?? 0;
          } else if (item['event'] is Map) {
            basePrice =
                num.tryParse(
                  item['event']['price']?.toString() ??
                      item['event']['fee']?.toString() ??
                      '0',
                ) ??
                0;
          } else if (eventsAsync.valueOrNull != null) {
            final eventMatch = eventsAsync.value!
                .where((e) => e.id.toString() == eventId)
                .firstOrNull;
            if (eventMatch != null) basePrice = eventMatch.price ?? 0;
          }

          grandTotal += basePrice * bookingsCount;
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              'Your Cart',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              if (items.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Text(
                      'CART VALUE: ₹$grandTotal',
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                RefreshIndicator(
                  color: const Color(0xFF7C3AED),
                  backgroundColor: const Color(0xFF1B1B26),
                  onRefresh: () async => ref.invalidate(cartDataProvider),
                  child: items.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.3,
                            ),
                            const Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.shopping_cart_outlined,
                                    color: Colors.white24,
                                    size: 80,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Your cart is empty',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : CustomScrollView(
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.all(20),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  return CartItemCard(item: items[index]);
                                }, childCount: items.length),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Container(
                                margin: const EdgeInsets.all(20).copyWith(
                                  bottom: 220,
                                ), // Padding to account for both floating checkout AND floating navbar
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF13131D),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'SUBTOTAL(${items.length} items)',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '₹$grandTotal',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                if (items.isNotEmpty)
                  Positioned(
                    bottom: 100, // Stay above the MainLayout floating navbar
                    left: 20,
                    right: 20,
                    child: SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          context.push('/checkout');
                        },
                        child: const Text(
                          'Proceed to Checkout',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error loading cart',
                style: TextStyle(color: Colors.white),
              ),
              TextButton(
                onPressed: () => ref.invalidate(cartDataProvider),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CartItemCard extends ConsumerWidget {
  final Map<String, dynamic> item;

  const CartItemCard({super.key, required this.item});

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

    final itemId = item['id'];

    // Real-Time Providers
    final tempBookingsAsync = ref.watch(tempBookingsProvider(itemId));
    final slotsAsync = ref.watch(slotsProvider(eventId));
    final eventsAsync = ref.watch(eventsProvider);

    num basePrice = 0;
    if (item['price'] != null) {
      basePrice = num.tryParse(item['price'].toString()) ?? 0;
    } else if (item['event'] is Map) {
      basePrice =
          num.tryParse(
            item['event']['price']?.toString() ??
                item['event']['fee']?.toString() ??
                '0',
          ) ??
          0;
    } else if (eventsAsync.valueOrNull != null) {
      final eventMatch = eventsAsync.value!
          .where((e) => e.id.toString() == eventId)
          .firstOrNull;
      if (eventMatch != null) {
        basePrice = eventMatch.price ?? 0;
      }
    }

    final bookingsCount =
        tempBookingsAsync.valueOrNull?.length ??
        item['participants_count'] ??
        1;
    final itemTotal = basePrice * bookingsCount;

    // Slot details logic
    int? selectedSlotId;
    if (item['temp_timeslots'] != null &&
        (item['temp_timeslots'] as List).isNotEmpty) {
      selectedSlotId = (item['temp_timeslots'] as List).first['slot'];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Item Total: ₹$itemTotal',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () async {
                  await ref.read(cartActionProvider).removeCartItem(itemId);
                  ref.invalidate(cartDataProvider);
                },
              ),
            ],
          ),

          if (selectedSlotId != null) ...[
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: slotsAsync.when(
                data: (slots) {
                  try {
                    final matchingSlot = slots.firstWhere(
                      (s) => s.id == selectedSlotId,
                    );
                    return Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.white54,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Slot:',
                          style: TextStyle(color: Colors.white54),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${matchingSlot.startTime} - ${matchingSlot.endTime}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  } catch (_) {
                    return const Text(
                      'Slot selected but unavailable',
                      style: TextStyle(color: Colors.white54),
                    );
                  }
                },
                loading: () => const Text(
                  'Loading slot details...',
                  style: TextStyle(color: Colors.white54),
                ),
                error: (_, __) => const Text(
                  'Error loading slot',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ),
          ],

          const Divider(color: Colors.white10, height: 1),

          // Participants List from Provider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              'Participants',
              style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          tempBookingsAsync.when(
            data: (bookings) {
              if (bookings.isEmpty)
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No participants added yet.',
                    style: TextStyle(color: Colors.white38),
                  ),
                );

              return Column(
                children: bookings
                    .map(
                      (booking) => ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.person,
                          color: Colors.white54,
                        ),
                        title: Text(
                          booking['name'] ?? 'Participant',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          booking['email'] != null &&
                                  booking['email'].toString().isNotEmpty
                              ? booking['email']
                              : 'No Email Provided',
                          style: const TextStyle(color: Colors.white38),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
              ),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Failed to load participants',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ),

          const SizedBox(height: 8),
          // Edit Button
          TextButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                useRootNavigator: true,
                builder: (_) => CartItemEditModal(item: item),
              );
            },
            icon: const Icon(Icons.edit, color: Color(0xFF7C3AED)),
            label: const Text(
              'Edit Cart Item',
              style: TextStyle(
                color: Color(0xFF7C3AED),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
