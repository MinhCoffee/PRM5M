import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/view_state.dart';
import '../../../core/services/firebase/firebase_analytics_service.dart';
import '../../../core/services/firebase/firebase_crashlytics_service.dart';
import '../../../services/attendance_stats_service.dart';
import '../attendance_student.dart';
import '../data/attendance_repository.dart';

class AttendanceDetailData {
  final AttendanceSession session;
  final List<AttendanceStudent> students;
  final bool isSubmitted;
  final double warnThreshold;
  final double banThreshold;

  const AttendanceDetailData({
    required this.session,
    required this.students,
    required this.isSubmitted,
    required this.warnThreshold,
    required this.banThreshold,
  });
}

class AttendanceDetailViewModel extends ChangeNotifier {
  final String sessionId;
  final AttendanceRepository _repository;
  final AttendanceStatsService _statsService;
  final IAnalyticsService _analyticsService;
  final ICrashlyticsService _crashlyticsService;

  ViewState<AttendanceDetailData> _state = ViewState.initial();
  ViewState<AttendanceDetailData> get state => _state;

  List<AttendanceStudent> _students = [];
  List<AttendanceStudent> get students => _students;

  AttendanceSession? _session;
  AttendanceSession? get session => _session;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isSubmitted = false;
  bool get isSubmitted => _isSubmitted;

  String? _saveErrorMessage;
  String? get saveErrorMessage => _saveErrorMessage;

  bool _hasOfflineBackup = false;
  bool get hasOfflineBackup => _hasOfflineBackup;

  String _searchQuery = '';
  String _statusFilter = 'all';

  final Map<String, AttendanceState> _initialStatuses = {};

  AttendanceDetailViewModel({
    required this.sessionId,
    required AttendanceRepository repository,
    required AttendanceStatsService statsService,
    required IAnalyticsService analyticsService,
    required ICrashlyticsService crashlyticsService,
  })  : _repository = repository,
        _statsService = statsService,
        _analyticsService = analyticsService,
        _crashlyticsService = crashlyticsService;

  int get presentCount =>
      _students.where((s) => s.status == AttendanceState.present).length;

  int get absentCount => _students.length - presentCount;

  double get attendanceRate =>
      _students.isEmpty ? 0.0 : presentCount / _students.length;

  List<AttendanceStudent> get visibleStudents => _students.where((student) {
        final query = _searchQuery.trim().toLowerCase();
        final matchesQuery = query.isEmpty ||
            student.rollNo.toLowerCase().contains(query) ||
            student.fullName.toLowerCase().contains(query);
        final matchesStatus = _statusFilter == 'all' ||
            (_statusFilter == 'present' &&
                student.status == AttendanceState.present) ||
            (_statusFilter == 'absent' &&
                student.status == AttendanceState.absent);
        return matchesQuery && matchesStatus;
      }).toList();

  Future<void> loadSessionDetails() async {
    _state = ViewState.loading();
    notifyListeners();

    try {
      final sessions = await _repository.getSessions();
      final session = sessions.firstWhere((item) => item.id == sessionId);
      final studentList = await _repository.studentsForSession(sessionId);
      final submitted = await _repository.isSessionSubmitted(sessionId);
      await _statsService.loadThresholds();

      _session = session;
      _students = studentList;
      _isSubmitted = submitted;
      _saveErrorMessage = null;

      // Check if there is an offline backup from a previous network error
      await _checkOfflineDraft();

      _initialStatuses
        ..clear()
        ..addEntries(
          studentList.map(
            (s) => MapEntry(
              s.studentId.isEmpty ? s.rollNo : s.studentId,
              s.status,
            ),
          ),
        );

      final data = AttendanceDetailData(
        session: session,
        students: _students,
        isSubmitted: _isSubmitted,
        warnThreshold: _statsService.warnThreshold,
        banThreshold: _statsService.banThreshold,
      );

      _state = ViewState.data(data);
      _analyticsService.logScreenView('attendance_detail_$sessionId');
      notifyListeners();
    } catch (e, st) {
      _crashlyticsService.recordError(e, st,
          reason: 'Failed to load attendance detail for $sessionId');
      _state = ViewState.error('Không thể tải dữ liệu ca điểm danh: $e');
      notifyListeners();
    }
  }

  void markStudent(AttendanceStudent student, AttendanceState newStatus) {
    student.status = newStatus;
    notifyListeners();
  }

  void setAll(AttendanceState status) {
    for (final s in _students) {
      s.status = status;
    }
    notifyListeners();
  }

  void resetStatuses() {
    for (final s in _students) {
      final key = s.studentId.isEmpty ? s.rollNo : s.studentId;
      s.status = _initialStatuses[key] ?? AttendanceState.present;
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  /// Flow 2: Save Draft / Submit with Error Recovery
  Future<bool> saveAttendance({required bool submitted}) async {
    if (_session == null || _isSaving) return false;
    _isSaving = true;
    _saveErrorMessage = null;
    notifyListeners();

    try {
      await _repository.saveAttendance(
        sessionId,
        _students,
        submitted: submitted,
      );

      await _statsService.load(force: true);

      _isSubmitted = submitted;
      _isSaving = false;
      _saveErrorMessage = null;
      _hasOfflineBackup = false;

      // Clear offline draft on success
      await _clearOfflineDraft();

      _initialStatuses
        ..clear()
        ..addEntries(
          _students.map(
            (s) => MapEntry(
              s.studentId.isEmpty ? s.rollNo : s.studentId,
              s.status,
            ),
          ),
        );

      _analyticsService.logAttendanceMarked(
        sessionId: sessionId,
        presentCount: presentCount,
        absentCount: absentCount,
      );

      if (submitted) {
        _analyticsService.logAttendanceSubmitted(
          sessionId: sessionId,
          classCode: _session!.className,
        );
      }

      notifyListeners();
      return true;
    } catch (e, st) {
      _crashlyticsService.recordError(e, st,
          reason: 'Error saving attendance for $sessionId');

      // Error Recovery: Giữ nguyên 100% thay đổi trên UI & Backup vào Local Storage
      await _saveOfflineDraft();

      _isSaving = false;
      _hasOfflineBackup = true;
      _saveErrorMessage =
          'Lỗi kết nối khi lưu: $e. Dữ liệu điểm danh đã được bảo vệ trong bộ nhớ máy.';
      notifyListeners();
      return false;
    }
  }

  Future<void> retrySaving({required bool submitted}) async {
    await saveAttendance(submitted: submitted);
  }

  // --- Offline Storage Backup implementation ---
  String get _draftKey => 'attendance_offline_draft_$sessionId';

  Future<void> _saveOfflineDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftList = _students
          .map((s) => {
                'id': s.studentId,
                'roll': s.rollNo,
                'status': s.status == AttendanceState.present ? 'P' : 'A',
                'note': s.note,
              })
          .toList();
      await prefs.setString(_draftKey, jsonEncode(draftList));
    } catch (_) {}
  }

  Future<void> _checkOfflineDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString(_draftKey);
      if (savedStr != null && savedStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(savedStr);
        final map = {
          for (final item in list)
            (item['id']?.toString().isNotEmpty == true
                ? item['id']
                : item['roll']): item
        };

        for (final s in _students) {
          final key = s.studentId.isNotEmpty ? s.studentId : s.rollNo;
          if (map.containsKey(key)) {
            final data = map[key]!;
            s.status = data['status'] == 'A'
                ? AttendanceState.absent
                : AttendanceState.present;
            s.note = data['note'] ?? '';
          }
        }
        _hasOfflineBackup = true;
      }
    } catch (_) {}
  }

  Future<void> _clearOfflineDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
    } catch (_) {}
  }
}
