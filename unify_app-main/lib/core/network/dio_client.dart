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
            final dataStr = e.response?.data?.toString() ?? "";
            final isAuthError =
                e.response?.statusCode == 401 ||
                dataStr.contains(
                  "Authentication credentials were not provided.",
                );

            if (isAuthError) {
              // 🔥 CLEAR AUTH STATE
              final auth = ref.read(authProvider.notifier);
              await auth.logout();

              // 🔥 NAVIGATE TO LOGIN
              final context = navigatorKey.currentContext;
              if (context != null) {
                GoRouter.of(context).go('/login');
              }
            }

            return handler.next(e);
          },
        ),
      );
    }
  }
}
