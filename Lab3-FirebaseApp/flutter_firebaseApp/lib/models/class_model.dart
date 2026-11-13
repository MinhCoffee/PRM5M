class ClassModel {
  final String classId;
  final String classCode;
  final String subject;
  final String lecturer;

  const ClassModel({
    required this.classId,
    required this.classCode,
    required this.subject,
    required this.lecturer,
  });

  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      classId: _value(map, 'class_id', 'ClassID'),
      classCode: _value(map, 'class_code', 'ClassCode'),
      subject: _value(map, 'subject', 'Subject'),
      lecturer: _value(map, 'lecturer', 'Lecturer'),
    );
  }

  Map<String, String> toMap() => {
        'class_id': classId,
        'class_code': classCode,
        'subject': subject,
        'lecturer': lecturer,
      };

  static String _value(Map<String, dynamic> map, String key, String legacyKey) {
    return map[key]?.toString().trim().isNotEmpty == true
        ? map[key].toString().trim()
        : map[legacyKey]?.toString().trim() ?? '';
  }
}
