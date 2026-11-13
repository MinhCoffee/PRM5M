import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// `GoogleSignIn.instance.initialize()` must run exactly once per process.
/// Both Firebase Auth and the Google Sheets client need it, so they share
/// this single entry point.
class GoogleSignInBootstrap {
  GoogleSignInBootstrap._();

  static Future<void>? _initialization;

  static Future<void> ensureInitialized() {
    return _initialization ??= _initialize().catchError((Object e) {
      // Allow a retry after a failed initialization.
      _initialization = null;
      throw e;
    });
  }

  static Future<void> _initialize() async {
    String? webClientId;
    try {
      webClientId = dotenv.maybeGet('GOOGLE_WEB_CLIENT_ID')?.trim();
    } catch (_) {
      webClientId = null;
    }
    await GoogleSignIn.instance.initialize(
      serverClientId:
          (webClientId == null || webClientId.isEmpty) ? null : webClientId,
    );
  }
}
