import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/event_model.dart';
import '../../../../core/errors/app_exception.dart';
import 'package:dio/dio.dart';

final eventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final dio = ref.read(dioProvider);

  try {
    // ✅ FIXED ENDPOINT
    final response = await dio.get('/events/browse/');

    List<dynamic> dataList = [];

    if (response.data is List) {
      dataList = response.data;
    } else if (response.data is Map) {
      dataList =
          response.data['results'] ??
          response.data['data'] ??
          response.data['events'] ??
          [];
    }

    return dataList.map((json) => EventModel.fromJson(json)).toList();
  } on DioError catch (e) {
    throw AppException(
      e.response?.data?['error'] ??
          e.response?.data?['detail'] ??
          "Failed to fetch events",
    );
  } catch (e, stack) {
    throw AppException("Parse Error: $e");
  }
});

final filteredEventsProvider = FutureProvider.family<List<EventModel>, String>((
  ref,
  type,
) async {
  final dio = ref.read(dioProvider);
  String? parentEventId;

  if (type == 'phaseshift') {
    parentEventId = '1';
  } else if (type == 'utsav') {
    parentEventId = '2';
  }

  try {
    final response = await dio.get(
      '/events/browse/',
      queryParameters: parentEventId != null
          ? {'parent_event': parentEventId}
          : null,
    );

    List<dynamic> dataList = [];
    if (response.data is List) {
      dataList = response.data;
    } else if (response.data is Map) {
      dataList =
          response.data['results'] ??
          response.data['data'] ??
          response.data['events'] ??
          [];
    }

    var events = dataList.map((json) => EventModel.fromJson(json)).toList();

    // For regular events, backend doesn't explicitly filter by exclusion natively, so we filter out 1 and 2 locally
    if (type == 'regular') {
      events = events
          .where((e) => e.parentEventId != 1 && e.parentEventId != 2)
          .toList();
    }

    return events;
  } on DioError catch (e) {
    throw AppException(
      e.response?.data?['error'] ??
          e.response?.data?['detail'] ??
          "Failed to fetch events",
    );
  } catch (e) {
    throw AppException("Parse Error: $e");
  }
});
