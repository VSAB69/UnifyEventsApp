import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/errors/app_exception.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';

/// STATE
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;
  final String? username;

  AuthState({
    required this.isLoading,
    required this.isAuthenticated,
    this.error,
    this.username,
  });

  factory AuthState.initial() =>
      AuthState(isLoading: true, isAuthenticated: false);

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
    String? username,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: clearError ? null : (error ?? this.error),
      username: username ?? this.username,
    );
  }
}

/// PROVIDERS
final storageProvider = Provider((ref) => SecureStorageService());

final dioProvider = Provider((ref) {
  final storage = ref.read(storageProvider);
  return DioClient(storage).dio;
});

final authRemoteProvider = Provider((ref) {
  return AuthRemoteDataSource(ref.read(dioProvider));
});

final authRepositoryProvider = Provider((ref) {
  return AuthRepositoryImpl(
    ref.read(authRemoteProvider),
    ref.read(storageProvider),
  );
});

/// NOTIFIER
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepositoryImpl repo;

  AuthNotifier(this.repo) : super(AuthState.initial());

  Future<void> checkAuth() async {
    try {
      final username = await repo.isLoggedIn().timeout(
        const Duration(seconds: 12),
      );

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: username != null,
        username: username,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, isAuthenticated: false);
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await repo.login(username, password).timeout(const Duration(seconds: 20));

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        username: username,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: "Something went wrong",
      );
    }
  }

  Future<void> logout() async {
    await repo.logout();

    state = AuthState(isLoading: false, isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
