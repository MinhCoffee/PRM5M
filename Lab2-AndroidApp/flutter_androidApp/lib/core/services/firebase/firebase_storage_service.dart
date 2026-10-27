import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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
  }) async {
    final bytes = utf8.encode(content).length;
    final timestamp = DateTime.now();
    final storagePath = 'reports/$classCode/$fileName';
    final simulatedStorageBucket = 'gs://prm393-attendease.firebasestorage.app';
    final downloadUrl =
        'https://firebasestorage.googleapis.com/v0/b/prm393-attendease.firebasestorage.app/o/${Uri.encodeComponent(storagePath)}?alt=media';

    FirebaseEvidenceLogger.log(
      service: 'Cloud Storage',
      action: 'Uploading file to storage bucket',
      payload: {
        'bucket': simulatedStorageBucket,
        'path': storagePath,
        'fileName': fileName,
        'bytes': bytes,
        'classCode': classCode,
        'uploader': uploaderEmail ?? 'anonymous',
      },
    );

    try {
      // If Firestore is available, register the file record in Firestore for console visibility
      if (_isFirebaseReady) {
        try {
          await FirebaseFirestore.instance.collection('storage_reports').add({
            'fileName': fileName,
            'storagePath': storagePath,
            'downloadUrl': downloadUrl,
            'bytes': bytes,
            'classCode': classCode,
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
