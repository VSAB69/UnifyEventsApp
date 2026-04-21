import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/cached_participant.dart';

// Provider to fetch secure events list based on User Role (Admin / Organiser)
final manageEventsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final box = Hive.box<CachedParticipant>('participants');

  try {
    final res = await dio.get("/events/");
    List<dynamic> dataList = [];

    if (res.data is List) {
      dataList = res.data;
    } else if (res.data is Map) {
      dataList = res.data['results'] ?? res.data['data'] ?? [];
    }

    // Save events and participants to cache
    await box.clear(); // Clear stale cache
    for (var event in dataList) {
      final participants = event['participants'] as List<dynamic>? ?? [];
      for (var p in participants) {
        final cached = CachedParticipant(
          id: p['id']?.toString() ?? '',
          name: p['name']?.toString() ?? 'Attendee',
          eventId: event['id']?.toString() ?? '',
          eventName: event['name']?.toString() ?? 'Event',
          qrToken: p['qr_token']?.toString() ?? '',
          isCheckedIn: p['checked_in'] == true,
        );
        // Important Rule: we cache check-in state but DO NOT trust it for scan validation (handled in SyncService)
        await box.add(cached);
      }
      
      // If there are no participants, we might still want to cache the event name 
      // but CachedParticipant requires an id. Since the requirement just focuses on participants list, 
      // saving only participants is fine. If the UI needs empty events, maybe we add a dummy participant or cache events separately.
    }

    return dataList;
  } on DioError catch (_) {
    // Return offline data
    if (box.isEmpty) {
      throw "Manage Events Failed: Offline and no cache";
    }

    final participants = box.values.toList();
    final Map<String, List<CachedParticipant>> grouped = {};
    for (var p in participants) {
      grouped.putIfAbsent(p.eventId, () => []).add(p);
    }

    List<dynamic> offlineEvents = [];
    for (var entry in grouped.entries) {
      final eventId = entry.key;
      final parts = entry.value;

      offlineEvents.add({
        "id": int.tryParse(eventId) ?? 0,
        "name": parts.first.eventName,
        "is_offline": true,
        "participants": parts.map((p) => {
          "id": p.id,
          "name": p.name,
          "qr_token": p.qrToken,
          "checked_in": p.isCheckedIn,
        }).toList(),
      });
    }

    return offlineEvents;
  } catch (e) {
    throw "Failed to parse manage events: $e";
  }
});

final categoriesProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final res = await ref.read(dioProvider).get("/categories/");
  return (res.data is List) ? res.data : (res.data['results'] ?? []);
});

final parentEventsProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final res = await ref.read(dioProvider).get("/parent-events/");
  return (res.data is List) ? res.data : (res.data['results'] ?? []);
});

final organisersProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final res = await ref.read(dioProvider).get("/organisers/");
  return (res.data is List) ? res.data : (res.data['results'] ?? []);
});
