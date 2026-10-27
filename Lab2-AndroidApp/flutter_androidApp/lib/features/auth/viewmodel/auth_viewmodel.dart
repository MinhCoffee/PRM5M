import 'package:flutter/foundation.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/view_state.dart';
import '../../../core/services/firebase/firebase_analytics_service.dart';
import '../../../core/services/firebase/firebase_auth_service.dart';
import '../../../core/services/firebase/firebase_crashlytics_service.dart';
import '../../../services/google_sheet_service.dart';

class AuthViewModel extends ChangeNotifier {
  final IAuthService _authService;
  final GoogleSheetService _sheetService;
  final IAnalyticsService _analyticsService;
  final ICrashlyticsService _crashlyticsService;

  ViewState<UserProfile> _state = ViewState.initial();
  ViewState<UserProfile> get state => _state;

  UserProfile? get currentUser => _authService.currentUser;
  bool get isAuthenticated => _state.hasData && _state.data != null;

  AuthViewModel({
    required IAuthService authService,
    required GoogleSheetService sheetService,
    required IAnalyticsService analyticsService,
    required ICrashlyticsService crashlyticsService,
  })  : _authService = authService,
        _sheetService = sheetService,
        _analyticsService = analyticsService,
        _crashlyticsService = crashlyticsService;

  Future<void> checkCachedSession() async {
    _state = ViewState.loading();
    notifyListeners();

    try {
      final hasSheetCreds = await _sheetService.hasCachedCredentials();
      final hasAuthCreds = await _authService.hasCachedSession();

      if (hasSheetCreds || hasAuthCreds) {
        final connected = await _sheetService.init();
        if (connected) {
          final user = _authService.currentUser ?? UserProfile.defaultLecturer();
          _state = ViewState.data(user);
          _analyticsService.logLogin('cached_credentials');
          notifyListeners();
          return;
        }
      }

      _state = ViewState.initial();
      notifyListeners();
    } catch (e, st) {
      _crashlyticsService.recordError(e, st, reason: 'Check cached session error');
      _state = ViewState.initial();
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _state = ViewState.loading();
    notifyListeners();

    try {
      // 1. Google OAuth & Firebase Authentication
      final user = await _authService.signInWithGoogle();

      // 2. Initialize Google Sheet connection
      final connected = await _sheetService.init();

      if (!connected) {
        final err = _sheetService.lastError ?? 'Không thể kết nối đến Google Sheets.';
        _state = ViewState.error(err);
        _analyticsService.logEvent('login_failed', {'reason': err});
        notifyListeners();
        return false;
      }

      final verifiedUser = user ?? UserProfile.defaultLecturer();
      _state = ViewState.data(verifiedUser);
      _analyticsService.logLogin('google_oauth_firebase');
      _crashlyticsService.setUserIdentifier(verifiedUser.email);
      notifyListeners();
      return true;
    } catch (e, st) {
      _crashlyticsService.recordError(e, st, reason: 'Google sign-in flow failed');
      final err = 'Xác thực Google thất bại: $e';
      _state = ViewState.error(err);
      _analyticsService.logEvent('login_failed', {'error': e.toString()});
      notifyListeners();
      return false;
    }
  }

  /// Error Recovery: Bấm nút thử lại Retry Authentication ngay lập tức
  Future<bool> retrySignIn() async {
    return signInWithGoogle();
  }

  Future<void> signOut() async {
    _state = ViewState.loading();
    notifyListeners();

    try {
      await _sheetService.signOut();
      await _authService.signOut();
      _state = ViewState.initial();
      _analyticsService.logEvent('logout', {});
    } catch (e, st) {
      _crashlyticsService.recordError(e, st, reason: 'Sign out failed');
      _state = ViewState.initial();
    } finally {
      notifyListeners();
    }
  }
}
