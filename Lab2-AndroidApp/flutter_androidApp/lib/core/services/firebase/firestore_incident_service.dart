import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'firebase_auth_service.dart';
import 'firebase_evidence_logger.dart';

/// What the admin web page shows in its "Sự cố ứng dụng" tab.
enum IncidentType {
  /// Written right before the intentional test crash (the app then dies).
  testCrashTriggered('test_crash_triggered'),

  /// Written on the next launch, only when the Crashlytics SDK reports that
  /// the previous run really crashed (`didCrashOnPreviousExecution`).
  crashConfirmed('crash_confirmed'),

  /// A handled error sent to Crashlytics as non-fatal.
  nonFatal('non_fatal');

  final String wire;
  const IncidentType(this.wire);
}

/// Forwards incidents to Firestore so the admin web can watch them live.
/// Stack traces stay in Crashlytics; only a summary and the Firebase uid go
/// here (no email, name or student data).
abstract interface class IIncidentService {
  /// Never throws: reporting must not cause a second failure.
  Future<void> report(IncidentType type, {String message = ''});

  /// If the previous run crashed, records [IncidentType.crashConfirmed].
  Future<void> reportPreviousCrashIfAny();
}

class FirestoreIncidentService implements IIncidentService {
  FirestoreIncidentService(this._auth);

  final IAuthService _auth;

  bool get _ready {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> report(IncidentType type, {String message = ''}) async {
    if (!_ready) return;
    try {
      // Wait briefly for a restored session; skip if nobody is signed in.
      final uid = _auth.currentUser?.id ??
          (await _auth.authStateChanges
                  .firstWhere((u) => u != null)
                  .timeout(const Duration(seconds: 3)))
              ?.id;
      if (uid == null) return;

      final write = FirebaseFirestore.instance.collection('incidents').add({
        'uid': uid,
        'type': type.wire,
        'fatal': type != IncidentType.nonFatal,
        'message': message.length > 200 ? message.substring(0, 200) : message,
        'platform': defaultTargetPlatform.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Offline writes are queued by the SDK and sent on the next launch, so
      // the wait is bounded: right before a crash we cannot wait for the ack.
      await write.timeout(const Duration(seconds: 2));
      FirebaseEvidenceLogger.log(
        service: 'Firestore',
        action: 'INCIDENT_REPORTED',
        payload: {'type': type.wire},
        isSuccess: true,
      );
    } on TimeoutException {
      debugPrint('Incident ${type.wire} queued (no ack within timeout).');
    } catch (e) {
      debugPrint('Incident report failed: $e');
    }
  }

  @override
  Future<void> reportPreviousCrashIfAny() async {
    if (!_ready) return;
    try {
      final crashed =
          await FirebaseCrashlytics.instance.didCrashOnPreviousExecution();
      if (crashed) {
        await report(
          IncidentType.crashConfirmed,
          message: 'Crashlytics: previous run ended in a crash',
        );
      }
    } catch (e) {
      debugPrint('Previous-crash check failed: $e');
    }
  }
}
