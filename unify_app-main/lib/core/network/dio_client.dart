import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../navigation/navigation_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class DioClient {
  late Dio dio;

  DioClient(SecureStorageService storage, [Ref? ref]) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    dio.interceptors.add(AuthInterceptor(dio, storage));

    if (ref != null) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onError: (e, handler) async {
            final status = e.response?.statusCode;

            // ✅ ONLY logout on actual 401
            if (status == 401) {
              final context = navigatorKey.currentContext;

              // clear auth safely
              final auth = ref.read(authProvider.notifier);
              await auth.logout();

              if (context != null) {
                GoRouter.of(context).go('/login');
              }
            }

            // ❌ DO NOT logout for network errors
            final typeStr = e.type.toString().toLowerCase();
            if (typeStr.contains('connection') ||
                typeStr.contains('unknown') ||
                typeStr.contains('timeout') ||
                typeStr.contains('other')) {
              // Offline → DO NOT logout
            }

            return handler.next(e);
          },
        ),
      );
    }
  }
}
