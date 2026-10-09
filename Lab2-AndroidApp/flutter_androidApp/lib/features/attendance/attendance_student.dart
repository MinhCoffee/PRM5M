import 'package:flutter/material.dart';

enum AttendanceState { present, absent }

class AttendanceStudent {
  final String studentId;
  final String rollNo;
  final String fullName;
  final String major;
  final String gender;
  final int previousAbsences;
  final int totalSessions;
  String note;
  final Color avatarColor;
  AttendanceState status;

  AttendanceStudent({
    this.studentId = '',
    required this.rollNo,
    required this.fullName,
    required this.major,
    required this.gender,
    required this.previousAbsences,
    required this.totalSessions,
    required this.note,
    required this.avatarColor,
    required this.status,
  });

  int get cumulativeAbsences => previousAbsences + (status == AttendanceState.absent ? 1 : 0);

  int get cumulativeSessions => totalSessions + 1;

  double get absenceRate => cumulativeAbsences / cumulativeSessions;
}