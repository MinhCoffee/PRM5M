import 'package:flutter/foundation.dart';
import '../../../core/models/view_state.dart';
import '../../../core/services/firebase/firebase_analytics_service.dart';
import '../../../core/services/firebase/firebase_crashlytics_service.dart';
import '../data/attendance_repository.dart';

class AttendanceBrowseData {
  final List<AttendanceSession> allSessions;
  final List<AttendanceSession> todaySessions;
  final List<AttendanceSession> upcomingSessions;

  const AttendanceBrowseData({
    required this.allSessions,
    required this.todaySessions,
    required this.upcomingSessions,
  });
}

class AttendanceBrowseViewModel extends ChangeNotifier {
  final AttendanceRepository _repository;
  final IAnalyticsService _analyticsService;
  final ICrashlyticsService _crashlyticsService;

  ViewState<AttendanceBrowseData> _state = ViewState.initial();
  ViewState<AttendanceBrowseData> get state => _state;

  AttendanceBrowseViewModel({
    required AttendanceRepository repository,
    required IAnalyticsService analyticsService,
    required ICrashlyticsService crashlyticsService,
  })  : _repository = repository,
        _analyticsService = analyticsService,
        _crashlyticsService = crashlyticsService;

  Future<void> loadSessions() async {
    _state = ViewState.loading(_state.data);
    notifyListeners();

    try {
      final sessions = await _repository.getSessions();

      if (sessions.isEmpty) {
        _state = ViewState.empty(
          'Không tìm thấy ca học nào trong hệ thống bảng tính lịch dạy.',
        );
        notifyListeners();
        return;
      }

      final today = _dateOnly(DateTime.now());
      final todaySessions = _filterSessionsForDay(sessions, today);
      final upcomingSessions = _filterUpcomingSessions(sessions, today);

      final data = AttendanceBrowseData(
        allSessions: sessions,
        todaySessions: todaySessions,
        upcomingSessions: upcomingSessions,
      );

      _state = ViewState.data(data);
      _analyticsService.logScreenView('attendance_browse');
      notifyListeners();
    } catch (e, st) {
      _crashlyticsService.recordError(e, st, reason: 'Failed to load attendance sessions');
      _state = ViewState.error('Không thể tải danh sách ca học: $e');
      notifyListeners();
    }
  }

  Future<void> seedSampleData() async {
    try {
      await _repository.seedSampleData();
      await loadSessions();
      _analyticsService.logEvent('seed_sample_data', {'success': true});
    } catch (e, st) {
      _crashlyticsService.recordError(e, st, reason: 'Seed sample data error');
      rethrow;
    }
  }

  List<AttendanceSession> _filterSessionsForDay(
    List<AttendanceSession> sessions,
    DateTime day,
  ) {
    final sorted = sessions.where((s) {
      final d = _parseDate(s.date);
      final slot = _slotNumber(s.schedule);
      return d != null && _sameDay(d, day) && slot >= 1 && slot <= 8;
    }).toList()
      ..sort((a, b) => _slotNumber(a.schedule).compareTo(_slotNumber(b.schedule)));

    final usedSlots = <int>{};
    final result = <AttendanceSession>[];
    for (final s in sorted) {
      final slot = _slotNumber(s.schedule);
      if (usedSlots.add(slot)) result.add(s);
      if (result.length == 8) break;
    }
    return result;
  }

  List<AttendanceSession> _filterUpcomingSessions(
    List<AttendanceSession> sessions,
    DateTime today,
  ) {
    final sorted = sessions.where((s) {
      final d = _parseDate(s.date);
      final slot = _slotNumber(s.schedule);
      return d != null && _dateOnly(d).isAfter(today) && slot >= 1 && slot <= 8;
    }).toList()
      ..sort((a, b) {
        final cmp = _parseDate(a.date)!.compareTo(_parseDate(b.date)!);
        return cmp != 0
            ? cmp
            : _slotNumber(a.schedule).compareTo(_slotNumber(b.schedule));
      });

    final sessionsByDate = <DateTime, int>{};
    final slotsByDate = <DateTime, Set<int>>{};
    final result = <AttendanceSession>[];
    for (final s in sorted) {
      final date = _dateOnly(_parseDate(s.date)!);
      final slot = _slotNumber(s.schedule);
      final count = sessionsByDate[date] ?? 0;
      final slots = slotsByDate.putIfAbsent(date, () => <int>{});
      if (count >= 8 || !slots.add(slot)) continue;
      sessionsByDate[date] = count + 1;
      result.add(s);
      if (result.length == 16) break;
    }
    return result;
  }

  DateTime? _parseDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
    final match = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(value);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(3)!),
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
    );
  }

  DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  bool _sameDay(DateTime a, DateTime b) => _dateOnly(a) == _dateOnly(b);

  int _slotNumber(String value) =>
      int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}
