import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Provider to fetch secure events list based on User Role (Admin / Organiser)
final manageEventsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get("/events/");
    print("EVENTS API RESPONSE: ${res.data}");
    
    if (res.data is List) {
      return res.data;
    } else if (res.data is Map) {
      return res.data['results'] ?? res.data['data'] ?? [];
    }
    return [];
  } catch (e) {
    print("EVENTS API ERROR: $e");
    if (e is DioException) {
      throw "Manage Events Failed: ${e.response?.statusCode} - ${e.response?.data}";
    }
    throw "Failed to fetch manage events: $e";
  }
});

final categoriesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ref.read(dioProvider).get("/categories/");
  return (res.data is List) ? res.data : (res.data['results'] ?? []);
});

final parentEventsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ref.read(dioProvider).get("/parent-events/");
  return (res.data is List) ? res.data : (res.data['results'] ?? []);
});

final organisersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ref.read(dioProvider).get("/organisers/");
  return (res.data is List) ? res.data : (res.data['results'] ?? []);
});
