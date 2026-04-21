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
import 'package:qr_flutter/qr_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/providers/event_details_provider.dart';
import '../../domain/models/slot_info.dart';

final bookedEventProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) async {
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

class _TicketPageState extends ConsumerState<TicketPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _particlesController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(bookedEventProvider(widget.bookedEventId));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookedAsync = ref.watch(bookedEventProvider(widget.bookedEventId));

    return Scaffold(
      backgroundColor: const Color(0xFF06060A),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Digital Pass',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          bookedAsync.maybeWhen(
            data: (data) => data['is_offline'] == true
                ? Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'OFFLINE',
                      style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  )
                : const SizedBox(),
            orElse: () => const SizedBox(),
          )
        ],
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
                  final dx =
                      100 *
                      (index % 2 == 0 ? 1 : -1) *
                      (1 + 0.5 * sin(t + index * 2));
                  return Positioned(
                    top:
                        MediaQuery.of(context).size.height *
                            (0.2 + index * 0.2) +
                        50 * (t + index).sign,
                    left:
                        MediaQuery.of(context).size.width *
                            (0.2 + (index % 2) * 0.5) +
                        dx,
                    child: Container(
                      width: 150 + index * 50,
                      height: 150 + index * 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index % 2 == 0
                            ? const Color(0xFF7C3AED).withOpacity(0.15)
                            : const Color(0xFFE81CFF).withOpacity(0.15),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (index % 2 == 0
                                        ? const Color(0xFF7C3AED)
                                        : const Color(0xFFE81CFF))
                                    .withOpacity(0.2),
                            blurRadius: 100,
                            spreadRadius: 50,
                          ),
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
                final participants =
                    (bookedEvent['participants'] as List?) ?? [];
                if (participants.isEmpty) {
                  return const Center(
                    child: Text(
                      "No passes found.",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return PageView.builder(
                  itemCount: participants.length,
                  physics: const BouncingScrollPhysics(),
                  controller: PageController(viewportFraction: 0.85),
                  itemBuilder: (context, index) {
                    final p = participants[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 20,
                      ),
                      child: ParticipantTicketCard(
                        participant: p,
                        bookedEvent: bookedEvent,
                        bookedEventId: widget.bookedEventId,
                      ),
                    );
                  },
                );
              },
              loading: () => Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                ),
              ),
              error: (_, __) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.search_off,
                      color: Colors.white54,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ticket not found',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(bookedEventProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ParticipantTicketCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> participant;
  final Map<String, dynamic> bookedEvent;
  final int bookedEventId;

  const ParticipantTicketCard({
    super.key,
    required this.participant,
    required this.bookedEvent,
    required this.bookedEventId,
  });

  @override
  ConsumerState<ParticipantTicketCard> createState() =>
      _ParticipantTicketCardState();
}

class _ParticipantTicketCardState extends ConsumerState<ParticipantTicketCard>
    with TickerProviderStateMixin {
  final GlobalKey _ticketKey = GlobalKey();
  late AnimationController _entryController;
  late AnimationController _tiltController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _tiltController.dispose();
    super.dispose();
  }

  Future<void> _shareTicket() async {
    setState(() => _isSaving = true);
    try {
      final boundary =
          _ticketKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File(
        '${tempDir.path}/unify_ticket_${widget.bookedEventId}_${widget.participant['id']}.png',
      ).create();
      await file.writeAsBytes(buffer);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'My Unify Event Pass 🎉');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share ticket.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventName =
        widget.bookedEvent['event_name']?.toString().toUpperCase() ?? 'EVENT';
    final p = widget.participant;
    final bool arrived = p['arrived'] == true || p['qr_used'] == true;
    final qrToken = p['qr_token'] ?? '';

    // fetch event details for venue
    final eventIdRaw =
        widget.bookedEvent['event_id'] ?? widget.bookedEvent['event'] ?? '';
    final eventId = eventIdRaw is Map
        ? eventIdRaw['id'].toString()
        : eventIdRaw.toString();
    final eventDetailsAsync = ref.watch(eventDetailsDataProvider(eventId));

    return AnimatedBuilder(
      animation: Listenable.merge([_entryController, _tiltController]),
      builder: (context, child) {
        final entryScale =
            CurvedAnimation(
                  parent: _entryController,
                  curve: Curves.easeOutBack,
                ).value *
                0.2 +
            0.8;
        final entryOpacity = CurvedAnimation(
          parent: _entryController,
          curve: Curves.easeIn,
        ).value;
        final tiltY = 0.03 * (_tiltController.value - 0.5);

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _ticketKey,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF13131D).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF7C3AED).withOpacity(0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.2),
                      blurRadius: 40,
                      spreadRadius: -5,
                    ),
                    BoxShadow(
                      color: const Color(0xFFE81CFF).withOpacity(0.1),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Background gradient
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.05),
                                Colors.transparent,
                                const Color(0xFF7C3AED).withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.stars,
                                  color: Color(0xFFE81CFF),
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'EVENT PASS CONFIRMED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(
                              color: Colors.white24,
                              height: 1,
                              thickness: 1,
                            ),
                            const SizedBox(height: 16),

                            Text(
                              eventName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 24),

                            // QR DISPLAY
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: arrived
                                          ? Colors.greenAccent.withOpacity(0.2)
                                          : const Color(
                                              0xFF38BDF8,
                                            ).withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: arrived
                                    ? const SizedBox(
                                        height: 160,
                                        width: 160,
                                        child: Center(
                                          child: Text(
                                            "Checked In",
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      )
                                    : QrImageView(
                                        data:
                                            """{"type": "event_checkin", "token": "$qrToken", "participant_id": ${p['id']}}""",
                                        version: QrVersions.auto,
                                        size: 160.0,
                                        gapless: false,
                                      ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // User info
                            Text(
                              p['name']?.toString() ?? 'Attendee',
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (p['email'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                p['email'].toString(),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            if (p['phone'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                p['phone'].toString(),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                            ],

                            const Spacer(),

                            // Event Details bottom area
                            const Divider(
                              color: Colors.white24,
                              height: 1,
                              thickness: 1,
                            ),
                            const SizedBox(height: 16),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildSlotInfoUI(
                                    widget.bookedEvent['slot_info'],
                                  ),
                                ),
                                Expanded(
                                  child: eventDetailsAsync.when(
                                    data: (details) => _buildInfoItem(
                                      Icons.location_on,
                                      'Venue',
                                      details['venue']?.toString() ?? 'TBA',
                                    ),
                                    loading: () => const Align(
                                      alignment: Alignment.centerLeft,
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white24,
                                        ),
                                      ),
                                    ),
                                    error: (_, __) => _buildInfoItem(
                                      Icons.location_off,
                                      'Venue',
                                      'Failed to load',
                                    ),
                                  ),
                                ),
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
          ),

          const SizedBox(height: 20),

          // DOWNLOAD BUTTON
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE81CFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 10,
                shadowColor: const Color(0xFFE81CFF).withOpacity(0.5),
              ),
              onPressed: _isSaving ? null : _shareTicket,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.download_rounded, color: Colors.white),
              label: Text(
                _isSaving ? 'Processing...' : 'Export Pass',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSlotInfoUI(dynamic rawSlotInfo) {
    final slotInfo = SlotInfo.tryParse(rawSlotInfo);
    if (slotInfo == null)
      return _buildInfoItem(Icons.event_seat, 'Category', 'General Slot');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (slotInfo.date != null) ...[
          Row(
            children: [
              const Icon(
                Icons.calendar_month,
                size: 14,
                color: Color(0xFF7C3AED),
              ),
              const SizedBox(width: 6),
              const Text(
                'Date',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            slotInfo.date!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (slotInfo.startTime != null && slotInfo.endTime != null) ...[
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Color(0xFF7C3AED)),
              const SizedBox(width: 6),
              const Text(
                'Time',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${formatTimeHHMM(slotInfo.startTime)} - ${formatTimeHHMM(slotInfo.endTime)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
