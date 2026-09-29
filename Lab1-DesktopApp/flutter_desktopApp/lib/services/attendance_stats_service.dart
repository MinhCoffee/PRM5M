import 'package:shared_preferences/shared_preferences.dart';

import '../models/student.dart';
import 'google_sheet_service.dart';

enum StudentRiskStatus { ok, warning, banned }

enum SessionStatus { notTaken, inProgress, taken, overdueNotTaken }

extension StudentRiskStatusLabel on StudentRiskStatus {
  String get value => switch (this) {
    StudentRiskStatus.ok => 'ok',
    StudentRiskStatus.warning => 'warning',
    StudentRiskStatus.banned => 'banned',
  };
}

extension SessionStatusLabel on SessionStatus {
  String get value => switch (this) {
    SessionStatus.notTaken => 'Upcoming',
    SessionStatus.inProgress => 'Taking Attendance',
    SessionStatus.taken => 'Completed',
    SessionStatus.overdueNotTaken => 'Missing Attendance',
  };
}

class AttendanceStudentStats {
  final Student student;
  final int sessionsHeld;
  final int absentCount;
  final double absenceRate;
  final StudentRiskStatus status;

  const AttendanceStudentStats({
    required this.student,
    required this.sessionsHeld,
    required this.absentCount,
    required this.absenceRate,
    required this.status,
  });
}

class AttendanceClassStats {
  final String classCode;
  final String subjectName;
  final int studentCount;
  final double progress;
  final int warningCount;
  final int bannedCount;

  const AttendanceClassStats({
    required this.classCode,
    required this.subjectName,
    required this.studentCount,
    required this.progress,
    required this.warningCount,
    required this.bannedCount,
  });
}

class AttendanceSubjectStats {
  final String classCode;
  final String subjectCode;
  final String subjectName;
  final int recordsCount;
  final int absentCount;
  final double absenceRate;
  final StudentRiskStatus status;

  const AttendanceSubjectStats({
    required this.classCode,
    required this.subjectCode,
    required this.subjectName,
    required this.recordsCount,
    required this.absentCount,
    required this.absenceRate,
    required this.status,
  });
}

class AttendanceStatsService {
  static const defaultWarnThreshold = 0.15;
  static const defaultBanThreshold = 0.20;
  static const _warnKey = 'attendance_warn_threshold';
  static const _banKey = 'attendance_ban_threshold';

  final GoogleSheetService sheetService;
  List<Student> students = const [];
  List<SheetScheduleRow> sessions = const [];
  List<SheetAttendanceRow> attendance = const [];
  double warnThreshold = defaultWarnThreshold;
  double banThreshold = defaultBanThreshold;
  bool _loaded = false;

  AttendanceStatsService(this.sheetService);

  bool get isLoaded => _loaded;

  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    final preferences = await SharedPreferences.getInstance();
    warnThreshold = preferences.getDouble(_warnKey) ?? defaultWarnThreshold;
    banThreshold = preferences.getDouble(_banKey) ?? defaultBanThreshold;
    final result = await Future.wait([
      sheetService.getAllStudents(),
      sheetService.getSchedule(),
      sheetService.getAllAttendance(),
    ]);
    students = result[0] as List<Student>;
    sessions = result[1] as List<SheetScheduleRow>;
    attendance = result[2] as List<SheetAttendanceRow>;
    _loaded = true;
  }

  Future<void> setThresholds({
    required double warn,
    required double ban,
  }) async {
    if (warn < 0 || ban < 0 || warn > 1 || ban > 1 || warn >= ban) {
      throw ArgumentError(
        'Warn threshold must be lower than ban threshold and both must be between 0% and 100%.',
      );
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_warnKey, warn);
    await preferences.setDouble(_banKey, ban);
    warnThreshold = warn;
    banThreshold = ban;
  }

  Future<SeedSummary> seedSampleData() async {
    final result = await sheetService.seedSampleData();
    await load(force: true);
    return result;
  }

  double absenceRate(String studentId, String classCode) {
    final classSessionIds = sessions
        .where(
          (session) =>
              session.classCode == classCode &&
              _isOnOrBeforeToday(session.sessionDate),
        )
        .map((session) => session.sessionId)
        .toSet();
    final rows = attendance
        .where(
          (row) =>
              row.studentId == studentId &&
              classSessionIds.contains(row.sessionId),
        )
        .toList();
    if (rows.isEmpty) return 0;
    return rows.where((row) => row.status == 'absent').length / rows.length;
  }

  StudentRiskStatus studentStatus(double rate) {
    if (rate >= banThreshold) return StudentRiskStatus.banned;
    if (rate >= warnThreshold) return StudentRiskStatus.warning;
    return StudentRiskStatus.ok;
  }

  StudentRiskStatus attendancePolicyStatus(double rate) {
    if (rate > defaultBanThreshold) return StudentRiskStatus.banned;
    if (rate > defaultWarnThreshold) return StudentRiskStatus.warning;
    return StudentRiskStatus.ok;
  }

  SessionStatus sessionStatus(SheetScheduleRow session) {
    final sessionDate = DateTime.tryParse(session.sessionDate);
    if (sessionDate == null) return SessionStatus.notTaken;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(
      sessionDate.year,
      sessionDate.month,
      sessionDate.day,
    );
    if (sessionDay.isAfter(today)) return SessionStatus.notTaken;

    final rows = attendance
        .where((row) => row.sessionId == session.sessionId)
        .toList();
    if (rows.isEmpty) {
      return sessionDay == today
          ? SessionStatus.inProgress
          : SessionStatus.overdueNotTaken;
    }
    if (rows.any((row) => row.syncStatus == 'draft'))
      return SessionStatus.inProgress;
    return SessionStatus.taken;
  }

  double classProgress(String classCode) {
    final classSessions = sessions
        .where((session) => session.classCode == classCode)
        .toList();
    if (classSessions.isEmpty) return 0;
    final totalSessions = classSessions
        .map((session) => session.totalSessions)
        .fold<int>(0, (max, value) => value > max ? value : max);
    if (totalSessions == 0) return 0;
    // Count sessions that are held (date <= today) — not just sessions with attendance rows
    final heldCount = classSessions
        .where((session) => _isOnOrBeforeToday(session.sessionDate))
        .length;
    return (heldCount / totalSessions).clamp(0, 1).toDouble();
  }

  AttendanceStudentStats studentStats(Student student, {String? classCode}) {
    final selectedClass = classCode ?? student.classId;
    final classSessionIds = sessions
        .where(
          (session) =>
              session.classCode == selectedClass &&
              _isOnOrBeforeToday(session.sessionDate),
        )
        .map((session) => session.sessionId)
        .toSet();
    final rows = attendance
        .where(
          (row) =>
              row.studentId == student.studentId &&
              classSessionIds.contains(row.sessionId),
        )
        .toList();
    return _studentStatsFromRows(
      student: student,
      rows: rows,
      usePolicyThresholds: false,
    );
  }

  AttendanceStudentStats studentStatsAcrossAllSubjects(
    Student student, {
    bool usePolicyThresholds = false,
  }) {
    final heldSessionIds = _heldSessionsById().keys.toSet();
    final rows = attendance
        .where(
          (row) =>
              row.studentId == student.studentId &&
              heldSessionIds.contains(row.sessionId),
        )
        .toList();
    return _studentStatsFromRows(
      student: student,
      rows: rows,
      usePolicyThresholds: usePolicyThresholds,
    );
  }

  List<AttendanceSubjectStats> subjectStats({
    bool usePolicyThresholds = false,
  }) {
    final heldSessions = _heldSessionsById();
    final rowsBySubject = <String, List<SheetAttendanceRow>>{};
    final subjectsByKey = <String, SheetScheduleRow>{};

    for (final row in attendance) {
      final session = heldSessions[row.sessionId];
      if (session == null) continue;
      final key = _subjectKey(session);
      rowsBySubject.putIfAbsent(key, () => []).add(row);
      subjectsByKey.putIfAbsent(key, () => session);
    }

    return rowsBySubject.entries.map((entry) {
      final session = subjectsByKey[entry.key]!;
      return _subjectStatsFromRows(
        session: session,
        rows: entry.value,
        usePolicyThresholds: usePolicyThresholds,
      );
    }).toList()..sort((a, b) {
      final subjectCompare = a.subjectCode.compareTo(b.subjectCode);
      return subjectCompare != 0
          ? subjectCompare
          : a.classCode.compareTo(b.classCode);
    });
  }

  List<AttendanceSubjectStats> subjectStatsForStudent(
    Student student, {
    bool usePolicyThresholds = false,
  }) {
    final heldSessions = _heldSessionsById();
    final rowsBySubject = <String, List<SheetAttendanceRow>>{};
    final subjectsByKey = <String, SheetScheduleRow>{};

    for (final row in attendance) {
      if (row.studentId != student.studentId) continue;
      final session = heldSessions[row.sessionId];
      if (session == null) continue;
      final key = _subjectKey(session);
      rowsBySubject.putIfAbsent(key, () => []).add(row);
      subjectsByKey.putIfAbsent(key, () => session);
    }

    return rowsBySubject.entries.map((entry) {
      final session = subjectsByKey[entry.key]!;
      return _subjectStatsFromRows(
        session: session,
        rows: entry.value,
        usePolicyThresholds: usePolicyThresholds,
      );
    }).toList()..sort((a, b) {
      final rateCompare = b.absenceRate.compareTo(a.absenceRate);
      if (rateCompare != 0) return rateCompare;
      final subjectCompare = a.subjectCode.compareTo(b.subjectCode);
      return subjectCompare != 0
          ? subjectCompare
          : a.classCode.compareTo(b.classCode);
    });
  }

  List<AttendanceStudentStats> statsForClass(String classCode) => students
      .where((student) => student.classId == classCode)
      .map(studentStats)
      .toList();

  List<AttendanceClassStats> classStats() {
    final classCodes = {
      ...students.map((student) => student.classId),
      ...sessions.map((session) => session.classCode),
    }.where((code) => code.isNotEmpty).toList()..sort();
    return classCodes.map((classCode) {
      final studentRows = statsForClass(classCode);
      final subject = sessions.firstWhere(
        (session) => session.classCode == classCode,
        orElse: () => const SheetScheduleRow(
          sessionId: '',
          classCode: '',
          subjectCode: '',
          subjectName: '',
          sessionDate: '',
          slot: '',
          room: '',
          sessionNo: 0,
          totalSessions: 0,
        ),
      );
      return AttendanceClassStats(
        classCode: classCode,
        subjectName: subject.subjectName,
        studentCount: students
            .where((student) => student.classId == classCode)
            .length,
        progress: classProgress(classCode),
        warningCount: studentRows
            .where((row) => row.status == StudentRiskStatus.warning)
            .length,
        bannedCount: studentRows
            .where((row) => row.status == StudentRiskStatus.banned)
            .length,
      );
    }).toList();
  }

  AttendanceStudentStats _studentStatsFromRows({
    required Student student,
    required List<SheetAttendanceRow> rows,
    required bool usePolicyThresholds,
  }) {
    final absentCount = rows
        .where((row) => row.status.toLowerCase() == 'absent')
        .length;
    final rate = rows.isEmpty ? 0.0 : absentCount / rows.length;
    return AttendanceStudentStats(
      student: student,
      sessionsHeld: rows.length,
      absentCount: absentCount,
      absenceRate: rate,
      status: usePolicyThresholds
          ? attendancePolicyStatus(rate)
          : studentStatus(rate),
    );
  }

  AttendanceSubjectStats _subjectStatsFromRows({
    required SheetScheduleRow session,
    required List<SheetAttendanceRow> rows,
    required bool usePolicyThresholds,
  }) {
    final absentCount = rows
        .where((row) => row.status.toLowerCase() == 'absent')
        .length;
    final rate = rows.isEmpty ? 0.0 : absentCount / rows.length;
    return AttendanceSubjectStats(
      classCode: session.classCode,
      subjectCode: session.subjectCode,
      subjectName: session.subjectName,
      recordsCount: rows.length,
      absentCount: absentCount,
      absenceRate: rate,
      status: usePolicyThresholds
          ? attendancePolicyStatus(rate)
          : studentStatus(rate),
    );
  }

  Map<String, SheetScheduleRow> _heldSessionsById() => {
    for (final session in sessions)
      if (_isOnOrBeforeToday(session.sessionDate)) session.sessionId: session,
  };

  String _subjectKey(SheetScheduleRow session) =>
      '${session.subjectCode}|${session.classCode}';

  /// `isHeld(session)` per spec: dateOnly(session.date) <= dateOnly(now).
  /// Time-of-day and slot number do NOT matter.
  bool _isOnOrBeforeToday(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(date.year, date.month, date.day);
    return !sessionDay.isAfter(today);
  }
}
