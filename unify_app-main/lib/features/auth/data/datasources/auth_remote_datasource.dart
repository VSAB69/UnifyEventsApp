import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/auth_response_model.dart';

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
}
