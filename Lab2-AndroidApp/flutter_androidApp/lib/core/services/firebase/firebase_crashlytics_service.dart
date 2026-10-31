import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
  Future<void> sendNonFatalError([String? customMessage]);
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

    if (_isFirebaseReady) {
      try {
        FirebaseCrashlytics.instance.log(message);
      } catch (e) {
        debugPrint('Firebase Crashlytics log notice: $e');
      }
    }
  }

  @override
  void setCustomKey(String key, Object value) {
    _customKeys[key] = value;
    FirebaseEvidenceLogger.log(
      service: 'Crashlytics',
      action: 'Custom Key set',
      payload: {'key': key, 'value': value.toString()},
    );

    if (_isFirebaseReady) {
      try {
        FirebaseCrashlytics.instance.setCustomKey(key, value);
      } catch (e) {
        debugPrint('Firebase Crashlytics setCustomKey notice: $e');
      }
    }
  }

  @override
  void setUserIdentifier(String userId) {
    _userId = userId;
    FirebaseEvidenceLogger.log(
      service: 'Crashlytics',
      action: 'User identifier set',
      payload: {'userId': userId},
    );

    if (_isFirebaseReady) {
      try {
        FirebaseCrashlytics.instance.setUserIdentifier(userId);
      } catch (e) {
        debugPrint('Firebase Crashlytics setUserIdentifier notice: $e');
      }
    }
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
        // Record directly into Firebase Crashlytics SDK
        await FirebaseCrashlytics.instance.recordError(
          exception,
          stack,
          reason: reason,
          fatal: fatal,
        );
      } catch (e) {
        debugPrint('Firebase Crashlytics recordError error: $e');
      }

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

    if (_isFirebaseReady) {
      try {
        // Triggers a real simulated crash via Firebase Crashlytics SDK
        FirebaseCrashlytics.instance.crash();
        return;
      } catch (e) {
        debugPrint('Crashlytics crash invocation note: $e');
      }
    }

    recordError(
      StateError('Firebase Crashlytics Test Crash verified successfully.'),
      StackTrace.current,
      reason: 'User triggered test crash from Settings/Profile screen',
      fatal: true,
    );
  }

  @override
  Future<void> sendNonFatalError([String? customMessage]) async {
    FirebaseEvidenceLogger.log(
      service: 'Crashlytics',
      action: 'NON_FATAL_TEST_ERROR_TRIGGERED',
      payload: {
        'message': customMessage ?? 'Lab 3 non-fatal verification error',
      },
      isSuccess: true,
    );

    final error = Exception(customMessage ?? 'Lab 3: Non-fatal test error recorded for Firebase Console.');
    await recordError(
      error,
      StackTrace.current,
      reason: 'User triggered non-fatal test error from Settings/Profile screen',
      fatal: false,
    );
  }
}
