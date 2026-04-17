import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import '../../../events/presentation/providers/event_details_provider.dart';
import '../../../events/domain/models/booking_models.dart';

class CartItemEditModal extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;

  const CartItemEditModal({super.key, required this.item});

  @override
  ConsumerState<CartItemEditModal> createState() => _CartItemEditModalState();
}

class _CartItemEditModalState extends ConsumerState<CartItemEditModal> {
  int _count = 1;
  late List<Map<String, dynamic>> _participants;
  late List<Map<String, dynamic>> _deletedParticipants;
  int? _selectedSlotId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _count = widget.item['participants_count'] ?? 1;
    _participants = [];
    _deletedParticipants = [];

    // Initialize with current slot if any
    if (widget.item['temp_timeslots'] != null &&
        (widget.item['temp_timeslots'] as List).isNotEmpty) {
      _selectedSlotId = (widget.item['temp_timeslots'] as List).first['slot'];
    }

    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    setState(() => _isLoading = true);
    try {
      final temp = await ref.read(
        tempBookingsProvider(widget.item['id']).future,
      );
      if (mounted) {
        setState(() {
          _participants = temp
              .map(
                (t) => {
                  'id': t['id'],
                  'name': TextEditingController(text: t['name'] ?? ''),
                  'email': TextEditingController(text: t['email'] ?? ''),
                  'phone': TextEditingController(text: t['phone'] ?? ''),
                },
              )
              .toList();
          _adjustParticipantsSize();
        });
      }
    } catch (_) {
      // Ignore if it fails, _adjustParticipantsSize will populate empty entries.
      if (mounted) {
        setState(() {
          _adjustParticipantsSize();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    for (var p in _participants) {
      (p['name'] as TextEditingController).dispose();
      (p['email'] as TextEditingController).dispose();
      (p['phone'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _adjustParticipantsSize() {
    if (_participants.length < _count) {
      int needed = _count - _participants.length;
      for (int i = 0; i < needed; i++) {
        _participants.add({
          'id': null,
          'name': TextEditingController(),
          'email': TextEditingController(),
          'phone': TextEditingController(),
        });
      }
    } else if (_participants.length > _count) {
      int excess = _participants.length - _count;
      for (int i = 0; i < excess; i++) {
        var removed = _participants.removeLast();
        if (removed['id'] != null) {
          _deletedParticipants.add(removed);
        }
      }
    }
  }

  Future<void> _saveChanges(int cartItemId) async {
    // Validation
    for (var p in _participants) {
      final nameCtrl = p['name'] as TextEditingController;
      if (nameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All participant names are required.')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    final actionService = ref.read(cartActionProvider);

    try {
      // 1. Update Team Size
      await actionService.updateCartItem(cartItemId, {
        'participants_count': _count,
      });

      // 2. Sync Participants
      for (var p in _participants) {
        final data = {
          'cart_item': cartItemId,
          'name': (p['name'] as TextEditingController).text.trim(),
          'email': (p['email'] as TextEditingController).text.trim(),
          'phone': (p['phone'] as TextEditingController).text.trim(),
        };

        if (p['id'] != null) {
          await actionService.updateParticipant(p['id'], data);
        } else {
          await actionService.addParticipant(data);
        }
      }

      for (var dp in _deletedParticipants) {
        await actionService.removeParticipant(dp['id']);
      }

      // 3. Update Slot
      if (_selectedSlotId != null) {
        await actionService.updateTimeSlot({
          'cart_item': cartItemId,
          'slot': _selectedSlotId,
        });
      }

      ref.invalidate(cartDataProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cart item updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String eventId = '';
    if (widget.item['event_id'] != null) {
      eventId = widget.item['event_id'].toString();
    } else if (widget.item['event'] is int) {
      eventId = widget.item['event'].toString();
    } else if (widget.item['event'] is Map) {
      eventId = widget.item['event']['id'].toString();
    }

    final constraintAsync = ref.watch(constraintProvider(eventId));
    final slotsAsync = ref.watch(slotsProvider(eventId));
    final cartItemId = widget.item['id'];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1B1B26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Cart Item',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white10),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Team Size Section
                      constraintAsync.when(
                        data: (constraint) {
                          if (constraint == null) return const SizedBox();

                          bool isFixed = constraint.fixed;
                          bool isSingle = constraint.bookingType == 'single';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Team Size',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (isSingle)
                                const Text(
                                  'This is a single participant event.',
                                  style: TextStyle(color: Colors.white54),
                                )
                              else if (isFixed)
                                Text(
                                  'Fixed team size of ${constraint.upperLimit} required.',
                                  style: const TextStyle(color: Colors.white54),
                                )
                              else
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: _count > constraint.lowerLimit
                                          ? () {
                                              setState(() {
                                                _count--;
                                                _adjustParticipantsSize();
                                              });
                                            }
                                          : null,
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '$_count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _count < constraint.upperLimit
                                          ? () {
                                              setState(() {
                                                _count++;
                                                _adjustParticipantsSize();
                                              });
                                            }
                                          : null,
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 24),
                            ],
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                        error: (_, __) => const Text(
                          'Failed to load constraints',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),

                      // Participants List
                      const Text(
                        'Participants',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _participants.length,
                        itemBuilder: (ctx, i) {
                          final p = _participants[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2B2B36),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Participant ${i + 1}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                TextField(
                                  controller:
                                      p['name'] as TextEditingController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Full Name *',
                                    labelStyle: TextStyle(
                                      color: Colors.white38,
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white24,
                                      ),
                                    ),
                                  ),
                                ),
                                TextField(
                                  controller:
                                      p['email'] as TextEditingController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Email (Optional)',
                                    labelStyle: TextStyle(
                                      color: Colors.white38,
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white24,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // Slot Picker
                      const Text(
                        'Select Time Slot',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      slotsAsync.when(
                        data: (slots) {
                          if (slots.isEmpty)
                            return const Text(
                              'No slots available.',
                              style: TextStyle(color: Colors.white54),
                            );

                          return Column(
                            children: slots.map((slot) {
                              bool hasCapacity =
                                  slot.unlimitedParticipants ||
                                  (slot.availableParticipants != null &&
                                      slot.availableParticipants! >= _count);
                              // Allow selection if has capacity, OR if it's the already selected slot.
                              bool canSelect =
                                  hasCapacity || _selectedSlotId == slot.id;

                              return GestureDetector(
                                onTap: canSelect
                                    ? () => setState(
                                        () => _selectedSlotId = slot.id,
                                      )
                                    : null,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _selectedSlotId == slot.id
                                        ? const Color(
                                            0xFF7C3AED,
                                          ).withOpacity(0.3)
                                        : const Color(0xFF2B2B36),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedSlotId == slot.id
                                          ? const Color(0xFF7C3AED)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${slot.startTime} - ${slot.endTime}',
                                        style: TextStyle(
                                          color: canSelect
                                              ? Colors.white
                                              : Colors.white38,
                                        ),
                                      ),
                                      if (_selectedSlotId == slot.id)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF7C3AED),
                                          size: 20,
                                        )
                                      else if (!canSelect)
                                        const Text(
                                          'Full',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                        error: (_, __) => const Text(
                          'Error loading slots',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : () => _saveChanges(cartItemId),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
