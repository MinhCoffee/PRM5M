import 'package:flutter/foundation.dart';
import '../../../core/models/view_state.dart';
import '../../../core/services/firebase/firebase_analytics_service.dart';
import '../../../core/services/firebase/firebase_crashlytics_service.dart';
import '../../../services/attendance_stats_service.dart';
import '../../../services/google_sheet_service.dart';

class TimetableData {
  final DateTime weekStart;
  final List<SheetScheduleRow> sessions;

  const TimetableData({
    required this.weekStart,
    required this.sessions,
  });
}

class TimetableViewModel extends ChangeNotifier {
  final AttendanceStatsService _statsService;
  final IAnalyticsService _analyticsService;
  final ICrashlyticsService _crashlyticsService;

  ViewState<TimetableData> _state = ViewState.initial();
  ViewState<TimetableData> get state => _state;

  late DateTime _weekStart;
  DateTime get weekStart => _weekStart;

  TimetableViewModel({
    required AttendanceStatsService statsService,
    required IAnalyticsService analyticsService,
    required ICrashlyticsService crashlyticsService,
  })  : _statsService = statsService,
        _analyticsService = analyticsService,
        _crashlyticsService = crashlyticsService {
    final today = DateTime.now();
    _weekStart = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
  }

  Future<void> loadTimetable() async {
    _state = ViewState.loading();
    notifyListeners();

    try {
      await _statsService.load();
      _buildDataState();
      _analyticsService.logScreenView('timetable_screen');
    } catch (e, st) {
      _crashlyticsService.recordError(e, st, reason: 'Failed to load timetable');
      _state = ViewState.error('Không thể tải lịch học tuần: $e');
      notifyListeners();
    }
  }

  void moveWeek(int offset) {
    _weekStart = _weekStart.add(Duration(days: offset * 7));
    _buildDataState();
  }

  void resetToCurrentWeek() {
    final today = DateTime.now();
    _weekStart = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
    _buildDataState();
  }

  void _buildDataState() {
    _state = ViewState.data(
      TimetableData(
        weekStart: _weekStart,
        sessions: _statsService.sessions,
      ),
    );
    notifyListeners();
  }

  SessionStatus sessionStatus(SheetScheduleRow session) =>
      _statsService.sessionStatus(session);
}
