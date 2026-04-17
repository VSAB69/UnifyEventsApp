import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final myBookingsProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final dio = ref.read(dioProvider);
  try {
    // ⚠️ STRICT RULE: Must use /bookings/ endpoint
    final response = await dio.get('/bookings/');
    List<dynamic> dataList = [];

    if (response.data is List) {
      dataList = response.data;
    } else if (response.data is Map) {
      dataList = response.data['results'] ?? response.data['data'] ?? [];
    }

    // Sort so most recent bookings appear at the top (descending ID usually handles chronological order in typical django API)
    dataList.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));
    return dataList;
  } catch (e) {
    throw "Failed to fetch bookings";
  }
});
