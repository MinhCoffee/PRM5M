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

/// Outcome of one [IIncidentService.report] call, shown to the tester so a
/// silent failure on someone else's phone is visible on screen.
class IncidentResult {
  final bool delivered;
  final String message;
  const IncidentResult(this.delivered, this.message);
}

/// Forwards incidents to Firestore so the admin web can watch them live.
/// Stack traces stay in Crashlytics; only a summary and the Firebase uid go
/// here (no email, name or student data).
abstract interface class IIncidentService {
  /// Never throws: reporting must not cause a second failure.
  Future<IncidentResult> report(IncidentType type, {String message = ''});

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
  Future<IncidentResult> report(IncidentType type,
      {String message = ''}) async {
    if (!_ready) {
      return const IncidentResult(false, 'Firebase chưa khởi tạo trên máy này.');
    }
    try {
      // Wait briefly for a restored session; skip if nobody is signed in.
      String? uid = _auth.currentUser?.id;
      if (uid == null) {
        try {
          uid = (await _auth.authStateChanges
                  .firstWhere((u) => u != null)
                  .timeout(const Duration(seconds: 3)))
              ?.id;
        } on TimeoutException {
          uid = null;
        }
      }
      if (uid == null) {
        return const IncidentResult(
            false, 'Chưa có phiên đăng nhập Firebase (không có uid), không gửi được.');
      }

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
      return const IncidentResult(true, 'Đã gửi sự cố lên Firestore (admin sẽ thấy).');
    } on TimeoutException {
      debugPrint('Incident ${type.wire} queued (no ack within timeout).');
      return const IncidentResult(
          false, 'Chưa nhận được xác nhận từ Firestore (mạng chậm/offline?). Đã xếp hàng chờ gửi.');
    } catch (e) {
      debugPrint('Incident report failed: $e');
      return IncidentResult(false, 'Gửi sự cố thất bại: $e');
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
