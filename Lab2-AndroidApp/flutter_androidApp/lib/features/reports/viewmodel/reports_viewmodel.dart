import 'package:flutter/foundation.dart';
import '../../../core/models/view_state.dart';
import '../../../core/services/firebase/firebase_analytics_service.dart';
import '../../../core/services/firebase/firebase_crashlytics_service.dart';
import '../../../core/services/firebase/firebase_storage_service.dart';
import '../../../services/attendance_stats_service.dart';
import '../../../services/file_service.dart';

class ReportsData {
  final List<String> semesters;
  final List<String> subjects;
  final List<String> classes;
  final String selectedSemester;
  final String selectedSubject;
  final String selectedClass;
  final List<AttendanceStudentStats> rows;

  const ReportsData({
    required this.semesters,
    required this.subjects,
    required this.classes,
    required this.selectedSemester,
    required this.selectedSubject,
    required this.selectedClass,
    required this.rows,
  });
}

class ReportsViewModel extends ChangeNotifier {
  final AttendanceStatsService _statsService;
  final FileService _fileService;
  final IStorageService _storageService;
  final IAnalyticsService _analyticsService;
  final ICrashlyticsService _crashlyticsService;

  ViewState<ReportsData> _state = ViewState.initial();
  ViewState<ReportsData> get state => _state;

  String _semester = 'all';
  String _subject = 'all';
  String _classCode = 'all';

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  String? _exportErrorMessage;
  String? get exportErrorMessage => _exportErrorMessage;

  ReportsViewModel({
    required AttendanceStatsService statsService,
    required FileService fileService,
    required IStorageService storageService,
    required IAnalyticsService analyticsService,
    required ICrashlyticsService crashlyticsService,
  })  : _statsService = statsService,
        _fileService = fileService,
        _storageService = storageService,
        _analyticsService = analyticsService,
        _crashlyticsService = crashlyticsService;

  Future<void> loadReports() async {
    _state = ViewState.loading();
    notifyListeners();

    try {
      await _statsService.load();
      _buildDataState();
      _analyticsService.logScreenView('reports_screen');
    } catch (e, st) {
      _crashlyticsService.recordError(e, st, reason: 'Failed to load reports');
      _state = ViewState.error('Không thể tải dữ liệu báo cáo: $e');
      notifyListeners();
    }
  }

  void setSemester(String value) {
    _semester = value;
    _analyticsService.logFilterChanged(filterType: 'semester', value: value);
    _buildDataState();
  }

  void setSubject(String value) {
    _subject = value;
    _analyticsService.logFilterChanged(filterType: 'subject', value: value);
    _buildDataState();
  }

  void setClassCode(String value) {
    _classCode = value;
    _analyticsService.logFilterChanged(filterType: 'class', value: value);
    _buildDataState();
  }

  void resetFilters() {
    _semester = 'all';
    _subject = 'all';
    _classCode = 'all';
    _buildDataState();
  }

  void _buildDataState() {
    final semesters = [
      'all',
      ..._statsService.sessions
          .map((s) => DateTime.tryParse(s.sessionDate)?.year.toString())
          .whereType<String>()
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a))
    ];

    final subjects = [
      'all',
      ..._statsService.sessions
          .map((s) => s.subjectCode)
          .where((v) => v.isNotEmpty)
          .toSet()
          .toList()
        ..sort()
    ];

    final classes = [
      'all',
      ..._statsService.students
          .map((s) => s.classId)
          .where((v) => v.isNotEmpty)
          .toSet()
          .toList()
        ..sort()
    ];

    final allowedClasses = _classCode == 'all' ? null : {_classCode};
    final allowedSessions = _statsService.sessions.where((session) {
      final yearMatches =
          _semester == 'all' || session.sessionDate.startsWith('$_semester-');
      final subjectMatches = _subject == 'all' || session.subjectCode == _subject;
      final classMatches = _classCode == 'all' || session.classCode == _classCode;
      return yearMatches && subjectMatches && classMatches;
    }).map((session) => session.classCode).toSet();

    final rows = _statsService.students
        .where((student) =>
            (allowedClasses == null || allowedClasses.contains(student.classId)) &&
            allowedSessions.contains(student.classId))
        .map(_statsService.studentStats)
        .toList()
      ..sort((a, b) => b.absenceRate.compareTo(a.absenceRate));

    final data = ReportsData(
      semesters: semesters,
      subjects: subjects,
      classes: classes,
      selectedSemester: _semester,
      selectedSubject: _subject,
      selectedClass: _classCode,
      rows: rows,
    );

    if (rows.isEmpty) {
      _state = ViewState.empty(
        'Chưa có dữ liệu điểm danh phù hợp với bộ lọc hiện tại (Học kỳ: $_semester, Môn: $_subject, Lớp: $_classCode).',
      );
    } else {
      _state = ViewState.data(data);
    }
    notifyListeners();
  }

  /// Flow 3: Export CSV with Firebase Cloud Storage upload & error recovery
  Future<String?> exportCsv() async {
    final currentRows = _state.data?.rows ?? [];

    if (currentRows.isEmpty) {
      _exportErrorMessage =
          'Chưa có buổi học nào được điểm danh trong bộ lọc này để xuất báo cáo.';
      notifyListeners();
      return null;
    }

    _isExporting = true;
    _exportErrorMessage = null;
    notifyListeners();

    try {
      final lines = <String>[
        'student_code,full_name,class_code,sessions_held,absent_count,absence_rate,status'
      ];
      for (final row in currentRows) {
        lines.add([
          row.student.studentCode,
          row.student.fullName,
          row.student.classId,
          row.sessionsHeld,
          row.absentCount,
          '${(row.absenceRate * 100).toStringAsFixed(1)}%',
          row.status.value,
        ].map(_csvEscape).join(','));
      }

      final csvContent = '${lines.join('\n')}\n';
      final fileName =
          'FAP_Attendance_Report_${_classCode == 'all' ? 'All' : _classCode}_${DateTime.now().millisecondsSinceEpoch}.csv';

      // 1. Save locally via Android File Picker
      final savedPath = await _fileService.saveTextFile(
        dialogTitle: 'Lưu báo cáo điểm danh CSV',
        fileName: fileName,
        content: csvContent,
        extensions: ['csv'],
      );

      if (savedPath == null) {
        _isExporting = false;
        notifyListeners();
        return null;
      }

      // 2. Upload backup to Firebase Cloud Storage (Service 2)
      try {
        await _storageService.uploadReport(
          fileName: fileName,
          content: csvContent,
          classCode: _classCode,
        );
      } catch (uploadError) {
        debugPrint('Cloud storage backup notification: $uploadError');
      }

      // 3. Log Analytics event (Service 4)
      _analyticsService.logExportReport(
        classCode: _classCode,
        fileType: 'csv',
      );

      _isExporting = false;
      notifyListeners();
      return savedPath;
    } catch (e, st) {
      _crashlyticsService.recordError(e, st, reason: 'Export CSV failed');
      _isExporting = false;
      _exportErrorMessage =
          'Không thể xuất file: $e. Vui lòng kiểm tra quyền bộ nhớ và thử lại.';
      notifyListeners();
      return null;
    }
  }

  String _csvEscape(Object value) =>
      '"${value.toString().replaceAll('"', '""')}"';
}
