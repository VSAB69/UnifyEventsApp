import 'dart:async'; // ✅ ADD THIS

import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl {
  final AuthRemoteDataSource remote;
  final SecureStorageService storage;

  AuthRepositoryImpl(this.remote, this.storage);

  Future<void> login(String username, String password) async {
    try {
      final response = await remote
          .login(username: username, password: password)
          .timeout(const Duration(seconds: 15));

      await storage.saveTokens(response.access, response.refresh);
      await storage.saveUsername(username);
    } on DioException catch (e) {
      final message = e.response?.data["error"] ?? "Login failed. Try again.";
      throw AppException(message);
    } on TimeoutException {
      throw AppException("Server is waking up... try again in a few seconds");
    } catch (_) {
      throw AppException("Something went wrong");
    }
  }

  Future<void> logout() async {
    final refresh = await storage.getRefreshToken();

    try {
      if (refresh != null) {
        await remote.dio.post(
          "/api/mobile-auth/logout/",
          data: {"refresh": refresh},
        );
      }
    } catch (_) {}

    await storage.clearTokens();
  }

  Future<String?> isLoggedIn() async {
    final token = await storage.getAccessToken();

    if (token == null) return null;

    try {
      await remote.dio
          .get("/api/mobile-auth/me/")
          .timeout(const Duration(seconds: 10));

      return await storage.getUsername();
    } catch (e) {
      return null;
    }
  }
}
