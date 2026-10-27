import 'package:flutter/foundation.dart';
import '../../../core/models/view_state.dart';
import '../../../core/services/firebase/firebase_analytics_service.dart';
import '../../../core/services/firebase/firebase_crashlytics_service.dart';
import '../../../core/services/firebase/firebase_remote_config_service.dart';
import '../../../services/attendance_stats_service.dart';
import '../../../services/google_sheet_service.dart';

class HomeDashboardData {
  final List<SheetScheduleRow> todaySessions;
  final double overallRate;
  final int bannedStudentsCount;
  final int draftSessionsCount;
  final String announcement;

  const HomeDashboardData({
    required this.todaySessions,
    required this.overallRate,
    required this.bannedStudentsCount,
    required this.draftSessionsCount,
    required this.announcement,
  });
}

class HomeViewModel extends ChangeNotifier {
  final AttendanceStatsService _statsService;
  final IRemoteConfigService _remoteConfigService;
  final IAnalyticsService _analyticsService;
  final ICrashlyticsService _crashlyticsService;

  ViewState<HomeDashboardData> _state = ViewState.initial();
  ViewState<HomeDashboardData> get state => _state;

  HomeViewModel({
    required AttendanceStatsService statsService,
    required IRemoteConfigService remoteConfigService,
    required IAnalyticsService analyticsService,
    required ICrashlyticsService crashlyticsService,
  })  : _statsService = statsService,
        _remoteConfigService = remoteConfigService,
        _analyticsService = analyticsService,
        _crashlyticsService = crashlyticsService;

  Future<void> loadDashboard({bool force = false}) async {
    _state = ViewState.loading(_state.data);
    notifyListeners();

    try {
      await _remoteConfigService.fetchAndActivate();
      await _statsService.load(force: force);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final todaySessions = _statsService.sessions.where((session) {
        final d = DateTime.tryParse(session.sessionDate);
        return d != null && DateTime(d.year, d.month, d.day) == today;
      }).toList()
        ..sort((a, b) => _slotNumber(a.slot).compareTo(_slotNumber(b.slot)));

      final heldRows = _statsService.attendance.where((row) {
        return _statsService.sessions.any((session) {
          if (session.sessionId != row.sessionId) return false;
          final d = DateTime.tryParse(session.sessionDate);
          return d != null && !DateTime(d.year, d.month, d.day).isAfter(today);
        });
      }).toList();

      final overallRate = heldRows.isEmpty
          ? 0.0
          : heldRows.where((row) => row.status == 'present').length / heldRows.length;

      final bannedStudentsCount = _statsService.students
          .map(_statsService.studentStats)
          .where((row) => row.status == StudentRiskStatus.banned)
          .length;

      final draftSessionsCount = _statsService.attendance
          .where((row) => row.syncStatus == 'draft')
          .map((row) => row.sessionId)
          .toSet()
          .length;

      final announcement = _remoteConfigService.getString(
        'portal_announcement',
        'Kỳ Fall 2026: Vui lòng nộp điểm danh trước 23h59 hàng ngày để đồng bộ dữ liệu FAP.',
      );

      final dashboardData = HomeDashboardData(
        todaySessions: todaySessions,
        overallRate: overallRate,
        bannedStudentsCount: bannedStudentsCount,
        draftSessionsCount: draftSessionsCount,
        announcement: announcement,
      );

      _state = ViewState.data(dashboardData);
      _analyticsService.logScreenView('home_dashboard');
      notifyListeners();
    } catch (e, st) {
      _crashlyticsService.recordError(e, st, reason: 'Failed to load home dashboard');
      _state = ViewState.error('Không thể tải dữ liệu trang chủ: $e');
      notifyListeners();
    }
  }

  int _slotNumber(String slot) =>
      int.tryParse(slot.replaceAll(RegExp(r'[^0-9]'), '')) ?? 99;

  SessionStatus sessionStatus(SheetScheduleRow session) =>
      _statsService.sessionStatus(session);
}
