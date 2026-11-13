import 'package:flutter/foundation.dart';
import '../../../core/models/view_state.dart';
import '../../../core/services/firebase/firebase_analytics_service.dart';
import '../../../core/services/firebase/firebase_crashlytics_service.dart';
import '../../../services/attendance_stats_service.dart';
import '../../../services/google_sheet_service.dart';

class MyClassesData {
  final List<AttendanceClassStats> classStats;
  final String? selectedClass;
  final List<SheetScheduleRow> selectedClassSessions;

  const MyClassesData({
    required this.classStats,
    this.selectedClass,
    this.selectedClassSessions = const [],
  });
}

class MyClassesViewModel extends ChangeNotifier {
  final AttendanceStatsService _statsService;
  final IAnalyticsService _analyticsService;
  final ICrashlyticsService _crashlyticsService;

  ViewState<MyClassesData> _state = ViewState.initial();
  ViewState<MyClassesData> get state => _state;

  String? _selectedClass;

  MyClassesViewModel({
    required AttendanceStatsService statsService,
    required IAnalyticsService analyticsService,
    required ICrashlyticsService crashlyticsService,
  })  : _statsService = statsService,
        _analyticsService = analyticsService,
        _crashlyticsService = crashlyticsService;

  Future<void> loadClasses() async {
    _state = ViewState.loading();
    notifyListeners();

    try {
      await _statsService.load();
      _buildDataState();
      _analyticsService.logScreenView('my_classes_screen');
    } catch (e, st) {
      _crashlyticsService.recordError(e, st, reason: 'Failed to load classes');
      _state = ViewState.error('Không thể tải danh sách lớp học: $e');
      notifyListeners();
    }
  }

  void selectClass(String? classCode) {
    _selectedClass = classCode;
    _buildDataState();
  }

  void _buildDataState() {
    final list = _statsService.classStats();

    if (list.isEmpty) {
      _state = ViewState.empty('Hiện chưa có dữ liệu lớp học nào được phân công.');
      notifyListeners();
      return;
    }

    List<SheetScheduleRow> classSessions = const [];
    if (_selectedClass != null) {
      classSessions = _statsService.sessions
          .where((s) => s.classCode == _selectedClass)
          .toList()
        ..sort((a, b) => a.sessionNo.compareTo(b.sessionNo));
    }

    _state = ViewState.data(
      MyClassesData(
        classStats: list,
        selectedClass: _selectedClass,
        selectedClassSessions: classSessions,
      ),
    );
    notifyListeners();
  }

  SessionStatus sessionStatus(SheetScheduleRow session) =>
      _statsService.sessionStatus(session);
}
