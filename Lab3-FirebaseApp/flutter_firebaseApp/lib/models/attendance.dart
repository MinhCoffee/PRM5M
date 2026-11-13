enum AttendanceStatus { present, late, absent }

extension AttendanceStatusCodec on AttendanceStatus {
  String get value {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.absent:
        return 'Absent';
    }
  }

  static AttendanceStatus parse(String value) {
    switch (value.trim().toLowerCase()) {
      case 'late':
        return AttendanceStatus.late;
      case 'absent':
        return AttendanceStatus.absent;
      default:
        return AttendanceStatus.present;
    }
  }
}

class Attendance {
  final String attendanceId;
  final String sessionId;
  final String studentId;
  final String studentCode;
  final DateTime date;
  final DateTime? checkInTime;
  final AttendanceStatus status;

  const Attendance({
    required this.attendanceId,
    required this.sessionId,
    required this.studentId,
    required this.studentCode,
    required this.date,
    required this.checkInTime,
    required this.status,
  });

  factory Attendance.fromMap(Map<String, dynamic> map) {
    final rawDate = map['date'] ?? map['Date'] ?? '';
    final rawCheckIn = map['check_in_time'] ?? map['CheckInTime'];
    return Attendance(
      attendanceId: _value(map, 'attendance_id', 'AttendanceID'),
      sessionId: _value(map, 'session_id', 'SessionID'),
      studentId: _value(map, 'student_id', 'StudentID'),
      studentCode: _value(map, 'student_code', 'StudentCode'),
      date: DateTime.tryParse(rawDate.toString()) ?? DateTime.now(),
      checkInTime: rawCheckIn == null || rawCheckIn.toString().isEmpty
          ? null
          : DateTime.tryParse(rawCheckIn.toString()),
      status: AttendanceStatusCodec.parse(_value(map, 'status', 'Status')),
    );
  }

  Map<String, String> toMap() => {
        'attendance_id': attendanceId,
        'session_id': sessionId,
        'student_id': studentId,
        'student_code': studentCode,
        'date': date.toIso8601String().substring(0, 10),
        'check_in_time': checkInTime?.toIso8601String() ?? '',
        'status': status.value,
      };

  static String _value(Map<String, dynamic> map, String key, String legacyKey) {
    return map[key]?.toString().trim().isNotEmpty == true
        ? map[key].toString().trim()
        : map[legacyKey]?.toString().trim() ?? '';
  }
}
