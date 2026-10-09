class Student {
  final String studentId;
  final String studentCode;
  final String studentName;
  final String classId;
  final String email;
  final String gender;
  final String major;
  final String photoUrl;

  Student({
    required this.studentId,
    this.studentCode = '',
    required this.studentName,
    required this.classId,
    required this.email,
    this.gender = '',
    this.major = '',
    this.photoUrl = '',
  });

  String get fullName => studentName;

  Map<String, String> toMap() {
    return {
      'student_id': studentId,
      'student_code': studentCode.isEmpty ? studentId : studentCode,
      'full_name': fullName,
      'email': email,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      studentId: _value(map, 'student_id', 'StudentID'),
      studentCode: _value(map, 'student_code', 'StudentCode'),
      studentName: _value(map, 'full_name', 'StudentName'),
      classId: _value(map, 'class_code', 'ClassID'),
      email: _value(map, 'email', 'Email'),
      gender: map['gender']?.toString().trim() ?? '',
      major: map['major']?.toString().trim() ?? '',
      photoUrl: map['photo_url']?.toString().trim() ?? '',
    );
  }

  static String _value(Map<String, dynamic> map, String key, String legacyKey) {
    return map[key]?.toString().trim().isNotEmpty == true
        ? map[key].toString().trim()
        : map[legacyKey]?.toString().trim() ?? '';
  }
}
