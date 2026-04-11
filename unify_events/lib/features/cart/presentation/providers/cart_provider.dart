import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final cartDataProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('/cart/');
    if (response.data is List && response.data.isNotEmpty) {
      return response.data[0];
    }
    return response.data is Map ? response.data as Map<String, dynamic> : {};
  } catch (e) {
    throw Exception('Failed to load cart');
  }
});

final tempBookingsProvider = FutureProvider.autoDispose.family<List<dynamic>, int>((ref, cartItemId) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('/tempbookings/', queryParameters: {'cart_item': cartItemId});
    List<dynamic> all = [];
    if (response.data is List) all = response.data;
    if (response.data is Map && response.data['results'] != null) all = response.data['results'];
    
    return all.where((b) {
      final bCartItem = b['cart_item'];
      if (bCartItem == null) return false;
      final bCartItemId = bCartItem is Map ? bCartItem['id'] : bCartItem;
      return bCartItemId.toString() == cartItemId.toString();
    }).toList();
  } catch (e) {
    return [];
  }
});

final tempTimeslotsProvider = FutureProvider.autoDispose.family<List<dynamic>, int>((ref, cartItemId) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('/temp-timeslots/', queryParameters: {'cart_item': cartItemId});
    List<dynamic> all = [];
    if (response.data is List) all = response.data;
    if (response.data is Map && response.data['results'] != null) all = response.data['results'];
    
    return all.where((t) {
      final tCartItem = t['cart_item'];
      if (tCartItem == null) return false;
      final tCartItemId = tCartItem is Map ? tCartItem['id'] : tCartItem;
      return tCartItemId.toString() == cartItemId.toString();
    }).toList();
  } catch (e) {
    return [];
  }
});

class CartActionService {
  final Dio _dio;
  CartActionService(this._dio);

  Future<void> removeCartItem(int itemId) async {
    await _dio.delete('/cartitems/$itemId/');
  }

  Future<void> updateCartItem(int itemId, Map<String, dynamic> data) async {
    await _dio.patch('/cartitems/$itemId/', data: data);
  }

  Future<void> updateParticipant(int bookingId, Map<String, dynamic> data) async {
    await _dio.patch('/tempbookings/$bookingId/', data: data);
  }

  Future<void> addParticipant(Map<String, dynamic> data) async {
    await _dio.post('/tempbookings/', data: data);
  }

  Future<void> removeParticipant(int bookingId) async {
    await _dio.delete('/tempbookings/$bookingId/');
  }

  Future<void> updateTimeSlot(Map<String, dynamic> data) async {
    await _dio.post('/temp-timeslots/', data: data); // POST creates or updates temp slot logic (handled by backend or we must specify cart_item)
  }
}

final cartActionProvider = Provider<CartActionService>((ref) {
  return CartActionService(ref.read(dioProvider));
});
