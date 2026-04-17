import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/booking_models.dart';
import '../../../../core/errors/app_exception.dart';

final eventDetailsDataProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, eventId) async {
      final dio = ref.read(dioProvider);
      try {
        final response = await dio.get(
          '/event-details/',
          queryParameters: {'event': eventId},
        );
        if (response.data is List && response.data.isNotEmpty)
          return response.data[0];
        if (response.data is Map) {
          if (response.data['results'] != null &&
              response.data['results'].isNotEmpty)
            return response.data['results'][0];
          return response.data;
        }
        return {};
      } catch (e) {
        return {};
      }
    });

final constraintProvider = FutureProvider.family<ConstraintModel?, String>((
  ref,
  eventId,
) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get(
      '/constraints/',
      queryParameters: {'event': eventId},
    );
    print("Constraint API: ${res.data}");

    if (res.data is List && res.data.isNotEmpty) {
      return ConstraintModel.fromJson(res.data[0]);
    } else {
      return null;
    }
  } catch (e) {
    print("Constraint API Error: $e");
    return null;
  }
});

final slotsProvider = FutureProvider.family<List<SlotModel>, String>((
  ref,
  eventId,
) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get(
      '/event-slots/',
      queryParameters: {'event_id': eventId},
    );
    print("Slots API: ${res.data}");

    List<dynamic> data = [];
    if (res.data is List)
      data = res.data;
    else if (res.data is Map)
      data = res.data['results'] ?? [];

    return data.map((x) => SlotModel.fromJson(x)).where((slot) {
      return (slot.availableParticipants != null &&
              slot.availableParticipants! > 0) ||
          slot.unlimitedParticipants;
    }).toList();
  } catch (e) {
    print("Slots API Error: $e");
    return [];
  }
});

class CartService {
  final Dio _dio;
  CartService(this._dio);

  Future<void> addToCart({
    required String eventId,
    required List<Map<String, String>> participants,
    required int slotId,
  }) async {
    try {
      // 0. Fetch the cart ID if we need it
      final cartFetch = await _dio.get('/cart/');
      String? cartId;
      if (cartFetch.data is List && cartFetch.data.isNotEmpty) {
        cartId = cartFetch.data[0]['id'].toString();
      } else if (cartFetch.data is Map) {
        if (cartFetch.data.containsKey('results') &&
            cartFetch.data['results'] is List &&
            cartFetch.data['results'].isNotEmpty) {
          cartId = cartFetch.data['results'][0]['id'].toString();
        } else if (cartFetch.data.containsKey('id')) {
          cartId = cartFetch.data['id'].toString();
        }
      }

      if (cartId == null) {
        final newCart = await _dio.post('/cart/');
        if (newCart.data != null &&
            newCart.data is Map &&
            newCart.data.containsKey('id')) {
          cartId = newCart.data['id'].toString();
        } else {
          throw AppException("Could not find or create active cart");
        }
      }

      // 1. Create cart item
      final cartResponse = await _dio.post(
        '/cartitems/',
        data: {
          'cart': cartId,
          'event': eventId,
          'participants_count': participants.length,
        },
      );

      final cartItemId = cartResponse.data['id'];

      // 2. Add participants (tempbookings)
      for (var p in participants) {
        await _dio.post(
          '/tempbookings/',
          data: {
            'cart_item': cartItemId,
            'name': p['name'],
            'email': p['email'] ?? '',
            'phone': p['phone'] ?? '',
          },
        );
      }

      // 3. Add slot
      await _dio.post(
        '/temp-timeslots/',
        data: {'cart_item': cartItemId, 'slot': slotId},
      );
    } on DioError catch (e) {
      throw AppException(
        e.response?.data?.toString() ?? "Failed to add to cart",
      );
    }
  }
}

final cartServiceProvider = Provider<CartService>((ref) {
  return CartService(ref.read(dioProvider));
});
