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
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      if (_isRefreshing) {
        // Wait until the other request completes the refresh
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          return _isRefreshing;
        });

        final newToken = await storage.getAccessToken();
        if (newToken != null) {
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';
          try {
            final retryResponse = await dio.fetch(options);
            return handler.resolve(retryResponse);
          } catch (e) {
            return handler.next(err);
          }
        } else {
          return handler.next(err);
        }
      }

      _isRefreshing = true;
      final refreshToken = await storage.getRefreshToken();

      if (refreshToken == null) {
        _isRefreshing = false;
        return handler.next(err);
      }

      try {
        final refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
        final response = await refreshDio.post(
          ApiConstants.refresh,
          data: {"refresh": refreshToken},
        );

        final newAccess = response.data["access"];
        await storage.saveTokens(newAccess, refreshToken);

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
