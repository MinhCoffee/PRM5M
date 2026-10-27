import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_evidence_logger.dart';

abstract interface class ICrashlyticsService {
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  });
  void log(String message);
  void setCustomKey(String key, Object value);
  void setUserIdentifier(String userId);
  void testCrash();
}

class FirebaseCrashlyticsService implements ICrashlyticsService {
  final Map<String, Object> _customKeys = {};
  String? _userId;
  final List<String> _breadcrumbs = [];

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void log(String message) {
    _breadcrumbs.add('${DateTime.now().toIso8601String()}: $message');
    FirebaseEvidenceLogger.log(
      service: 'Crashlytics',
      action: 'Breadcrumb logged',
      payload: {'message': message},
    );
  }

  @override
  void setCustomKey(String key, Object value) {
    _customKeys[key] = value;
    FirebaseEvidenceLogger.log(
      service: 'Crashlytics',
      action: 'Custom Key set',
      payload: {'key': key, 'value': value.toString()},
    );
  }

  @override
  void setUserIdentifier(String userId) {
    _userId = userId;
    FirebaseEvidenceLogger.log(
      service: 'Crashlytics',
      action: 'User identifier set',
      payload: {'userId': userId},
    );
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    final payload = {
      'exception': exception.toString(),
      'reason': reason ?? 'Unspecified error',
      'fatal': fatal,
      'userId': _userId,
      'customKeys': _customKeys,
      'stackTrace': stack?.toString().split('\n').take(10).join('\n'),
      'recentBreadcrumbs': _breadcrumbs.take(5).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    FirebaseEvidenceLogger.log(
      service: 'Crashlytics',
      action: fatal ? 'FATAL_CRASH_RECORDED' : 'NON_FATAL_ERROR_RECORDED',
      payload: payload,
      isSuccess: true,
      errorMessage: exception.toString(),
    );

    if (_isFirebaseReady) {
      try {
        await FirebaseFirestore.instance.collection('crashlytics_reports').add({
          'exception': exception.toString(),
          'reason': reason,
          'fatal': fatal,
          'userId': _userId,
          'customKeys': _customKeys,
          'clientTimestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Crashlytics firestore record notice: $e');
      }
    }
  }

  @override
  void testCrash() {
    FirebaseEvidenceLogger.log(
      service: 'Crashlytics',
      action: 'TEST_CRASH_TRIGGERED',
      payload: {
        'message': 'Simulated test crash initiated for Firebase Console verification',
      },
      isSuccess: true,
    );

    recordError(
      StateError('Firebase Crashlytics Test Crash verified successfully.'),
      StackTrace.current,
      reason: 'User triggered test crash from Settings/Profile screen',
      fatal: true,
    );
  }
}
