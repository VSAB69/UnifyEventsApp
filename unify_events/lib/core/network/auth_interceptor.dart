import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';
import '../constants/api_constants.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final SecureStorageService storage;

  bool _isRefreshing = false;

  AuthInterceptor(this.dio, this.storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.getAccessToken();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // If unauthorized → try refresh
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      final refreshToken = await storage.getRefreshToken();

      if (refreshToken == null) {
        _isRefreshing = false;
        return handler.next(err);
      }

      try {
        final response = await dio.post(
          ApiConstants.refresh,
          data: {"refresh": refreshToken},
        );

        final newAccess = response.data["access"];

        // Save new access token
        await storage.saveTokens(newAccess, refreshToken);

        // Retry original request
        final options = err.requestOptions;

        options.headers['Authorization'] = 'Bearer $newAccess';

        final retryResponse = await dio.fetch(options);

        _isRefreshing = false;
        return handler.resolve(retryResponse);
      } catch (e) {
        _isRefreshing = false;
        await storage.clearTokens();
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}
