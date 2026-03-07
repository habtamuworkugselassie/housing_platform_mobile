import '../network/api_client.dart';
import '../models/auth_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  AuthService(this._apiClient, [this._storage = const FlutterSecureStorage()]);

  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _apiClient.post(
      '/auth/login',
      data: request.toJson(),
    );
    
    final authResponse = AuthResponse.fromJson(response.data);
    await _saveTokens(authResponse);
    return authResponse;
  }

  Future<AuthResponse> register(RegistrationRequest request) async {
    final response = await _apiClient.post(
      '/auth/register',
      data: request.toJson(),
    );
    
    final authResponse = AuthResponse.fromJson(response.data);
    await _saveTokens(authResponse);
    return authResponse;
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (_) {
      // Ignored: Token might already be invalid, we just want to clear local storage anyway
    } finally {
      await _storage.deleteAll();
    }
  }

  Future<bool> sendVerificationCode(String phoneNumber) async {
    try {
      await _apiClient.post(
        '/auth/verify/send',
        data: {'phoneNumber': phoneNumber},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> confirmVerificationCode(String phoneNumber, String code) async {
    try {
      await _apiClient.post(
        '/auth/verify/confirm',
        data: {
          'phoneNumber': phoneNumber,
          'code': code,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendOtpLogin(String phoneNumber) async {
    try {
      await _apiClient.post(
        '/auth/login/otp/send',
        data: {'phoneNumber': phoneNumber},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<AuthResponse> confirmOtpLogin(String phoneNumber, String code) async {
    final response = await _apiClient.post(
      '/auth/login/otp/confirm',
      data: {
        'phoneNumber': phoneNumber,
        'code': code,
      },
    );
    final authResponse = AuthResponse.fromJson(response.data);
    await _saveTokens(authResponse);
    return authResponse;
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: 'access_token');
    return token != null && token.isNotEmpty;
  }

  Future<void> _saveTokens(AuthResponse response) async {
    await _storage.write(key: 'access_token', value: response.accessToken);
    await _storage.write(key: 'refresh_token', value: response.refreshToken);
    await _storage.write(key: 'user_id', value: response.userId);
  }
}
