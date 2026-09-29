import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gsheets/gsheets.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/attendance_record.dart';
import '../models/student.dart';

class GoogleSheetException implements Exception {
  final String message;

  const GoogleSheetException(this.message);

  @override
  String toString() => message;
}

class SheetScheduleRow {
  final String sessionId;
  final String classCode;
  final String subjectCode;
  final String subjectName;
  final String sessionDate;
  final String slot;
  final String room;
  final int sessionNo;
  final int totalSessions;

  const SheetScheduleRow({
    required this.sessionId,
    required this.classCode,
    required this.subjectCode,
    required this.subjectName,
    required this.sessionDate,
    required this.slot,
    required this.room,
    required this.sessionNo,
    required this.totalSessions,
  });
}

class SheetAttendanceRow {
  final String attendanceId;
  final String sessionId;
  final String studentId;
  final String status;
  final String note;
  final String syncStatus;
  final String updatedAt;

  const SheetAttendanceRow({
    required this.attendanceId,
    required this.sessionId,
    required this.studentId,
    required this.status,
    required this.note,
    required this.syncStatus,
    required this.updatedAt,
  });
}

class SeedSummary {
  final int subjectCount;
  final int classCount;
  final int studentsAdded;
  final int sessionsAdded;
  final int attendanceAdded;

  const SeedSummary({
    required this.subjectCount,
    required this.classCount,
    required this.studentsAdded,
    required this.sessionsAdded,
    required this.attendanceAdded,
  });
}

class GoogleSheetService {
  String? _spreadsheetId;
  GSheets? _gsheets;
  Worksheet? _studentsSheet;
  Worksheet? _scheduleSheet;
  Worksheet? _attendanceSheet;
  bool _initialized = false;
  bool _isLive = false;
  String? _lastError;

  bool get isLive => _isLive;
  String? get lastError => _lastError;

  GoogleSheetService([String? customSpreadsheetId]) {
    _spreadsheetId = customSpreadsheetId ?? _readEnv('GOOGLE_SPREADSHEET_ID');
  }

  String? _readEnv(String key) {
    try {
      return dotenv.env[key];
    } on NotInitializedError {
      return null;
    }
  }

  /// Sign out by deleting cached OAuth credentials.
  /// After calling this, the next [init] call will prompt the user to choose a Google account.
  Future<void> signOut() async {
    try {
      final file = await _credentialsFile();
      if (await file.exists()) await file.delete();
    } catch (_) {}
    _initialized = false;
    _isLive = false;
    _gsheets = null;
    _studentsSheet = null;
    _scheduleSheet = null;
    _attendanceSheet = null;
    _lastError = null;
  }

  Future<bool> init({bool forceReauth = false}) async {
    if (_initialized && _isLive && !forceReauth) return true;

    if (forceReauth) await signOut();

    try {
      final clientId = _readEnv('GOOGLE_CLIENT_ID')?.trim() ?? '';
      final clientSecret = _readEnv('GOOGLE_CLIENT_SECRET')?.trim() ?? '';
      final targetSpreadsheetId = _spreadsheetId ?? _readEnv('GOOGLE_SPREADSHEET_ID') ?? '';

      if (clientId.isEmpty || clientSecret.isEmpty || targetSpreadsheetId.isEmpty) {
        throw const GoogleSheetException('GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, and GOOGLE_SPREADSHEET_ID are required.');
      }

      final oauthClient = await _loadCachedClient(auth.ClientId(clientId, clientSecret)) ?? await _requestUserClient(auth.ClientId(clientId, clientSecret));
      await _saveCredentials(oauthClient.credentials);
      _gsheets = GSheets.withClient(oauthClient);
      final ss = await _gsheets!.spreadsheet(targetSpreadsheetId);

      _studentsSheet = ss.worksheetByTitle('students');
      _scheduleSheet = ss.worksheetByTitle('schedule');
      _attendanceSheet = ss.worksheetByTitle('attendance');
      final missing = <String>[
        if (_studentsSheet == null) 'students',
        if (_scheduleSheet == null) 'schedule',
        if (_attendanceSheet == null) 'attendance',
      ];
      if (missing.isNotEmpty) throw GoogleSheetException('Missing required sheet tab(s): ${missing.join(', ')}');
      await _validateHeaders(_studentsSheet!, 'students', _studentsHeaders);
      await _validateHeaders(_scheduleSheet!, 'schedule', _scheduleHeaders);
      await _validateHeaders(_attendanceSheet!, 'attendance', _attendanceHeaders);

      _isLive = true;
      _initialized = true;
      _lastError = null;
      return true;
    } catch (e) {
      debugPrint('Google Sheets Init Error: $e');
      _isLive = false;
      _initialized = true;
      _lastError = 'Google Sheets connection error: $e';
      return false;
    }
  }

  Future<List<Student>> getStudentsByClass(String classId) async {
    final students = await getAllStudents();
    return students.where((student) => student.classId.toUpperCase() == classId.trim().toUpperCase()).toList();
  }

  Future<List<Student>> getAllStudents() async {
    await _requireLive();
    try {
      final rows = await _readRows(_studentsSheet!, 'students', _studentsHeaders);
      return rows.map((row) => Student(
        studentId: _value(row, 'student_id'),
        studentCode: _value(row, 'student_code'),
        studentName: _value(row, 'full_name'),
        classId: _value(row, 'class_code'),
        email: _value(row, 'email'),
        gender: _value(row, 'gender'),
        major: _value(row, 'major'),
        photoUrl: _value(row, 'photo_url'),
      )).where((student) => student.studentId.isNotEmpty && student.studentName.isNotEmpty && student.classId.isNotEmpty).toList();
    } catch (e) {
      throw GoogleSheetException('Could not read students: $e');
    }
  }

  Future<List<SheetScheduleRow>> getSchedule() async {
    await _requireLive();
    try {
      final rows = await _readRows(_scheduleSheet!, 'schedule', _scheduleHeaders);
      return rows.map((row) {
        final rawDate = _value(row, 'session_date');
        final cleanDate = rawDate.startsWith('\'') ? rawDate.substring(1) : rawDate;
        return SheetScheduleRow(
          sessionId: _value(row, 'session_id'), classCode: _value(row, 'class_code'),
          subjectCode: _value(row, 'subject_code'), subjectName: _value(row, 'subject_name'),
          sessionDate: cleanDate, slot: _value(row, 'slot'), room: _value(row, 'room'),
          sessionNo: int.tryParse(_value(row, 'session_no')) ?? 0,
          totalSessions: int.tryParse(_value(row, 'total_sessions')) ?? 0,
        );
      }).where((row) => row.sessionId.isNotEmpty && row.classCode.isNotEmpty).toList();
    } catch (e) {
      throw GoogleSheetException('Could not read schedule: $e');
    }
  }

  Future<List<SheetAttendanceRow>> getAttendance(String sessionId) async {
    final rows = await getAllAttendance();
    return rows.where((row) => row.sessionId == sessionId).toList();
  }

  Future<List<SheetAttendanceRow>> getAllAttendance() async {
    await _requireLive();
    try {
      final rows = await _readRows(_attendanceSheet!, 'attendance', _attendanceHeaders);
      return rows.map((row) => SheetAttendanceRow(
        attendanceId: _value(row, 'attendance_id'), sessionId: _value(row, 'session_id'),
        studentId: _value(row, 'student_id'), status: _value(row, 'status'), note: _value(row, 'note'),
        syncStatus: _value(row, 'sync_status'), updatedAt: _value(row, 'updated_at'),
      )).toList();
    } catch (e) {
      throw GoogleSheetException('Could not read attendance: $e');
    }
  }

  Future<void> upsertAttendance({required String sessionId, required String studentId, required String status, required String note, required String syncStatus}) async {
    await _requireLive();
    if (status != 'present' && status != 'absent') throw const GoogleSheetException('Attendance status must be present or absent.');
    if (syncStatus != 'draft' && syncStatus != 'submitted') throw const GoogleSheetException('Sync status must be draft or submitted.');
    try {
      final rows = await _readRows(_attendanceSheet!, 'attendance', _attendanceHeaders);
      final rowIndex = rows.indexWhere((row) => _value(row, 'session_id') == sessionId && _value(row, 'student_id') == studentId) + 2;
      final values = ['attendance-$sessionId-$studentId', sessionId, studentId, status, note, syncStatus, DateTime.now().toUtc().toIso8601String()];
      if (rowIndex == 1) {
        await _attendanceSheet!.values.appendRow(values);
      } else {
        await _attendanceSheet!.values.insertRow(rowIndex, values);
      }
    } catch (e) {
      throw GoogleSheetException('Could not save attendance: $e');
    }
  }

  Future<void> appendStudents(List<Student> newStudents) async {
    await _requireLive();
    try {
      await _studentsSheet!.values.appendRows(newStudents.map((s) => [s.studentId, s.studentCode, s.fullName, s.email, s.classId, s.gender, s.major, s.photoUrl]).toList());
    } catch (e) {
      throw GoogleSheetException('Could not append students: $e');
    }
  }

  Future<void> saveAttendance(List<AttendanceRecord> records) async {
    for (final record in records) {
      await upsertAttendance(
        sessionId: record.sessionId,
        studentId: record.studentId,
        status: record.status.toLowerCase(),
        note: record.note,
        syncStatus: 'draft',
      );
    }
  }

  /// Clears all data and rewrites headers to guarantee column order.
  Future<void> _clearDataRows(Worksheet sheet, List<String> headers) async {
    await sheet.clear();
    await sheet.values.insertRow(1, headers);
  }

  /// Full-replace seed: clears all 3 tabs then generates fresh randomized data.
  Future<SeedSummary> seedSampleData() async {
    await _requireLive();
    try {
      // ── 1. Clear all existing data rows ──────────────────────────────────
      await Future.wait([
        _clearDataRows(_studentsSheet!, _studentsHeaders),
        _clearDataRows(_scheduleSheet!, _scheduleHeaders),
        _clearDataRows(_attendanceSheet!, _attendanceHeaders),
      ]);

      final rng = Random();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // ── 2. Generate random subjects and classes ──────────────────────────
      const allSubjects = [
        ['SWE202', 'Software Testing'],
        ['SWP391', 'Application Development Project'],
        ['DBI202', 'Database Systems'],
        ['SWD392', 'Software Architecture'],
        ['PRN231', 'Web API Development'],
        ['IOT102', 'Internet of Things'],
        ['MAS291', 'Statistics and Probability'],
        ['JPD123', 'Japanese Elementary 1'],
        ['NWC203', 'Computer Networking'],
        ['OSG202', 'Operating Systems'],
      ];
      const allMajors = ['SE', 'IA', 'AI', 'IoT', 'BA'];

      // Pick 3–5 random subjects
      final subjectPool = List<List<String>>.from(allSubjects)..shuffle(rng);
      final subjectCount = 3 + rng.nextInt(3); // 3, 4, or 5
      final subjects = subjectPool.take(subjectCount).toList();

      // For each subject, create 2-3 classes
      final classDefinitions = <Map<String, String>>[];  // {classCode, subjectCode, subjectName, major}
      var classSerial = 1801;
      for (final subject in subjects) {
        final numClasses = 2 + rng.nextInt(2); // 2 or 3
        final primaryMajor = allMajors[rng.nextInt(allMajors.length)];
        for (var c = 0; c < numClasses; c++) {
          classDefinitions.add({
            'classCode': 'SE${classSerial++}',
            'subjectCode': subject[0],
            'subjectName': subject[1],
            'primaryMajor': primaryMajor,
          });
        }
      }

      // ── 3. Generate students per class ──────────────────────────────────
      // Vietnamese name components for varied random generation
      const lastNames = [
        'Nguyen', 'Tran', 'Le', 'Pham', 'Hoang', 'Huynh', 'Phan', 'Vu',
        'Vo', 'Dang', 'Bui', 'Do', 'Ho', 'Ngo', 'Duong', 'Ly',
        'Trinh', 'Dinh', 'Luong', 'Mai', 'Lam', 'Ha', 'Cao', 'Ta',
      ];
      const middleNames = [
        'Minh', 'Thanh', 'Quoc', 'Ngoc', 'Hoang', 'Duc', 'Thi',
        'Thu', 'Gia', 'Hai', 'Khanh', 'Xuan', 'Bao', 'Phuong',
        'Tuan', 'Mai', 'Duy', 'Anh', 'Van', 'Kim', 'Hong', 'Huu',
      ];
      const givenNamesMale = [
        'Anh', 'Bao', 'Dat', 'Dung', 'Hieu', 'Hung', 'Huy', 'Khai',
        'Kiet', 'Khoa', 'Long', 'Minh', 'Nam', 'Phuc', 'Quan',
        'Son', 'Tai', 'Thinh', 'Tien', 'Tri', 'Trung', 'Tuan', 'Vu',
      ];
      const givenNamesFemale = [
        'Anh', 'Chi', 'Chau', 'Diem', 'Giang', 'Ha', 'Han', 'Hang',
        'Hanh', 'Huong', 'Lan', 'Linh', 'Mai', 'My', 'Nhi',
        'Phuong', 'Thao', 'Trang', 'Trinh', 'Uyen', 'Van', 'Vy', 'Yen',
      ];

      final usedStudentCodes = <String>{};
      final allStudentRows = <List<String>>[]; // raw rows for sheet
      final studentsByClass = <String, List<List<String>>>{}; // classCode → students

      String uniqueStudentCode() {
        String code;
        do {
          code = 'HE17${(1000 + rng.nextInt(9000)).toString()}';
        } while (usedStudentCodes.contains(code));
        usedStudentCodes.add(code);
        return code;
      }

      var globalStudentId = 1;
      for (final classDef in classDefinitions) {
        final classCode = classDef['classCode']!;
        final primaryMajor = classDef['primaryMajor']!;
        final numStudents = 15 + rng.nextInt(16); // 15–30
        final classStudents = <List<String>>[];

        for (var s = 0; s < numStudents; s++) {
          final isFemale = rng.nextBool();
          final lastName = lastNames[rng.nextInt(lastNames.length)];
          final middle = middleNames[rng.nextInt(middleNames.length)];
          final given = isFemale
              ? givenNamesFemale[rng.nextInt(givenNamesFemale.length)]
              : givenNamesMale[rng.nextInt(givenNamesMale.length)];
          final fullName = '$lastName $middle $given';
          final gender = isFemale ? 'Female' : 'Male';
          // ~10-20% cross-enrolled from another major
          final isCrossEnrolled = rng.nextDouble() < 0.15;
          final major = isCrossEnrolled
              ? allMajors.where((m) => m != primaryMajor).toList()[rng.nextInt(allMajors.length - 1)]
              : primaryMajor;
          final studentCode = uniqueStudentCode();
          final studentId = 'STU-${globalStudentId++}';

          final row = [
            studentId,
            studentCode,
            fullName,
            '${studentCode.toLowerCase()}@fpt.edu.vn',
            classCode,
            gender,
            major,
            '',  // photo_url
          ];
          classStudents.add(row);
          allStudentRows.add(row);
        }
        studentsByClass[classCode] = classStudents;
      }

      // ── 4. Generate schedule (weekly pattern per class) ─────────────────
      // Cycle through weekday pairs so different classes meet on different days
      const weekdayPairPool = [
        [DateTime.monday, DateTime.thursday],
        [DateTime.tuesday, DateTime.friday],
        [DateTime.wednesday, DateTime.saturday],
        [DateTime.monday, DateTime.wednesday],
        [DateTime.tuesday, DateTime.thursday],
        [DateTime.wednesday, DateTime.friday],
        [DateTime.monday, DateTime.friday],
      ];
      const totalSessions = 30;
      // Anchor ~7.5 weeks back so ~15 sessions are past and ~15 are future
      final anchorDate = today.subtract(const Duration(days: 52));
      const slotLabels = ['Slot 1', 'Slot 2', 'Slot 3', 'Slot 4', 'Slot 5', 'Slot 6'];
      const rooms = ['Room 301', 'Room 302', 'Room 303', 'Room 401', 'Room 402', 'Lab A-201', 'Lab B-102'];

      final allScheduleRows = <List<String>>[];
      final scheduleByClass = <String, List<List<String>>>{}; // classCode → sessions

      var globalSessionId = 1;
      for (var ci = 0; ci < classDefinitions.length; ci++) {
        final classDef = classDefinitions[ci];
        final classCode = classDef['classCode']!;
        final weekdays = weekdayPairPool[ci % weekdayPairPool.length];
        final slotLabel = slotLabels[ci % slotLabels.length];
        final room = rooms[ci % rooms.length];

        // Walk forward from anchor collecting matching weekdays
        final candidates = <DateTime>[];
        var cursor = anchorDate;
        while (candidates.length < totalSessions + 10) {
          if (weekdays.contains(cursor.weekday)) candidates.add(cursor);
          cursor = cursor.add(const Duration(days: 1));
        }
        final sessionDates = candidates.take(totalSessions).toList();

        final classSessions = <List<String>>[];
        for (var sn = 1; sn <= sessionDates.length; sn++) {
          final date = sessionDates[sn - 1];
          final dateText = '\'${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final sessionId = 'SES-${globalSessionId++}';
          final row = [
            sessionId,
            classCode,
            classDef['subjectCode']!,
            classDef['subjectName']!,
            dateText,
            slotLabel,
            room,
            '$sn',
            '$totalSessions',
          ];
          classSessions.add(row);
          allScheduleRows.add(row);
        }
        scheduleByClass[classCode] = classSessions;
      }

      // ── 5. Generate attendance ──────────────────────────────────────────
      // Only for isHeld sessions (dateOnly(date) <= dateOnly(today)).
      // Absence profile per data-seeding.md: ~70% ok, ~15% warning, ~15% banned
      // with randomness within each band.
      final allAttendanceRows = <List<String>>[];
      var globalAttId = 1;

      for (final classDef in classDefinitions) {
        final classCode = classDef['classCode']!;
        final classSessions = scheduleByClass[classCode] ?? [];
        final classStudents = studentsByClass[classCode] ?? [];

        // Held sessions: date <= today
        final heldSessions = classSessions.where((s) {
          final d = DateTime.tryParse(s[4]);
          return d != null && !DateTime(d.year, d.month, d.day).isAfter(today);
        }).toList();
        final heldCount = heldSessions.length;
        if (heldCount == 0 || classStudents.isEmpty) continue;

        // Assign each student a target absence rate within their band
        for (var si = 0; si < classStudents.length; si++) {
          final studentId = classStudents[si][0];

          // Determine band: ~70% ok (0–10%), ~15% warning (15–19%), ~15% banned (20–35%)
          double targetRate;
          final pct = si / classStudents.length;
          if (pct < 0.70) {
            // ok band: random 0% – 10%
            targetRate = rng.nextDouble() * 0.10;
          } else if (pct < 0.85) {
            // warning band: random 15% – 19%
            targetRate = 0.15 + rng.nextDouble() * 0.04;
          } else {
            // banned band: random 20% – 35%
            targetRate = 0.20 + rng.nextDouble() * 0.15;
          }

          final targetAbsent = (heldCount * targetRate).round();

          // Pick which sessions to mark absent — spread randomly, not just first N
          final absentIndices = <int>{};
          if (targetAbsent > 0 && targetAbsent < heldCount) {
            final indices = List.generate(heldCount, (i) => i)..shuffle(rng);
            absentIndices.addAll(indices.take(targetAbsent));
          } else if (targetAbsent >= heldCount) {
            absentIndices.addAll(List.generate(heldCount, (i) => i));
          }

          for (var hi = 0; hi < heldCount; hi++) {
            final session = heldSessions[hi];
            final isAbsent = absentIndices.contains(hi);
            allAttendanceRows.add([
              'ATT-${globalAttId++}',
              session[0],  // session_id
              studentId,
              isAbsent ? 'absent' : 'present',
              '',
              'submitted', // spec: never "draft" for seed data
              DateTime.now().toUtc().toIso8601String(),
            ]);
          }
        }
      }

      // ── 6. Write all data to sheets ─────────────────────────────────────
      final futures = <Future<void>>[];
      if (allStudentRows.isNotEmpty) {
        futures.add(_studentsSheet!.values.appendRows(allStudentRows));
      }
      if (allScheduleRows.isNotEmpty) {
        futures.add(_scheduleSheet!.values.appendRows(allScheduleRows));
      }
      if (allAttendanceRows.isNotEmpty) {
        // Run batch updates concurrently in chunks of 1000
        for (var i = 0; i < allAttendanceRows.length; i += 1000) {
          final end = (i + 1000).clamp(0, allAttendanceRows.length);
          futures.add(_attendanceSheet!.values.appendRows(allAttendanceRows.sublist(i, end)));
        }
      }
      await Future.wait(futures);

      return SeedSummary(
        subjectCount: subjects.length,
        classCount: classDefinitions.length,
        studentsAdded: allStudentRows.length,
        sessionsAdded: allScheduleRows.length,
        attendanceAdded: allAttendanceRows.length,
      );
    } catch (e) {
      throw GoogleSheetException('Could not seed sample data: $e');
    }
  }

  Future<auth.AutoRefreshingAuthClient?> _loadCachedClient(auth.ClientId clientId) async {
    try {
      final file = await _credentialsFile();
      if (!await file.exists()) return null;
      final credentials = auth.AccessCredentials.fromJson(jsonDecode(await file.readAsString()) as Map<String, dynamic>);
      if (credentials.refreshToken == null) return null;
      return auth.autoRefreshingClient(clientId, credentials, http.Client());
    } catch (_) {
      return null;
    }
  }

  Future<auth.AutoRefreshingAuthClient> _requestUserClient(auth.ClientId clientId) async {
    final client = await auth.clientViaUserConsent(
      clientId,
      const ['https://www.googleapis.com/auth/spreadsheets'],
      (authorizationUrl) async {
        // Append prompt=select_account so Google always shows the account picker
        final uri = Uri.parse(authorizationUrl);
        final modifiedUri = uri.replace(
          queryParameters: {
            ...uri.queryParameters,
            'prompt': 'select_account',
          },
        );
        final opened = await launchUrl(modifiedUri, mode: LaunchMode.externalApplication);
        if (!opened) throw const GoogleSheetException('Could not open the Google authorization page.');
      },
    );
    return client;
  }

  Future<void> _saveCredentials(auth.AccessCredentials credentials) async {
    if (credentials.refreshToken == null) return;
    final file = await _credentialsFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(credentials.toJson()), flush: true);
  }

  Future<File> _credentialsFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}${Platform.pathSeparator}fap_attendance_oauth.json');
  }

  Future<void> _requireLive() async {
    if (!await init()) throw GoogleSheetException(_lastError ?? 'Google Sheets is unavailable.');
  }

  Future<void> _validateHeaders(Worksheet sheet, String name, List<String> required) async {
    final rows = await sheet.values.allRows(fromRow: 1, count: 1, fill: true);
    final headers = rows.isEmpty ? <String>{} : rows.first.map((key) => key.trim()).toSet();
    final missing = required.where((key) => !headers.contains(key)).toList();
    if (missing.isNotEmpty) {
      throw GoogleSheetException('Sheet "$name" is missing required column(s): ${missing.join(', ')}');
    }
  }

  Future<List<Map<String, String>>> _readRows(Worksheet sheet, String name, List<String> requiredHeaders) async {
    final rawRows = await sheet.values.allRows(fromRow: 1, fill: false);
    if (rawRows.isEmpty) return [];

    final physicalHeaders = rawRows.first.map((key) => key.trim()).toList();
    final headerSet = physicalHeaders.toSet();
    
    final missing = requiredHeaders.where((key) => !headerSet.contains(key)).toList();
    if (missing.isNotEmpty) {
      throw GoogleSheetException('Sheet "$name" is missing required column(s): ${missing.join(', ')}');
    }

    final rows = <Map<String, String>>[];
    for (var i = 1; i < rawRows.length; i++) {
      final rawRow = rawRows[i];
      final values = List<String>.filled(physicalHeaders.length, '');
      for (var j = 0; j < rawRow.length && j < physicalHeaders.length; j++) {
        values[j] = rawRow[j].trim();
      }
      if (values.every((value) => value.isEmpty)) continue;
      
      final rowMap = <String, String>{};
      for (var j = 0; j < physicalHeaders.length; j++) {
        rowMap[physicalHeaders[j]] = values[j];
      }
      rows.add(rowMap);
    }
    return rows;
  }

  static const _studentsHeaders = ['student_id', 'student_code', 'full_name', 'email', 'class_code', 'gender', 'major', 'photo_url'];
  static const _scheduleHeaders = ['session_id', 'class_code', 'subject_code', 'subject_name', 'session_date', 'slot', 'room', 'session_no', 'total_sessions'];
  static const _attendanceHeaders = ['attendance_id', 'session_id', 'student_id', 'status', 'note', 'sync_status', 'updated_at'];

  String _value(Map<String, String> row, String key) => row[key]?.trim() ?? '';
}
