import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../../core/models/view_state.dart';
import '../../../core/services/firebase/firebase_analytics_service.dart';
import '../../../core/services/firebase/firebase_crashlytics_service.dart';
import '../../../core/services/firebase/firebase_storage_service.dart';
import '../../../models/student.dart';
import '../../../services/attendance_stats_service.dart';
import '../../../services/file_service.dart';
import '../../../services/google_sheet_service.dart';

class ExportData {
  final List<SheetScheduleRow> sessions;
  final List<String> classes;
  final String selectedClass;
  final DateTime? fromDate;
  final DateTime? toDate;

  const ExportData({
    required this.sessions,
    required this.classes,
    required this.selectedClass,
    this.fromDate,
    this.toDate,
  });
}

class ExportViewModel extends ChangeNotifier {
  final AttendanceStatsService _statsService;
  final FileService _fileService;
  final IStorageService _storageService;
  final IAnalyticsService _analyticsService;
  final ICrashlyticsService _crashlyticsService;

  ViewState<ExportData> _state = ViewState.initial();
  ViewState<ExportData> get state => _state;

  String _classCode = 'all';
  DateTime? _from;
  DateTime? _to;

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  bool _isImporting = false;
  bool get isImporting => _isImporting;

  String? _operationMessage;
  String? get operationMessage => _operationMessage;

  ExportViewModel({
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

  Future<void> loadExportData({bool force = false}) async {
    _state = ViewState.loading();
    notifyListeners();

    try {
      await _statsService.load(force: force);
      _buildDataState();
      _analyticsService.logScreenView('export_fap_sync');
    } catch (e, st) {
      _crashlyticsService.recordError(e, st, reason: 'Failed to load export data');
      _state = ViewState.error('Không thể tải dữ liệu ca học để xuất: $e');
      notifyListeners();
    }
  }

  void setClassCode(String value) {
    _classCode = value;
    _buildDataState();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    _from = from;
    _to = to;
    _buildDataState();
  }

  void resetFilters() {
    _classCode = 'all';
    _from = null;
    _to = null;
    _buildDataState();
  }

  void _buildDataState() {
    final classes = [
      'all',
      ...{
        ..._statsService.students.map((s) => s.classId),
        ..._statsService.sessions.map((s) => s.classCode),
      }.where((v) => v.isNotEmpty).toList()
        ..sort()
    ];

    final filteredSessions = _statsService.sessions.where((session) {
      final date = DateTime.tryParse(session.sessionDate);
      final classMatches =
          _classCode == 'all' || session.classCode == _classCode;
      final fromMatches =
          _from == null || (date != null && !date.isBefore(_from!));
      final toMatches = _to == null || (date != null && !date.isAfter(_to!));
      return classMatches && fromMatches && toMatches;
    }).toList()
      ..sort((a, b) => a.sessionDate.compareTo(b.sessionDate));

    final data = ExportData(
      sessions: filteredSessions,
      classes: classes,
      selectedClass: _classCode,
      fromDate: _from,
      toDate: _to,
    );

    if (filteredSessions.isEmpty) {
      _state = ViewState.empty(
        'Không tìm thấy ca học nào phù hợp với bộ lọc ngày và lớp đã chọn.',
      );
    } else {
      _state = ViewState.data(data);
    }
    notifyListeners();
  }

  Future<String?> exportFapCsv() async {
    final currentSessions = _state.data?.sessions ?? [];
    if (currentSessions.isEmpty) return null;

    _isExporting = true;
    _operationMessage = null;
    notifyListeners();

    try {
      final sessionIds = currentSessions.map((s) => s.sessionId).toSet();
      final relevantAttendance = _statsService.attendance
          .where((row) => sessionIds.contains(row.sessionId))
          .toList();

      if (relevantAttendance.isEmpty) {
        _isExporting = false;
        _operationMessage =
            'Chưa có dữ liệu điểm danh nào được ghi nhận cho các ca học đã chọn.';
        notifyListeners();
        return null;
      }

      final rows = <String>[
        'class_code,subject_code,session_no,session_date,slot,roll_number,full_name,status,note',
      ];

      for (final att in relevantAttendance) {
        final session = currentSessions
            .firstWhere((item) => item.sessionId == att.sessionId);
        final student = _statsService.students.firstWhere(
          (item) =>
              item.studentId == att.studentId ||
              item.studentCode == att.studentId,
          orElse: () => Student(
            studentId: att.studentId,
            studentName: 'Sinh viên chưa cập nhật tên',
            classId: session.classCode,
            email: '',
          ),
        );
        final rollNo = student.studentCode.isNotEmpty
            ? student.studentCode
            : student.studentId;
        rows.add([
          session.classCode,
          session.subjectCode,
          session.sessionNo.toString(),
          session.sessionDate,
          session.slot,
          rollNo,
          student.fullName,
          att.status,
          att.note,
        ].map(_csvEscape).join(','));
      }

      final csvContent = '${rows.join('\n')}\n';
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final classLabel = _classCode == 'all' ? 'AllClasses' : _classCode;
      final defaultFileName = 'FAP_Attendance_${classLabel}_$timestamp.csv';

      // 1. Save locally via FileService
      final savedPath = await _fileService.saveTextFile(
        dialogTitle: 'Lưu tệp CSV điểm danh FAP',
        fileName: defaultFileName,
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
          fileName: defaultFileName,
          content: csvContent,
          classCode: classLabel,
        );
      } catch (uploadError) {
        debugPrint('Cloud storage backup notification: $uploadError');
      }

      // 3. Log Analytics event (Service 4)
      _analyticsService.logExportReport(
        classCode: classLabel,
        fileType: 'fap_csv',
      );

      _isExporting = false;
      notifyListeners();
      return savedPath;
    } catch (e, st) {
      _crashlyticsService.recordError(e, st, reason: 'Export FAP CSV failed');
      _isExporting = false;
      _operationMessage = 'Lỗi xuất tệp: $e';
      notifyListeners();
      return null;
    }
  }

  Future<int> importStudents({
    required bool isExcel,
    required String fallbackClass,
  }) async {
    _isImporting = true;
    _operationMessage = null;
    notifyListeners();

    try {
      final students = isExcel
          ? await _fileService.importStudentsFromExcel(fallbackClass)
          : await _fileService.importStudentsFromCsv(fallbackClass);

      if (students.isEmpty) {
        _isImporting = false;
        _operationMessage = 'Không tìm thấy dòng dữ liệu sinh viên nào trong tệp.';
        notifyListeners();
        return 0;
      }

      final added = await _statsService.sheetService.appendStudents(students);
      await _statsService.load(force: true);
      _buildDataState();

      _analyticsService.logEvent('import_students', {
        'count': added,
        'format': isExcel ? 'excel' : 'csv',
      });

      _isImporting = false;
      notifyListeners();
      return added;
    } catch (e, st) {
      _crashlyticsService.recordError(e, st, reason: 'Import students failed');
      _isImporting = false;
      _operationMessage = 'Lỗi nhập danh sách: $e';
      notifyListeners();
      return 0;
    }
  }

  String syncStatus(String sessionId) {
    final statuses = _statsService.attendance
        .where((row) => row.sessionId == sessionId)
        .map((row) => row.syncStatus)
        .toSet();
    if (statuses.isEmpty) return 'not_taken';
    if (statuses.contains('draft')) return 'draft';
    return 'submitted';
  }

  String _csvEscape(Object value) =>
      '"${value.toString().replaceAll('"', '""')}"';
}
