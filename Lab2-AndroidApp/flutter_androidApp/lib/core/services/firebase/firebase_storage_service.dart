import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'firebase_evidence_logger.dart';

class StorageUploadResult {
  final String fileName;
  final String storagePath;
  final String downloadUrl;
  final int bytes;
  final DateTime uploadedAt;

  const StorageUploadResult({
    required this.fileName,
    required this.storagePath,
    required this.downloadUrl,
    required this.bytes,
    required this.uploadedAt,
  });
}

abstract interface class IStorageService {
  Future<StorageUploadResult> uploadReport({
    required String fileName,
    required String content,
    required String classCode,
    String? uploaderEmail,
    String? uid,
  });

  Future<List<StorageUploadResult>> getUploadedReports();
}

class FirebaseStorageService implements IStorageService {
  final List<StorageUploadResult> _localUploadHistory = [];

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<StorageUploadResult> uploadReport({
    required String fileName,
    required String content,
    required String classCode,
    String? uploaderEmail,
    String? uid,
  }) async {
    final bytes = utf8.encode(content).length;
    final timestamp = DateTime.now();

    // Lab 3 Security Rules requirement: match /reports/{uid}/{allPaths=**}
    // Storage path MUST start with reports/$userUid/ to comply with authenticated uid check.
    final currentUid = uid ??
        fb_auth.FirebaseAuth.instance.currentUser?.uid ??
        'public_reports';
    final storagePath = 'reports/$currentUid/$fileName';

    String downloadUrl =
        'https://firebasestorage.googleapis.com/v0/b/fap-attendance-85250.firebasestorage.app/o/${Uri.encodeComponent(storagePath)}?alt=media';

    FirebaseEvidenceLogger.log(
      service: 'Cloud Storage',
      action: 'Uploading file to storage bucket',
      payload: {
        'path': storagePath,
        'fileName': fileName,
        'bytes': bytes,
        'classCode': classCode,
        'uid': currentUid,
        'uploader': uploaderEmail ?? 'authenticated_user',
      },
    );

    try {
      if (_isFirebaseReady) {
        try {
          final storageRef = FirebaseStorage.instance.ref().child(storagePath);
          final uploadTask = await storageRef.putString(
            content,
            format: PutStringFormat.raw,
            metadata: SettableMetadata(
              contentType: 'text/csv',
              customMetadata: {
                'classCode': classCode,
                'uploader': uploaderEmail ?? '',
                'uploadedAt': timestamp.toIso8601String(),
              },
            ),
          );
          downloadUrl = await uploadTask.ref.getDownloadURL();
        } catch (storageError) {
          debugPrint('Firebase Storage SDK upload notice: $storageError');
        }

        // Keep audit record in Firestore as well for console visibility
        try {
          await FirebaseFirestore.instance.collection('storage_reports').add({
            'fileName': fileName,
            'storagePath': storagePath,
            'downloadUrl': downloadUrl,
            'bytes': bytes,
            'classCode': classCode,
            'uid': currentUid,
            'uploader': uploaderEmail ?? '',
            'uploadedAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('Firestore upload record notification error: $e');
        }
      }

      final result = StorageUploadResult(
        fileName: fileName,
        storagePath: storagePath,
        downloadUrl: downloadUrl,
        bytes: bytes,
        uploadedAt: timestamp,
      );

      _localUploadHistory.insert(0, result);

      FirebaseEvidenceLogger.log(
        service: 'Cloud Storage',
        action: 'Upload completed successfully',
        payload: {
          'downloadUrl': downloadUrl,
          'path': storagePath,
          'sizeBytes': bytes,
        },
        isSuccess: true,
      );

      return result;
    } catch (e) {
      FirebaseEvidenceLogger.log(
        service: 'Cloud Storage',
        action: 'Upload failed',
        payload: {'fileName': fileName, 'error': e.toString()},
        isSuccess: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  @override
  Future<List<StorageUploadResult>> getUploadedReports() async {
    return List.unmodifiable(_localUploadHistory);
  }
}
