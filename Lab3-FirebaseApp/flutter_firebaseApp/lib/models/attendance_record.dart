class AttendanceRecord {
  final String sessionId;
  final DateTime date;
  final String classId;
  final String studentId;
  final String status; // "Present" / "Absent"
  final String note;

  AttendanceRecord({
    required this.sessionId,
    required this.date,
    required this.classId,
    required this.studentId,
    required this.status,
    this.note = '',
  });

  Map<String, String> toMap() {
    return {
      'SessionID': sessionId,
      'Date': date.toIso8601String().substring(0, 10),
      'ClassID': classId,
      'StudentID': studentId,
      'Status': status,
      'Note': note,
    };
  }
}
