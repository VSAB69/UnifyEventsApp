import 'dart:async';
import 'dart:developer' as dev;
import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../domain/models/user_model.dart';

class AuthRepositoryImpl {
  final AuthRemoteDataSource remote;
  final SecureStorageService storage;

  AuthRepositoryImpl(this.remote, this.storage);

  Future<UserModel> login(String username, String password) async {
    try {
      final response = await remote
          .login(username: username, password: password)
          .timeout(const Duration(seconds: 15));

      await storage.saveTokens(response.access, response.refresh);
      await storage.saveUsername(username);

      final userResponse = await remote.getCurrentUser();
      return UserModel.fromJson(userResponse);
    } on DioException catch (e) {
      final message = e.response?.data["error"] ?? "Login failed. Try again.";
      throw AppException(message);
    } on TimeoutException {
      throw AppException("Server is waking up... try again in a few seconds");
    } catch (_) {
      throw AppException("Something went wrong");
    }
  }

  Future<UserModel> googleLogin(String idToken) async {
    try {
      dev.log("🚀 Calling Backend Google Login API");
      final response = await remote
          .googleLogin(idToken)
          .timeout(const Duration(seconds: 15));

      dev.log("✅ Backend response received: ${response.access.substring(0, 10)}...");
      await storage.saveTokens(response.access, response.refresh);

      dev.log("🚀 Fetching current user profile");
      final userResponse = await remote.getCurrentUser();
      dev.log("✅ Current user profile fetched");

      return UserModel.fromJson(userResponse);
    } on DioException catch (e) {
      dev.log("🔥 Backend Google Login Error: ${e.response?.data}");
      final message = e.response?.data["error"] ?? "Google Login failed.";
      throw AppException(message);
    } catch (e) {
      dev.log("🔥 Unexpected Google Login Error: $e");
      throw AppException("Google Sign-In failed");
    }
  }

  Future<void> setUsername(String username) async {
    try {
      await remote.setUsername(username);
    } on DioException catch (e) {
      throw AppException(e.response?.data["error"] ?? "Failed to set username");
    }
  }

  Future<void> setPassword(String password) async {
    try {
      await remote.setPassword(password);
    } on DioException catch (e) {
      throw AppException(e.response?.data["error"] ?? "Failed to set password");
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

  Future<UserModel?> getCurrentUser() async {
    final token = await storage.getAccessToken();

    if (token == null) return null;

    try {
      final userResponse = await remote.getCurrentUser();
      return UserModel.fromJson(userResponse);
    } catch (e) {
      return null;
    }
  }
}
