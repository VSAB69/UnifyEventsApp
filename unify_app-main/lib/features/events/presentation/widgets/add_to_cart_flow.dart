import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/booking_models.dart';
import '../../domain/models/event_model.dart';
import '../providers/event_details_provider.dart';

class AddToCartFlow {
  static void start(
    BuildContext context,
    WidgetRef ref,
    EventModel event,
    ConstraintModel constraint,
    List<SlotModel> slots,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B1B26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ParticipantCountModal(
        event: event,
        constraint: constraint,
        slots: slots,
      ),
    );
  }
}

class ParticipantCountModal extends StatefulWidget {
  final EventModel event;
  final ConstraintModel constraint;
  final List<SlotModel> slots;

  const ParticipantCountModal({
    super.key,
    required this.event,
    required this.constraint,
    required this.slots,
  });

  @override
  State<ParticipantCountModal> createState() => _ParticipantCountModalState();
}

class _ParticipantCountModalState extends State<ParticipantCountModal> {
  int _count = 1;

  @override
  void initState() {
    super.initState();
    _count = widget.constraint.lowerLimit;
  }

  void _next() {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B1B26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ParticipantDetailsModal(
        event: widget.event,
        count: _count,
        slots: widget.slots,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isFixed = widget.constraint.fixed;
    bool isSingle = widget.constraint.bookingType == 'single';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 30,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'How many participants?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (isSingle)
            const Text(
              'This is a single participant event.',
              style: TextStyle(color: Colors.white70),
            )
          else if (isFixed)
            Text(
              'This requires exactly ${widget.constraint.upperLimit} participants.',
              style: const TextStyle(color: Colors.white70),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _count > widget.constraint.lowerLimit
                      ? () => setState(() => _count--)
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
                  onPressed: _count < widget.constraint.upperLimit
                      ? () => setState(() => _count++)
                      : null,
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _next,
              child: const Text(
                'Next Phase',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class ParticipantDetailsModal extends StatefulWidget {
  final EventModel event;
  final int count;
  final List<SlotModel> slots;

  const ParticipantDetailsModal({
    super.key,
    required this.event,
    required this.count,
    required this.slots,
  });

  @override
  State<ParticipantDetailsModal> createState() =>
      _ParticipantDetailsModalState();
}

class _ParticipantDetailsModalState extends State<ParticipantDetailsModal> {
  late List<Map<String, TextEditingController>> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.count,
      (index) => {
        'name': TextEditingController(),
        'email': TextEditingController(),
        'phone': TextEditingController(),
      },
    );
  }

  void _next() {
    // Validate
    for (var c in _controllers) {
      if (c['name']!.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All participant names are required.')),
        );
        return;
      }
    }

    final participants = _controllers
        .map(
          (c) => {
            'name': c['name']!.text.trim(),
            'email': c['email']!.text.trim(),
            'phone': c['phone']!.text.trim(),
          },
        )
        .toList();

    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B1B26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SlotPickerModal(
        event: widget.event,
        participants: participants,
        slots: widget.slots,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 30,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Participant Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.count,
                itemBuilder: (context, i) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B2B36),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Participant ${i + 1}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _controllers[i]['name'],
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Full Name *',
                            labelStyle: TextStyle(color: Colors.white54),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                          ),
                        ),
                        TextField(
                          controller: _controllers[i]['email'],
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Email (Optional)',
                            labelStyle: TextStyle(color: Colors.white54),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _next,
                child: const Text(
                  'Select Slot',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class SlotPickerModal extends ConsumerStatefulWidget {
  final EventModel event;
  final List<Map<String, String>> participants;
  final List<SlotModel> slots;

  const SlotPickerModal({
    super.key,
    required this.event,
    required this.participants,
    required this.slots,
  });

  @override
  ConsumerState<SlotPickerModal> createState() => _SlotPickerModalState();
}

class _SlotPickerModalState extends ConsumerState<SlotPickerModal> {
  SlotModel? _selectedSlot;
  bool _isLoading = false;

  Future<void> _completeBooking() async {
    if (_selectedSlot == null) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(cartServiceProvider)
          .addToCart(
            eventId: widget.event.id.toString(),
            participants: widget.participants,
            slotId: _selectedSlot!.id,
          );
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1B1B26),
          title: const Text('Success', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Added to Cart securely!',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFF7C3AED)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int requested = widget.participants.length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20).copyWith(top: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a Time Slot',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (widget.slots.isEmpty)
              const Text(
                'No slots available for this event.',
                style: TextStyle(color: Colors.redAccent),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.slots.length,
                  itemBuilder: (context, i) {
                    final slot = widget.slots[i];
                    bool hasCapacity =
                        slot.unlimitedParticipants ||
                        (slot.availableParticipants != null &&
                            slot.availableParticipants! >= requested);

                    return GestureDetector(
                      onTap: hasCapacity
                          ? () => setState(() => _selectedSlot = slot)
                          : null,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedSlot == slot
                              ? const Color(0xFF7C3AED).withOpacity(0.3)
                              : const Color(0xFF2B2B36),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedSlot == slot
                                ? const Color(0xFF7C3AED)
                                : Colors.white10,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${slot.startTime} - ${slot.endTime}',
                                  style: TextStyle(
                                    color: hasCapacity
                                        ? Colors.white
                                        : Colors.white38,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  slot.unlimitedParticipants
                                      ? 'Unlimited spots'
                                      : '${slot.availableParticipants} spots left',
                                  style: TextStyle(
                                    color: hasCapacity
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            if (_selectedSlot == slot)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF7C3AED),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: (_selectedSlot == null || _isLoading)
                    ? null
                    : _completeBooking,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Add To Cart',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
