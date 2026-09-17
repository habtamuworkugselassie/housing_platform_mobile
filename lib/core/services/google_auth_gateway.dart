import 'package:google_sign_in/google_sign_in.dart';

import '../config/google_config.dart';

/// Thin wrapper over `google_sign_in` so screens and tests never touch the plugin directly.
///
/// The ID token is requested with the web client id as `serverClientId`, which makes its audience
/// the same value the backend verifies. Returns null when the user dismissed the account picker.
class GoogleAuthGateway {
  GoogleSignIn? _client;

  bool get isAvailable => GoogleConfig.isConfigured;

  GoogleSignIn _signIn() => _client ??= GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: GoogleConfig.webClientId,
      );

  Future<String?> obtainIdToken() async {
    if (!isAvailable) {
      throw StateError('Google sign-in is not configured (GOOGLE_WEB_CLIENT_ID)');
    }
    final account = await _signIn().signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    return auth.idToken;
  }

  Future<void> signOut() async {
    try {
      await _client?.signOut();
    } catch (_) {
      // Nothing to do: the platform session is already gone.
    }
  }
}
