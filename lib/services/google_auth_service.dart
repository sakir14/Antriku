import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static const String _webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '791932772209-mne91kk19adgnahindjmqd6a1vq3mr3g.apps.googleusercontent.com',
  );

  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;

    await GoogleSignIn.instance.initialize(
      serverClientId: _webClientId.isEmpty ? null : _webClientId,
    );

    _initialized = true;
  }

  static Future<String?> signInAndGetIdToken() async {
    await _ensureInitialized();

    try {
      final account = await GoogleSignIn.instance.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }

      debugPrint('Google Sign-In gagal: ${e.code} ${e.description}');
      rethrow;
    }
  }
}
