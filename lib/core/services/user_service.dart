import 'dart:io';
import 'package:dio/dio.dart';
import '../models/user_profile_model.dart';
import '../network/api_client.dart';

/// Service for current user profile (GET /me, PUT /me).
class UserService {
  final ApiClient _apiClient;

  UserService(this._apiClient);

  /// GET /api/v1/users/me - requires authenticated user.
  Future<UserProfile> getMe() async {
    final response = await _apiClient.get('/users/me');
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT /api/v1/users/me - update current user profile.
  Future<UserProfile> updateMe(UserUpdateRequest request) async {
    final response = await _apiClient.put(
      '/users/me',
      data: request.toJson(),
    );
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /api/v1/users/me/profile-image
  Future<UserProfile> uploadProfileImage(File file) async {
    final fileName = file.path.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
    });

    final response = await _apiClient.postForm(
      '/users/me/profile-image',
      data: formData,
    );
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /users/me/password — set a first password, or change the current one.
  Future<UserProfile> changePassword({String? currentPassword, required String newPassword}) async {
    final response = await _apiClient.post('/users/me/password', data: {
      if (currentPassword != null) 'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT /users/me/payment-preferences — preferred method and mobile-money number; null clears.
  Future<UserProfile> updatePaymentPreferences({String? method, String? phone}) async {
    final response = await _apiClient.put('/users/me/payment-preferences', data: {
      'preferredPaymentMethod': method,
      'paymentPhone': phone,
    });
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  /// The saved payment method, or null when there is none or the profile cannot be read.
  Future<String?> preferredPaymentMethod() async {
    try {
      return (await getMe()).preferredPaymentMethod;
    } catch (_) {
      return null;
    }
  }

  /// DELETE /users/me — permanently delete the signed-in user's account (irreversible).
  Future<void> deleteAccount() async {
    await _apiClient.delete('/users/me');
  }
}
