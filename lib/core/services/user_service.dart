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

  /// DELETE /users/me — permanently delete the signed-in user's account (irreversible).
  Future<void> deleteAccount() async {
    await _apiClient.delete('/users/me');
  }
}
