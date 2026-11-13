import 'package:flutter/foundation.dart';

class FirebaseEvidenceLogger {
  static final List<Map<String, dynamic>> _auditLogs = [];

  static List<Map<String, dynamic>> get auditLogs => List.unmodifiable(_auditLogs);

  static void log({
    required String service,
    required String action,
    required Map<String, dynamic> payload,
    bool isSuccess = true,
    String? errorMessage,
  }) {
    final record = {
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'service': service,
      'action': action,
      'payload': payload,
      'success': isSuccess,
      if (errorMessage != null) 'error': errorMessage,
    };
    _auditLogs.add(record);

    debugPrint(
      '🔥 [Firebase Evidence: $service] $action | success=$isSuccess | ${payload.toString()}${errorMessage != null ? " | ERROR: $errorMessage" : ""}',
    );
  }

  static void clear() {
    _auditLogs.clear();
  }
}
