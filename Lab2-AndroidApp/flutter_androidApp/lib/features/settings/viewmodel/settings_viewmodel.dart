import 'package:flutter/foundation.dart';
import '../../../core/models/view_state.dart';
import '../../../core/services/firebase/firebase_analytics_service.dart';
import '../../../core/services/firebase/firebase_crashlytics_service.dart';
import '../../../core/services/firebase/firebase_remote_config_service.dart';
import '../../../services/attendance_stats_service.dart';
import '../../../services/google_sheet_service.dart';

class SettingsData {
  final double warnThreshold;
  final double banThreshold;
  final bool isLiveSheet;
  final Map<String, dynamic> remoteConfigValues;

  const SettingsData({
    required this.warnThreshold,
    required this.banThreshold,
    required this.isLiveSheet,
    required this.remoteConfigValues,
  });
}

class SettingsViewModel extends ChangeNotifier {
  final AttendanceStatsService _statsService;
  final IRemoteConfigService _remoteConfigService;
  final ICrashlyticsService _crashlyticsService;
  final IAnalyticsService _analyticsService;

  ViewState<SettingsData> _state = ViewState.initial();
  ViewState<SettingsData> get state => _state;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isSeeding = false;
  bool get isSeeding => _isSeeding;

  SettingsViewModel({
    required AttendanceStatsService statsService,
    required IRemoteConfigService remoteConfigService,
    required ICrashlyticsService crashlyticsService,
    required IAnalyticsService analyticsService,
  })  : _statsService = statsService,
        _remoteConfigService = remoteConfigService,
        _crashlyticsService = crashlyticsService,
        _analyticsService = analyticsService;

  Future<void> loadSettings() async {
    _state = ViewState.loading();
    notifyListeners();

    try {
      await _statsService.loadThresholds();
      await _remoteConfigService.fetchAndActivate();

      _state = ViewState.data(
        SettingsData(
          warnThreshold: _statsService.warnThreshold,
          banThreshold: _statsService.banThreshold,
          isLiveSheet: _statsService.sheetService.isLive,
          remoteConfigValues: _remoteConfigService.getAllValues(),
        ),
      );
      _analyticsService.logScreenView('settings_screen');
      notifyListeners();
    } catch (e, st) {
      _crashlyticsService.recordError(e, st, reason: 'Failed to load settings');
      _state = ViewState.error('Không thể tải cài đặt: $e');
      notifyListeners();
    }
  }

  Future<void> saveThresholds({required double warn, required double ban}) async {
    _isSaving = true;
    notifyListeners();

    try {
      await _statsService.setThresholds(warn: warn, ban: ban);
      await _remoteConfigService.setLocalOverride('attendance_warn_threshold', warn);
      await _remoteConfigService.setLocalOverride('attendance_ban_threshold', ban);

      _analyticsService.logEvent('save_thresholds', {'warn': warn, 'ban': ban});
      await loadSettings();
    } catch (e, st) {
      _crashlyticsService.recordError(e, st, reason: 'Failed to save thresholds');
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<SeedSummary> seedSampleData() async {
    _isSeeding = true;
    notifyListeners();

    try {
      final summary = await _statsService.seedSampleData();
      _analyticsService.logEvent('seed_sample_data', {
        'subjects': summary.subjectCount,
        'classes': summary.classCount,
      });
      await loadSettings();
      return summary;
    } catch (e, st) {
      _crashlyticsService.recordError(e, st, reason: 'Failed to seed sample data');
      rethrow;
    } finally {
      _isSeeding = false;
      notifyListeners();
    }
  }

  void triggerTestCrash() {
    _crashlyticsService.testCrash();
  }

  Future<void> triggerTestNonFatalError() async {
    await _crashlyticsService.sendNonFatalError(
      'Lab 3 Non-Fatal Test Error from Settings Page',
    );
  }
}
