import 'package:flutter/material.dart';
import '../../../services/google_sheet_service.dart';
import '../attendance_student.dart';

class AttendanceSession {
  final String id;
  final String subjectCode;
  final String subjectName;
  final String className;
  final String schedule;
  final String room;
  final String date;
  final int sessionNumber;
  final int totalSessions;
  final Color accentColor;

  const AttendanceSession({
    required this.id,
    required this.subjectCode,
    required this.subjectName,
    required this.className,
    required this.schedule,
    required this.room,
    required this.date,
    required this.sessionNumber,
    required this.totalSessions,
    required this.accentColor,
  });
}

abstract interface class AttendanceRepository {
  Future<List<AttendanceSession>> getSessions();
  Future<List<AttendanceStudent>> studentsForSession(String sessionId);
  Future<void> saveAttendance(String sessionId, List<AttendanceStudent> students, {required bool submitted});
  Future<SeedSummary> seedSampleData();
}

class MockAttendanceRepository implements AttendanceRepository {
  final List<AttendanceSession> _sessions = const [
    AttendanceSession(
      id: 'swp391-se1804',
      subjectCode: 'SWP391',
      subjectName: 'Application Development Project',
      className: 'SE1804',
      schedule: 'Slot 3 · 11:00 - 12:30',
      room: 'Room 302',
      date: 'Thu, 22/10/2026',
      sessionNumber: 14,
      totalSessions: 30,
      accentColor: Color(0xFF0072BC),
    ),
    AttendanceSession(
      id: 'swd392-se1802',
      subjectCode: 'SWD392',
      subjectName: 'Software Architecture',
      className: 'SE1802',
      schedule: 'Slot 1 · 07:30 - 09:00',
      room: 'Lab A-203',
      date: 'Fri, 23/10/2026',
      sessionNumber: 10,
      totalSessions: 30,
      accentColor: Color(0xFF35618D),
    ),
    AttendanceSession(
      id: 'swe202-se1801',
      subjectCode: 'SWE202',
      subjectName: 'Software Testing',
      className: 'SE1801',
      schedule: 'Slot 5 · 15:00 - 16:30',
      room: 'Room 405',
      date: 'Mon, 26/10/2026',
      sessionNumber: 8,
      totalSessions: 30,
      accentColor: Color(0xFFBA4C00),
    ),
  ];

  @override
  Future<List<AttendanceSession>> getSessions() async => _sessions;

  @override
  Future<List<AttendanceStudent>> studentsForSession(String sessionId) async {
    return [
      _student('HE170124', 'Tran Hoang Nam', 'Male', 1, 'Present in class', Colors.blue),
      _student('HE170318', 'Nguyen Thi Minh Anh', 'Female', 0, '', Colors.teal),
      _student('HE170455', 'Le Quoc Bao', 'Male', 3, 'Absent unexcused', Colors.indigo, present: false),
      _student('HE170682', 'Pham Duc Thang', 'Male', 1, '', Colors.deepOrange),
      _student('HE170791', 'Vu Huong Giang', 'Female', 2, 'Medical absence reported to Academic Affairs', Colors.purple, present: false),
      _student('HE170814', 'Doan Tuan Kiet', 'Male', 0, '', Colors.green),
      _student('HE170950', 'Nguyen Hoang Long', 'Male', 2, '', Colors.blueGrey),
      _student('HE171012', 'Bui Mai Phuong', 'Female', 4, 'Consecutive absence 3rd time', Colors.pink, present: false),
    ];
  }

  @override
  Future<void> saveAttendance(String sessionId, List<AttendanceStudent> students, {required bool submitted}) async {}

  @override
  Future<SeedSummary> seedSampleData() async => const SeedSummary(subjectCount: 0, classCount: 0, studentsAdded: 0, sessionsAdded: 0, attendanceAdded: 0);

  AttendanceStudent _student(String rollNo, String name, String gender, int absences, String note, Color color, {bool present = true}) => AttendanceStudent(
        rollNo: rollNo,
        fullName: name,
        major: 'SE - Software Engineering',
        gender: gender,
        previousAbsences: absences,
        totalSessions: 14,
        note: note,
        avatarColor: color,
        status: present ? AttendanceState.present : AttendanceState.absent,
      );
}

class GoogleSheetsAttendanceRepository implements AttendanceRepository {
  final GoogleSheetService service;
  List<AttendanceSession> _sessions = const [];

  GoogleSheetsAttendanceRepository(this.service);

  @override
  Future<List<AttendanceSession>> getSessions() async {
    final rows = await service.getSchedule();
    _sessions = rows.map(_toSession).toList();
    return _sessions;
  }

  @override
  Future<List<AttendanceStudent>> studentsForSession(String sessionId) async {
    final session = _sessions.firstWhere((item) => item.id == sessionId);
    final students = await service.getStudentsByClass(session.className);
    final attendance = await service.getAllAttendance();
    final pastSessionIds = _sessions.where((item) => item.className == session.className && item.sessionNumber < session.sessionNumber).map((item) => item.id).toSet();
    final currentAttendance = attendance.where((row) => row.sessionId == sessionId);
    final byStudent = {for (final row in currentAttendance) row.studentId: row};
    return students.map((student) {
      final row = byStudent[student.studentId];
      final previousRows = attendance.where((item) => item.studentId == student.studentId && pastSessionIds.contains(item.sessionId));
      final previousAbsences = previousRows.where((item) => item.status == 'absent').length;
      return AttendanceStudent(
        studentId: student.studentId,
        rollNo: student.studentCode.isEmpty ? student.studentId : student.studentCode,
        fullName: student.fullName,
        major: student.major,
        gender: student.gender,
        previousAbsences: previousAbsences,
        totalSessions: pastSessionIds.length,
        note: row?.note ?? '',
        avatarColor: _avatarColor(student.studentId),
        status: row?.status == 'absent' ? AttendanceState.absent : AttendanceState.present,
      );
    }).toList();
  }

  @override
  Future<void> saveAttendance(String sessionId, List<AttendanceStudent> students, {required bool submitted}) async {
    for (final student in students) {
      await service.upsertAttendance(
        sessionId: sessionId,
        studentId: student.studentId.isEmpty ? student.rollNo : student.studentId,
        status: student.status == AttendanceState.present ? 'present' : 'absent',
        note: student.note,
        syncStatus: submitted ? 'submitted' : 'draft',
      );
    }
  }

  @override
  Future<SeedSummary> seedSampleData() => service.seedSampleData();

  AttendanceSession _toSession(SheetScheduleRow row) => AttendanceSession(
        id: row.sessionId,
        subjectCode: row.subjectCode,
        subjectName: row.subjectName,
        className: row.classCode,
        schedule: row.slot,
        room: row.room,
        date: row.sessionDate,
        sessionNumber: row.sessionNo,
        totalSessions: row.totalSessions,
        accentColor: _accentColor(row.subjectCode),
      );

  Color _accentColor(String value) => Color((value.hashCode & 0x00FFFFFF) | 0xFF000000);

  Color _avatarColor(String value) => Colors.primaries[value.hashCode.abs() % Colors.primaries.length];
}