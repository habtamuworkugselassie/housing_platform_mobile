import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile_model.dart';
import 'auth_provider.dart';

/// Fetches current user profile from GET /users/me when authenticated.
/// Invalidate after login or after updating profile to refetch.
final profileProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
  final isAuth = ref.watch(authProvider).isAuthenticated;
  if (!isAuth) return null;
  final profile = await ref.read(userServiceProvider).getMe();
  return profile;
});
