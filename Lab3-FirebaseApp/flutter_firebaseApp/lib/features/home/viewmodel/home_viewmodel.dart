import 'dart:async';

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

  /// Remote Config `show_banner`: whether the announcement banner is shown.
  final bool showBanner;

  /// Remote Config `max_items`: cap on how many of today's sessions are listed.
  final int maxItems;

  /// How many of today's sessions exist before the `max_items` cap is applied.
  final int totalTodaySessions;

  const HomeDashboardData({
    required this.todaySessions,
    required this.overallRate,
    required this.bannedStudentsCount,
    required this.draftSessionsCount,
    required this.announcement,
    this.showBanner = true,
    this.maxItems = 10,
    int? totalTodaySessions,
  }) : totalTodaySessions = totalTodaySessions ?? todaySessions.length;

  int get hiddenSessionCount => totalTodaySessions - todaySessions.length;
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
      // Remote Config (up to a 10s timeout when offline) must not delay the
      // dashboard: fetch in parallel, show cached/default values now and
      // re-apply once fresh values are activated.
      final remoteFetch = _remoteConfigService.fetchAndActivate();
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

      HomeDashboardData build() {
        final announcement = _remoteConfigService.getString(
          'portal_announcement',
          'Kỳ Fall 2026: Vui lòng nộp điểm danh trước 23h59 hàng ngày để đồng bộ dữ liệu FAP.',
        );
        final showBanner = _remoteConfigService.getBool('show_banner', true);
        final maxItems =
            _remoteConfigService.getInt('max_items', 10).clamp(1, 100);
        return HomeDashboardData(
          todaySessions: todaySessions.take(maxItems).toList(),
          totalTodaySessions: todaySessions.length,
          showBanner: showBanner,
          maxItems: maxItems,
          overallRate: overallRate,
          bannedStudentsCount: bannedStudentsCount,
          draftSessionsCount: draftSessionsCount,
          announcement: announcement,
        );
      }

      final dashboardData = build();
      _state = ViewState.data(dashboardData);
      _analyticsService.logScreenView('home_dashboard');
      notifyListeners();

      unawaited(remoteFetch.then((_) {
        // Skip if the user left the screen or a newer load replaced this one.
        if (_disposed || !identical(_state.data, dashboardData)) return;
        _state = ViewState.data(build());
        notifyListeners();
      }));
    } catch (e, st) {
      _crashlyticsService.recordError(e, st, reason: 'Failed to load home dashboard');
      _state = ViewState.error('Không thể tải dữ liệu trang chủ: $e');
      notifyListeners();
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  int _slotNumber(String slot) =>
      int.tryParse(slot.replaceAll(RegExp(r'[^0-9]'), '')) ?? 99;

  SessionStatus sessionStatus(SheetScheduleRow session) =>
      _statsService.sessionStatus(session);
}
