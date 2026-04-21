import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const _accessTokenKey = "access_token";
  static const _refreshTokenKey = "refresh_token";

  static const _usernameKey = "username";

  // Save tokens
  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _accessTokenKey, value: access);
    await _storage.write(key: _refreshTokenKey, value: refresh);
  }

  // Save username
  Future<void> saveUsername(String username) async {
    await _storage.write(key: _usernameKey, value: username);
  }

  // Get access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // Get username
  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  // Get/Set Hive Encryption Key
  Future<String?> getHiveKey() async {
    return await _storage.read(key: 'hive_key');
  }

  Future<void> saveHiveKey(String keyStr) async {
    await _storage.write(key: 'hive_key', value: keyStr);
  }

  // Clear tokens
  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }
}
