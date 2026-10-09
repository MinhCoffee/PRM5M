class AttendanceSession {
  final String sessionId;
  final String classId;
  final DateTime date;
  final String startTime;
  final String endTime;

  const AttendanceSession({
    required this.sessionId,
    required this.classId,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  factory AttendanceSession.fromMap(Map<String, dynamic> map) {
    final rawDate = map['date'] ?? map['Date'] ?? '';
    return AttendanceSession(
      sessionId: _value(map, 'session_id', 'SessionID'),
      classId: _value(map, 'class_id', 'ClassID'),
      date: DateTime.tryParse(rawDate.toString()) ?? DateTime.now(),
      startTime: _value(map, 'start_time', 'StartTime'),
      endTime: _value(map, 'end_time', 'EndTime'),
    );
  }

  Map<String, String> toMap() => {
        'session_id': sessionId,
        'class_id': classId,
        'date': date.toIso8601String().substring(0, 10),
        'start_time': startTime,
        'end_time': endTime,
      };

  static String _value(Map<String, dynamic> map, String key, String legacyKey) {
    return map[key]?.toString().trim().isNotEmpty == true
        ? map[key].toString().trim()
        : map[legacyKey]?.toString().trim() ?? '';
  }
}
