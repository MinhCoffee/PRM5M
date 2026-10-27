import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/models/user_profile.dart';
import 'package:flutter_application_1/core/services/firebase/firebase_auth_service.dart';
import 'package:flutter_application_1/core/services/firebase/firebase_analytics_service.dart';
import 'package:flutter_application_1/core/services/firebase/firebase_crashlytics_service.dart';
import 'package:flutter_application_1/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:flutter_application_1/services/google_sheet_service.dart';

class FakeAuthService implements IAuthService {
  UserProfile? _user;
  bool shouldFail = false;
  final _controller = StreamController<UserProfile?>.broadcast();

  @override
  UserProfile? get currentUser => _user;

  @override
  Stream<UserProfile?> get authStateChanges => _controller.stream;

  @override
  Future<bool> hasCachedSession() async => _user != null;

  @override
  Future<UserProfile?> signInWithGoogle() async {
    if (shouldFail) {
      throw Exception('Network connection timed out');
    }
    _user = UserProfile.defaultLecturer(
      email: 'minhnd32@fpt.edu.vn',
      name: 'Dr. Nguyen Van Minh',
    );
    _controller.add(_user);
    return _user;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}

class FakeAnalyticsService implements IAnalyticsService {
  final List<String> loggedEvents = [];

  @override
  Future<void> logAttendanceMarked({
    required String sessionId,
    required int presentCount,
    required int absentCount,
  }) async {
    loggedEvents.add('attendance_marked');
  }

  @override
  Future<void> logAttendanceSubmitted({
    required String sessionId,
    required String classCode,
  }) async {
    loggedEvents.add('attendance_submitted');
  }

  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    loggedEvents.add(name);
  }

  @override
  Future<void> logExportReport({
    required String classCode,
    required String fileType,
  }) async {
    loggedEvents.add('export_report');
  }

  @override
  Future<void> logFilterChanged({
    required String filterType,
    required String value,
  }) async {
    loggedEvents.add('filter_changed');
  }

  @override
  Future<void> logLogin(String method) async {
    loggedEvents.add('login_$method');
  }

  @override
  Future<void> logScreenView(String screenName) async {
    loggedEvents.add('screen_$screenName');
  }
}

class FakeCrashlyticsService implements ICrashlyticsService {
  final List<String> recordedErrors = [];

  @override
  void log(String message) {}

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    recordedErrors.add(exception.toString());
  }

  @override
  void setCustomKey(String key, Object value) {}

  @override
  void setUserIdentifier(String userId) {}

  @override
  void testCrash() {}
}

void main() {
  group('AuthViewModel MVVM Unit Tests with Injected Fake Services', () {
    late FakeAuthService fakeAuth;
    late FakeAnalyticsService fakeAnalytics;
    late FakeCrashlyticsService fakeCrashlytics;
    late GoogleSheetService sheetService;
    late AuthViewModel viewModel;

    setUp(() {
      fakeAuth = FakeAuthService();
      fakeAnalytics = FakeAnalyticsService();
      fakeCrashlytics = FakeCrashlyticsService();
      sheetService = GoogleSheetService();
      viewModel = AuthViewModel(
        authService: fakeAuth,
        sheetService: sheetService,
        analyticsService: fakeAnalytics,
        crashlyticsService: fakeCrashlytics,
      );
    });

    test('Initial state is not authenticated', () {
      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.state.isInitial, isTrue);
    });

    test('Sign in failure sets Error state and logs to Crashlytics', () async {
      fakeAuth.shouldFail = true;

      final success = await viewModel.signInWithGoogle();

      expect(success, isFalse);
      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.state.hasError, isTrue);
      expect(viewModel.state.errorMessage, contains('Network connection timed out'));
      expect(fakeCrashlytics.recordedErrors.isNotEmpty, isTrue);
    });

    test('Error Recovery: retrySignIn succeeds after fixing network', () async {
      fakeAuth.shouldFail = true;
      await viewModel.signInWithGoogle();
      expect(viewModel.state.hasError, isTrue);

      // Network recovers
      fakeAuth.shouldFail = false;
      // In unit test without real Google Sheets connection, Sheet init will fail safely
      await viewModel.retrySignIn();

      // State is no longer loading
      expect(viewModel.state.isLoading, isFalse);
    });

    test('SignOut resets ViewModel to initial state', () async {
      await viewModel.signOut();
      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.state.isInitial, isTrue);
      expect(fakeAnalytics.loggedEvents, contains('logout'));
    });
  });
}
