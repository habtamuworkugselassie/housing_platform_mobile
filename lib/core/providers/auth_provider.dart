import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_model.dart';
import '../models/user_profile_model.dart';
import '../network/api_client.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/sponsorship_service.dart';
import '../services/organization_service.dart';
import '../services/exhibition_service.dart';
import '../services/live_service.dart';

// Global singletons
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(ref.read(apiClientProvider));
});

final sponsorshipServiceProvider = Provider<SponsorshipService>((ref) {
  return SponsorshipService(ref.read(apiClientProvider));
});

final organizationServiceProvider = Provider<OrganizationService>((ref) {
  return OrganizationService(ref.read(apiClientProvider));
});

final exhibitionServiceProvider = Provider<ExhibitionService>((ref) {
  return ExhibitionService(ref.read(apiClientProvider));
});

final liveServiceProvider = Provider<LiveService>((ref) {
  return LiveService(ref.read(apiClientProvider));
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(apiClientProvider), ref.read(secureStorageProvider));
});


class AuthState {
  final bool isLoading;
  final AuthResponse? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isLoading,
    AuthResponse? user,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final UserService _userService;

  AuthNotifier(this._authService, this._userService) : super(const AuthState()) {
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    state = state.copyWith(isLoading: true);
    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        try {
          final profile = await _userService.getMe();
          state = state.copyWith(
            isLoading: false,
            user: AuthResponse(
              accessToken: '',
              tokenType: 'Bearer',
              expiresIn: 0,
              refreshToken: '',
              userId: profile.id,
              email: profile.email,
              firstName: profile.firstName,
              lastName: profile.lastName,
              phoneNumber: profile.phoneNumber,
              roles: profile.roles,
              scopes: [],
            ),
          );
        } catch (_) {
          state = state.copyWith(
            isLoading: false,
            user: const AuthResponse(
              accessToken: '',
              tokenType: '',
              expiresIn: 0,
              refreshToken: '',
              userId: '',
              email: '',
              firstName: 'User',
              lastName: '',
              roles: ['BUYER'],
              scopes: [],
            ),
          );
        }
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.login(LoginRequest(
        username: username,
        password: password,
      ));
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register(RegistrationRequest request) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.register(request);
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authService.logout();
    state = const AuthState(); // Reset state completely
  }

  Future<bool> sendVerificationCode(String phone) async {
    return _authService.sendVerificationCode(phone);
  }

  Future<bool> confirmVerificationCode(String phone, String code) async {
    return _authService.confirmVerificationCode(phone, code);
  }

  Future<bool> sendOtpLogin(String phone) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final success = await _authService.sendOtpLogin(phone);
      state = state.copyWith(isLoading: false);
      if (!success) {
        state = state.copyWith(error: "Failed to send OTP. Please try again.");
      }
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> confirmOtpLogin(String phone, String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.confirmOtpLogin(phone, code);
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      final errorMsg = e.toString();
      // If error contains "User not found", we might need to handle registration on UI
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    }
  }
  
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Update displayed user from profile (e.g. after GET /me or PUT /me).
  void updateUserFromProfile(UserProfile profile) {
    if (state.user == null) return;
    state = state.copyWith(
      user: AuthResponse(
        accessToken: state.user!.accessToken,
        tokenType: state.user!.tokenType,
        expiresIn: state.user!.expiresIn,
        refreshToken: state.user!.refreshToken,
        userId: profile.id,
        email: profile.email,
        firstName: profile.firstName,
        lastName: profile.lastName,
        phoneNumber: profile.phoneNumber,
        roles: profile.roles,
        scopes: state.user!.scopes,
      ),
    );
  }
}

// Global Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider), ref.read(userServiceProvider));
});
