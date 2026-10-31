import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_evidence_logger.dart';

abstract interface class IAnalyticsService {
  Future<void> setUserId(String? userId);
  Future<void> logScreenView(String screenName);
  Future<void> logLogin(String method);
  Future<void> logAttendanceMarked({
    required String sessionId,
    required int presentCount,
    required int absentCount,
  });
  Future<void> logAttendanceSubmitted({
    required String sessionId,
    required String classCode,
  });
  Future<void> logExportReport({
    required String classCode,
    required String fileType,
  });
  Future<void> logFilterChanged({
    required String filterType,
    required String value,
  });
  Future<void> logEvent(String name, [Map<String, Object>? parameters]);
}

class FirebaseAnalyticsService implements IAnalyticsService {
  final List<Map<String, dynamic>> _eventsLog = [];

  List<Map<String, dynamic>> get recordedEvents => List.unmodifiable(_eventsLog);

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    FirebaseEvidenceLogger.log(
      service: 'Analytics',
      action: 'Set User ID: $userId',
      payload: {'userId': userId ?? 'null'},
    );

    if (_isFirebaseReady) {
      try {
        await FirebaseAnalytics.instance.setUserId(id: userId);
      } catch (e) {
        debugPrint('Firebase Analytics setUserId error: $e');
      }
    }
  }

  @override
  Future<void> logScreenView(String screenName) async {
    if (_isFirebaseReady) {
      try {
        await FirebaseAnalytics.instance.logScreenView(screenName: screenName);
      } catch (e) {
        debugPrint('Firebase Analytics logScreenView error: $e');
      }
    }
    await logEvent('screen_view', {'screen_name': screenName});
  }

  @override
  Future<void> logLogin(String method) async {
    if (_isFirebaseReady) {
      try {
        await FirebaseAnalytics.instance.logLogin(loginMethod: method);
      } catch (e) {
        debugPrint('Firebase Analytics logLogin error: $e');
      }
    }
    await logEvent('login', {'method': method});
  }

  @override
  Future<void> logAttendanceMarked({
    required String sessionId,
    required int presentCount,
    required int absentCount,
  }) async {
    await logEvent('attendance_marked', {
      'session_id': sessionId,
      'present_count': presentCount,
      'absent_count': absentCount,
    });
  }

  @override
  Future<void> logAttendanceSubmitted({
    required String sessionId,
    required String classCode,
  }) async {
    await logEvent('attendance_submitted', {
      'session_id': sessionId,
      'class_code': classCode,
    });
  }

  @override
  Future<void> logExportReport({
    required String classCode,
    required String fileType,
  }) async {
    await logEvent('export_report', {
      'class_code': classCode,
      'file_type': fileType,
    });
  }

  @override
  Future<void> logFilterChanged({
    required String filterType,
    required String value,
  }) async {
    await logEvent('filter_changed', {
      'filter_type': filterType,
      'filter_value': value,
    });
  }

  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    final eventRecord = {
      'event': name,
      'parameters': parameters ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    };
    _eventsLog.add(eventRecord);

    FirebaseEvidenceLogger.log(
      service: 'Analytics',
      action: 'Event logged: $name',
      payload: eventRecord,
    );

    if (_isFirebaseReady) {
      try {
        // Log to official Firebase Analytics SDK
        await FirebaseAnalytics.instance.logEvent(
          name: name,
          parameters: parameters,
        );
      } catch (e) {
        debugPrint('Firebase Analytics logEvent error: $e');
      }

      try {
        await FirebaseFirestore.instance.collection('analytics_events').add({
          'eventName': name,
          'params': parameters ?? {},
          'clientTimestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Analytics firestore record notice: $e');
      }
    }
  }
}
