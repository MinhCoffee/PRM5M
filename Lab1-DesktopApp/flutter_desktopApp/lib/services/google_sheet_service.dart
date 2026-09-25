import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gsheets/gsheets.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';

class GoogleSheetService {
  String? _spreadsheetId;
  GSheets? _gsheets;
  Worksheet? _studentsSheet;
  Worksheet? _attendanceSheet;
  bool _initialized = false;
  bool _isLive = false;
  String? _lastError;

  // Local fallback storage when Sheets API credentials are not provided or offline
  final List<Student> _localStudents = [
    Student(studentId: 'SE170001', studentName: 'Nguyễn Văn A', classId: 'SE1801', email: 'anv@fpt.edu.vn'),
    Student(studentId: 'SE170002', studentName: 'Trần Thị B', classId: 'SE1801', email: 'btt@fpt.edu.vn'),
    Student(studentId: 'SE170003', studentName: 'Lê Hoàng C', classId: 'SE1801', email: 'cleh@fpt.edu.vn'),
    Student(studentId: 'SE170004', studentName: 'Phạm Minh D', classId: 'SE1801', email: 'dpm@fpt.edu.vn'),
    Student(studentId: 'SE170005', studentName: 'Vũ Thị E', classId: 'SE1801', email: 'evt@fpt.edu.vn'),
    Student(studentId: 'SE170006', studentName: 'Đặng Tuấn F', classId: 'SE1802', email: 'fdt@fpt.edu.vn'),
    Student(studentId: 'SE170007', studentName: 'Bùi Bảo G', classId: 'SE1802', email: 'gbb@fpt.edu.vn'),
  ];

  final List<AttendanceRecord> _localAttendance = [];

  bool get isLive => _isLive;
  String? get lastError => _lastError;

  GoogleSheetService([String? customSpreadsheetId]) {
    _spreadsheetId = customSpreadsheetId ?? _readEnv('SPREADSHEET_ID');
  }

  String? _readEnv(String key) {
    try {
      return dotenv.env[key];
    } on NotInitializedError {
      return null;
    }
  }

  Future<bool> init() async {
    if (_initialized && _isLive) return true;

    try {
      final credentialsJson = await rootBundle.loadString('assets/credentials.json');
      final Map<String, dynamic> parsed = jsonDecode(credentialsJson);

      // Check if credentials are valid (not template/placeholder)
      final clientEmail = parsed['client_email']?.toString() ?? '';
      final targetSpreadsheetId = _spreadsheetId ?? _readEnv('SPREADSHEET_ID') ?? '';

      if (clientEmail.contains('your-service-account') ||
          targetSpreadsheetId.isEmpty ||
          targetSpreadsheetId.contains('your_spreadsheet_id')) {
        _isLive = false;
        _initialized = true;
        _lastError = 'Google Sheets credentials or Spreadsheet ID not configured (using local cache mode).';
        return false;
      }

      _gsheets = GSheets(credentialsJson);
      final ss = await _gsheets!.spreadsheet(targetSpreadsheetId);

      _studentsSheet = ss.worksheetByTitle('Students');
      _studentsSheet ??= await ss.addWorksheet('Students');

      _attendanceSheet = ss.worksheetByTitle('Attendance');
      _attendanceSheet ??= await ss.addWorksheet('Attendance');

      // Ensure headers exist
      await _ensureHeaders();

      _isLive = true;
      _initialized = true;
      _lastError = null;
      return true;
    } catch (e) {
      debugPrint('Google Sheets Init Error: $e');
      _isLive = false;
      _initialized = true;
      _lastError = 'Google Sheets connection error: $e. Falling back to local storage.';
      return false;
    }
  }

  Future<void> _ensureHeaders() async {
    if (_studentsSheet != null) {
      final firstRow = await _studentsSheet!.values.row(1);
      if (firstRow.isEmpty) {
        await _studentsSheet!.values.insertRow(1, ['StudentID', 'StudentName', 'ClassID', 'Email']);
      }
    }
    if (_attendanceSheet != null) {
      final firstRow = await _attendanceSheet!.values.row(1);
      if (firstRow.isEmpty) {
        await _attendanceSheet!.values.insertRow(1, ['SessionID', 'Date', 'ClassID', 'StudentID', 'Status', 'Note']);
      }
    }
  }

  Future<List<Student>> getStudentsByClass(String classId) async {
    await init();
    if (_isLive && _studentsSheet != null) {
      try {
        final rows = await _studentsSheet!.values.map.allRows() ?? [];
        final fetched = rows
            .where((row) => (row['ClassID'] ?? '').toString().trim().toUpperCase() == classId.trim().toUpperCase())
            .map((row) => Student(
                  studentId: row['StudentID'] ?? '',
                  studentName: row['StudentName'] ?? '',
                  classId: row['ClassID'] ?? '',
                  email: row['Email'] ?? '',
                ))
            .toList();

        if (fetched.isNotEmpty) return fetched;
      } catch (e) {
        debugPrint('Error fetching students from GSheets: $e');
      }
    }

    // Fallback to local students filter
    return _localStudents
        .where((s) => s.classId.toUpperCase() == classId.toUpperCase())
        .toList();
  }

  Future<List<Student>> getAllStudents() async {
    await init();
    if (_isLive && _studentsSheet != null) {
      try {
        final rows = await _studentsSheet!.values.map.allRows() ?? [];
        if (rows.isNotEmpty) {
          return rows
              .map((row) => Student(
                    studentId: row['StudentID'] ?? '',
                    studentName: row['StudentName'] ?? '',
                    classId: row['ClassID'] ?? '',
                    email: row['Email'] ?? '',
                  ))
              .toList();
        }
      } catch (e) {
        debugPrint('Error getting all students from GSheets: $e');
      }
    }
    return List.from(_localStudents);
  }

  Future<void> saveAttendance(List<AttendanceRecord> records) async {
    await init();
    _localAttendance.addAll(records);

    if (_isLive && _attendanceSheet != null) {
      try {
        final rows = records.map((r) => [
          r.sessionId,
          r.date.toIso8601String().substring(0, 10),
          r.classId,
          r.studentId,
          r.status,
          r.note,
        ]).toList();

        await _attendanceSheet!.values.appendRows(rows);
      } catch (e) {
        debugPrint('Error saving attendance to Google Sheets: $e');
        throw Exception('Lỗi lưu điểm danh lên Google Sheets: $e');
      }
    }
  }

  Future<void> appendStudents(List<Student> newStudents) async {
    await init();
    // Add to local cache first
    for (final s in newStudents) {
      if (!_localStudents.any((existing) => existing.studentId == s.studentId)) {
        _localStudents.add(s);
      }
    }

    if (_isLive && _studentsSheet != null) {
      try {
        final rows = newStudents.map((s) => [
          s.studentId,
          s.studentName,
          s.classId,
          s.email,
        ]).toList();

        await _studentsSheet!.values.appendRows(rows);
      } catch (e) {
        debugPrint('Error appending students to Google Sheets: $e');
        throw Exception('Lỗi append sinh viên vào Google Sheets: $e');
      }
    }
  }

  List<AttendanceRecord> getLocalAttendanceHistory(String classId) {
    return _localAttendance.where((r) => r.classId.toUpperCase() == classId.toUpperCase()).toList();
  }
}
