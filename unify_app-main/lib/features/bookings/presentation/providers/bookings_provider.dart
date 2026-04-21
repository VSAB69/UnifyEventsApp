import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/cached_ticket.dart';

final myBookingsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final box = Hive.box<CachedTicket>('tickets');

  try {
    final response = await dio.get('/bookings/');
    List<dynamic> dataList = [];

    if (response.data is List) {
      dataList = response.data;
    } else if (response.data is Map) {
      dataList = response.data['results'] ?? response.data['data'] ?? [];
    }

    // Sort so most recent bookings appear at the top
    dataList.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));

    // Save to Hive
    await box.clear(); // Clear old cache to avoid stale tickets
    for (var booking in dataList) {
      final bookedEvents = booking['booked_events'] as List<dynamic>? ?? [];
      for (var bEvent in bookedEvents) {
        final participants = bEvent['participants'] as List<dynamic>? ?? [];
        for (var p in participants) {
          final ticket = CachedTicket(
            participantId: p['id']?.toString() ?? '',
            name: p['name']?.toString() ?? 'Attendee',
            eventName: bEvent['event_name']?.toString() ?? 'Event',
            slot: bEvent['slot_info']?.toString() ?? '',
            qrToken: p['qr_token']?.toString() ?? '',
            isCheckedIn: p['checked_in'] == true,
            cachedAt: DateTime.now(),
          );
          await box.add(ticket);
        }
      }
    }

    return dataList;
  } on DioError catch (_) {
    // Offline / Failure Mode
    if (box.isEmpty) {
      throw "Failed to fetch bookings and no offline cache available";
    }

    // Reconstruct bookings structure from Hive
    final cachedTickets = box.values.toList();
    // Group by eventName (since offline we may not have original booking ids)
    final Map<String, List<CachedTicket>> groupedByEvent = {};
    for (var t in cachedTickets) {
      groupedByEvent.putIfAbsent(t.eventName, () => []).add(t);
    }

    List<dynamic> offlineBookings = [];
    int dummyId = 9999;
    
    for (var entry in groupedByEvent.entries) {
      final eventName = entry.key;
      final tickets = entry.value;

      offlineBookings.add({
        "id": dummyId,
        "is_offline": true,
        "total_amount": 0,
        "booked_events": [
          {
            "id": dummyId, // Used as bookedEventId in UI
            "event_name": eventName,
            "participants_count": tickets.length,
            "slot_info": tickets.first.slot,
            "participants": tickets.map((t) => {
              "id": t.participantId,
              "name": t.name,
              "qr_token": t.qrToken,
              "checked_in": t.isCheckedIn,
            }).toList(),
          }
        ]
      });
      dummyId--;
    }

    return offlineBookings;
  } catch (e) {
    throw "Failed to parse bookings: $e";
  }
});
