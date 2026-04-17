import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class CachedImage {
  final String url;
  final DateTime expiry;

  CachedImage(this.url, this.expiry);
}

class R2ImageService {
  final Dio _dio;
  final Map<String, CachedImage> _cache = {};

  R2ImageService(this._dio);

  Future<String?> getSignedUrl(String imageKey) async {
    if (_cache.containsKey(imageKey)) {
      final cached = _cache[imageKey]!;
      // Use safety buffer of 30 seconds
      if (DateTime.now().isBefore(cached.expiry)) {
        return cached.url;
      }
    }
    try {
      final response = await _dio.get(
        '/secure/event-image/',
        queryParameters: {'key': imageKey},
      );

      if (response.statusCode == 200) {
        final url = response.data['url']?.toString();
        final expiresIn =
            int.tryParse(response.data['expires_in']?.toString() ?? '300') ??
            300;

        if (url != null) {
          final expiryTime = DateTime.now().add(
            Duration(seconds: expiresIn - 30),
          );
          _cache[imageKey] = CachedImage(url, expiryTime);
          return url;
        }
      }
      return null;
    } catch (e) {
      return null; // Handle errors safely, return null on failure
    }
  }

  void invalidateCache(String imageKey) {
    _cache.remove(imageKey);
  }
}

final r2ImageServiceProvider = Provider<R2ImageService>((ref) {
  return R2ImageService(ref.read(dioProvider));
});

final eventImageProvider = FutureProvider.family<String?, String>((
  ref,
  imageKey,
) async {
  // Cache the signed URL to avoid refetching.
  // It expires in 300s. We can let riverpod cache it as long as the provider is alive.
  // We can also use ref.keepAlive() to maintain cache across rebuilds within the page.
  ref.keepAlive();

  final service = ref.read(r2ImageServiceProvider);
  return await service.getSignedUrl(imageKey);
});
