import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/providers/event_details_provider.dart';
import '../../domain/models/slot_info.dart';

final bookedEventProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, id) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/booked-events/$id/');
  return res.data;
});

class TicketPage extends ConsumerStatefulWidget {
  final int bookedEventId;

  const TicketPage({super.key, required this.bookedEventId});

  @override
  ConsumerState<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends ConsumerState<TicketPage> with TickerProviderStateMixin {
  final GlobalKey _ticketKey = GlobalKey();
  
  late AnimationController _entryController;
  late AnimationController _stampController;
  late AnimationController _particlesController;
  late AnimationController _tiltController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..forward();
    _stampController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _particlesController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _tiltController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _stampController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _stampController.dispose();
    _particlesController.dispose();
    _tiltController.dispose();
    super.dispose();
  }

  Future<void> _shareTicket() async {
    setState(() => _isSaving = true);
    try {
      final boundary = _ticketKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/unify_ticket_${widget.bookedEventId}.png').create();
      await file.writeAsBytes(buffer);

      await Share.shareXFiles([XFile(file.path)], text: 'My Unify Event Ticket 🎉');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to share ticket.')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookedAsync = ref.watch(bookedEventProvider(widget.bookedEventId));

    return Scaffold(
      backgroundColor: const Color(0xFF06060A),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => context.pop()),
        title: const Text('Digital Pass', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Animated Particles
          AnimatedBuilder(
            animation: _particlesController,
            builder: (context, _) {
              return Stack(
                children: List.generate(4, (index) {
                  final t = _particlesController.value * 2 * 3.14159;
                  final dx = 100 * (index % 2 == 0 ? 1 : -1) * (1 + 0.5 * sin(t + index * 2)); // pseudo-random dummy logic
                  return Positioned(
                    top: MediaQuery.of(context).size.height * (0.2 + index * 0.2) + 50 * (t + index).sign,
                    left: MediaQuery.of(context).size.width * (0.2 + (index % 2) * 0.5) + dx,
                    child: Container(
                      width: 150 + index * 50,
                      height: 150 + index * 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index % 2 == 0 ? const Color(0xFF7C3AED).withOpacity(0.15) : const Color(0xFFE81CFF).withOpacity(0.15),
                        boxShadow: [
                          BoxShadow(color: (index % 2 == 0 ? const Color(0xFF7C3AED) : const Color(0xFFE81CFF)).withOpacity(0.2), blurRadius: 100, spreadRadius: 50),
                        ],
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          
          SafeArea(
            child: bookedAsync.when(
              data: (bookedEvent) {
                final eventIdRaw = bookedEvent['event_id'] ?? bookedEvent['event'] ?? '';
                final eventId = eventIdRaw is Map ? eventIdRaw['id'].toString() : eventIdRaw.toString();

                final eventDetailsAsync = ref.watch(eventDetailsDataProvider(eventId));
                
                return Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20).copyWith(bottom: 120),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_entryController, _tiltController]),
                      builder: (context, child) {
                        final entryScale = CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack).value * 0.2 + 0.8;
                        final entryOpacity = CurvedAnimation(parent: _entryController, curve: Curves.easeIn).value;
                        
                        // 3D Tilt hovering effect
                        final tiltY = 0.05 * (_tiltController.value - 0.5);

                        return Opacity(
                          opacity: entryOpacity,
                          child: Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..scale(entryScale)
                              ..rotateX(tiltY)
                              ..rotateY(-tiltY),
                            alignment: Alignment.center,
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RepaintBoundary(
                            key: _ticketKey,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF13131D).withOpacity(0.85),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.5), width: 1.5),
                                boxShadow: [
                                  BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.2), blurRadius: 40, spreadRadius: -5),
                                  BoxShadow(color: const Color(0xFFE81CFF).withOpacity(0.1), blurRadius: 40, offset: const Offset(0, 20)),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Stack(
                                  children: [
                                    // Ticket Gradient Overlay
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.white.withOpacity(0.05), Colors.transparent, const Color(0xFF7C3AED).withOpacity(0.05)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        ),
                                      ),
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.all(28),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // HEADER
                                          const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.stars, color: Color(0xFFE81CFF), size: 24),
                                              SizedBox(width: 8),
                                              Text('EVENT PASS CONFIRMED', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                                            ],
                                          ),
                                          const SizedBox(height: 24),
                                          const Divider(color: Colors.white24, height: 1, thickness: 1),
                                          const SizedBox(height: 24),
                                          
                                          // EVENT DETAILS
                                          Text(bookedEvent['event_name']?.toString().toUpperCase() ?? 'EVENT', 
                                            textAlign: TextAlign.center, 
                                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.2)),
                                          
                                          const SizedBox(height: 24),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(child: _buildSlotInfoUI(bookedEvent['slot_info'])),
                                              Expanded(child: _buildInfoItem(Icons.group, 'Team Size', '${bookedEvent['participants_count'] ?? 1}')),
                                            ],
                                          ),
                                          const SizedBox(height: 16),

                                          eventDetailsAsync.when(
                                            data: (details) => Row(
                                              children: [
                                                Expanded(child: const SizedBox()), // Empty spacing or removed
                                                Expanded(child: _buildInfoItem(Icons.location_on, 'Venue', details['venue']?.toString() ?? 'TBA')),
                                              ],
                                            ),
                                            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white24)),
                                            error: (_, __) => _buildInfoItem(Icons.location_off, 'Venue', 'Failed to load details'),
                                          ),

                                          const SizedBox(height: 32),
                                          
                                          // PARTICIPANTS
                                          const Text('ATTENDEES', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                          const SizedBox(height: 12),
                                          ...((bookedEvent['participants'] as List?) ?? []).asMap().entries.map((entry) {
                                            final i = entry.key;
                                            final p = entry.value;
                                            
                                            return AnimatedBuilder(
                                              animation: _entryController,
                                              builder: (context, child) {
                                                // Stagger calculation
                                                final delay = 0.4 + (i * 0.1);
                                                final progress = ((_entryController.value - delay) / 0.4).clamp(0.0, 1.0);
                                                final slideY = 20 * (1 - progress);
                                                return Opacity(
                                                  opacity: progress,
                                                  child: Transform.translate(offset: Offset(0, slideY), child: child),
                                                );
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.person, color: Color(0xFF38BDF8), size: 18),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(p['name'] ?? 'Attendee', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                                          if (p['email'] != null) Text(p['email'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),

                                          const SizedBox(height: 24),
                                          const Divider(color: Colors.white24, height: 1, thickness: 1), 
                                          const SizedBox(height: 24),

                                          // TOTAL
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('TOTAL PAID:', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                              Text('₹${bookedEvent['line_total'] ?? 0}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 24, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // STAMP OVERLAY
                                    Positioned(
                                      top: 60,
                                      right: 10,
                                      child: ScaleTransition(
                                        scale: CurvedAnimation(parent: _stampController, curve: Curves.elasticOut),
                                        child: FadeTransition(
                                          opacity: CurvedAnimation(parent: _stampController, curve: Curves.easeIn),
                                          child: RotationTransition(
                                            turns: Tween(begin: 0.1, end: -0.05).animate(CurvedAnimation(parent: _stampController, curve: Curves.easeOutBack)),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.greenAccent, width: 3),
                                                borderRadius: BorderRadius.circular(8),
                                                color: Colors.black.withOpacity(0.5),
                                              ),
                                              child: const Text('PAID', style: TextStyle(color: Colors.greenAccent, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // DOWNLOAD BUTTON
                          FadeTransition(
                            opacity: CurvedAnimation(parent: _entryController, curve: const Interval(0.8, 1.0)),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE81CFF),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 10,
                                  shadowColor: const Color(0xFFE81CFF).withOpacity(0.5),
                                ),
                                onPressed: _isSaving ? null : _shareTicket,
                                icon: _isSaving 
                                   ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                   : const Icon(Icons.download_rounded, color: Colors.white),
                                label: Text(_isSaving ? 'Processing...' : 'Export & Share Pass', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))),
              error: (_, __) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off, color: Colors.white54, size: 64),
                    const SizedBox(height: 16),
                    const Text('Ticket not found', style: TextStyle(color: Colors.white, fontSize: 18)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () => ref.invalidate(bookedEventProvider), child: const Text('Retry'))
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF7C3AED)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSlotInfoUI(dynamic rawSlotInfo) {
    final slotInfo = SlotInfo.tryParse(rawSlotInfo);
    if (slotInfo == null) return _buildInfoItem(Icons.event_seat, 'Category', 'General Slot');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (slotInfo.date != null) ...[
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 14, color: Color(0xFF7C3AED)),
              const SizedBox(width: 6),
              const Text('Date', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 4),
          Text(slotInfo.date!, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
        ],
        if (slotInfo.startTime != null && slotInfo.endTime != null) ...[
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Color(0xFF7C3AED)),
              const SizedBox(width: 6),
              const Text('Time', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${formatTimeHHMM(slotInfo.startTime)} - ${formatTimeHHMM(slotInfo.endTime)}', 
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
