import 'package:flutter/material.dart';
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
  List<AttendanceSession> get sessions;

  List<AttendanceStudent> studentsForSession(String sessionId);
}

class MockAttendanceRepository implements AttendanceRepository {
  @override
  final List<AttendanceSession> sessions = const [
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
  List<AttendanceStudent> studentsForSession(String sessionId) {
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