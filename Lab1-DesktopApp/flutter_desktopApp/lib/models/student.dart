class Student {
  final String studentId;
  final String studentName;
  final String classId;
  final String email;

  Student({
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.email,
  });

  String get studentCode => studentId;
  String get fullName => studentName;

  Map<String, String> toMap() {
    return {
      'student_id': studentId,
      'student_code': studentCode,
      'full_name': fullName,
      'email': email,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      studentId: _value(map, 'student_id', 'StudentID'),
      studentName: _value(map, 'full_name', 'StudentName'),
      classId: _value(map, 'class_id', 'ClassID'),
      email: _value(map, 'email', 'Email'),
    );
  }

  static String _value(Map<String, dynamic> map, String key, String legacyKey) {
    return map[key]?.toString().trim().isNotEmpty == true
        ? map[key].toString().trim()
        : map[legacyKey]?.toString().trim() ?? '';
  }
}
