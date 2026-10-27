import 'package:flutter/foundation.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/view_state.dart';
import '../../../core/services/firebase/firebase_analytics_service.dart';
import '../../../core/services/firebase/firebase_auth_service.dart';
import '../../../core/services/firebase/firebase_crashlytics_service.dart';
import '../../../core/services/firebase/firebase_messaging_service.dart';
import '../../../core/services/firebase/firebase_remote_config_service.dart';
import '../../../core/services/firebase/firebase_storage_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final IAuthService _authService;
  final IMessagingService _messagingService;
  final ICrashlyticsService _crashlyticsService;
  final IRemoteConfigService _remoteConfigService;
  final IStorageService _storageService;
  final IAnalyticsService _analyticsService;

  ViewState<UserProfile> _state = ViewState.initial();
  ViewState<UserProfile> get state => _state;

  String _fcmToken = 'Loading FCM Token...';
  String get fcmToken => _fcmToken;

  int _uploadedReportsCount = 0;
  int get uploadedReportsCount => _uploadedReportsCount;

  ProfileViewModel({
    required IAuthService authService,
    required IMessagingService messagingService,
    required ICrashlyticsService crashlyticsService,
    required IRemoteConfigService remoteConfigService,
    required IStorageService storageService,
    required IAnalyticsService analyticsService,
  })  : _authService = authService,
        _messagingService = messagingService,
        _crashlyticsService = crashlyticsService,
        _remoteConfigService = remoteConfigService,
        _storageService = storageService,
        _analyticsService = analyticsService;

  Future<void> loadProfile() async {
    _state = ViewState.loading();
    notifyListeners();

    try {
      final user = _authService.currentUser ?? UserProfile.defaultLecturer();
      _fcmToken = await _messagingService.getFcmToken();
      final reports = await _storageService.getUploadedReports();
      _uploadedReportsCount = reports.length;

      _state = ViewState.data(user);
      _analyticsService.logScreenView('user_profile_screen');
      notifyListeners();
    } catch (e, st) {
      _crashlyticsService.recordError(e, st, reason: 'Failed to load profile');
      _state = ViewState.error('Không thể tải thông tin hồ sơ: $e');
      notifyListeners();
    }
  }

  void triggerTestCrash() {
    _crashlyticsService.testCrash();
  }

  Future<void> triggerTestPushNotification() async {
    await _messagingService.sendLocalNotification(
      title: '🚨 Cảnh báo vắng học kỳ (FCM)',
      body: 'Lớp SE1801 có 2 sinh viên vượt ngưỡng vắng 20%. Nhấn để xem chi tiết.',
      data: {'type': 'risk_alert', 'classCode': 'SE1801'},
    );
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
