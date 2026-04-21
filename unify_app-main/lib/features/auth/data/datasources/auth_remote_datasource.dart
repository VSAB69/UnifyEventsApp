import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/auth_response_model.dart';

class AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSource(this.dio);

  Future<AuthResponseModel> login({
    required String username,
    required String password,
  }) async {
    final response = await dio.post(
      ApiConstants.login,
      data: {"username": username, "password": password},
    );

    return AuthResponseModel.fromJson(response.data);
  }

  Future<AuthResponseModel> googleLogin(String idToken) async {
    final response = await dio.post(
      ApiConstants.google,
      data: {"id_token": idToken},
    );
    return AuthResponseModel.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await dio.get(ApiConstants.me);
    return response.data;
  }

  Future<void> setUsername(String username) async {
    await dio.post(
      ApiConstants.setUsername,
      data: {"username": username},
    );
  }

  Future<void> setPassword(String password) async {
    await dio.post(
      ApiConstants.setPassword,
      data: {"password": password},
    );
  }
}
