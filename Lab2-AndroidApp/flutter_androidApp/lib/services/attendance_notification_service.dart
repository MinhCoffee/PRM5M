import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'attendance_stats_service.dart';

class AttendanceNotificationDispatch {
  final int sentCount;
  final int pendingCount;

  const AttendanceNotificationDispatch({
    required this.sentCount,
    required this.pendingCount,
  });
}

class AttendanceNotificationService {
  static const _sentEventsKey = 'attendance_notification_events';

  Future<AttendanceNotificationDispatch> dispatch({
    required List<MissingAttendanceSession> missingSessions,
    required List<AttendanceStudentStats> riskRows,
  }) async {
    final endpoint = dotenv.env['ATTENDANCE_NOTIFICATION_ENDPOINT']?.trim();
    final teacherEmail = dotenv.env['ATTENDANCE_TEACHER_EMAIL']?.trim() ?? '';
    final recipients = riskRows
        .where((row) => row.student.email.trim().isNotEmpty)
        .map(
          (row) => {
            'email': row.student.email.trim(),
            'student_id': row.student.studentId,
            'student_code': row.student.studentCode,
            'full_name': row.student.fullName,
            'status': row.status.value,
            'absence_rate': row.absenceRate,
            'absent_count': row.absentCount,
            'sessions_held': row.sessionsHeld,
          },
        )
        .toList();
    if (recipients.isEmpty) {
      return const AttendanceNotificationDispatch(sentCount: 0, pendingCount: 0);
    }

    final prefs = await SharedPreferences.getInstance();
    final sentEvents = prefs.getStringList(_sentEventsKey)?.toSet() ?? {};
    final newRecipients = recipients.where((recipient) {
      final eventKey = _eventKey(recipient);
      return !sentEvents.contains(eventKey);
    }).toList();
    if (newRecipients.isEmpty) {
      return const AttendanceNotificationDispatch(sentCount: 0, pendingCount: 0);
    }
    if (endpoint == null || endpoint.isEmpty) {
      return AttendanceNotificationDispatch(
        sentCount: 0,
        pendingCount: newRecipients.length,
      );
    }

    final response = await http.post(
      Uri.parse(endpoint),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'type': 'attendance_risk_alert',
        'teacher_email': teacherEmail,
        'recipients': newRecipients,
        'missing_sessions': missingSessions
            .map(
              (item) => {
                'session_id': item.session.sessionId,
                'subject_code': item.session.subjectCode,
                'class_code': item.session.classCode,
                'session_date': item.session.sessionDate,
                'status': item.status.value,
              },
            )
            .toList(),
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Notification endpoint returned HTTP ${response.statusCode}.',
      );
    }
    sentEvents.addAll(newRecipients.map(_eventKey));
    await prefs.setStringList(_sentEventsKey, sentEvents.toList());
    return AttendanceNotificationDispatch(
      sentCount: newRecipients.length,
      pendingCount: 0,
    );
  }

  String _eventKey(Map<String, dynamic> recipient) =>
      '${recipient['student_id']}:${recipient['status']}:${recipient['absence_rate']}';
}