import 'dart:async';
import 'dart:convert';
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

enum StorageFailureKind { notSignedIn, permissionDenied, network, unknown }

/// Upload/list failure with a message that is safe to show to the user.
class StorageFailure implements Exception {
  final StorageFailureKind kind;
  final String userMessage;
  final Object? cause;

  const StorageFailure(this.kind, this.userMessage, {this.cause});

  @override
  String toString() => 'StorageFailure(${kind.name}): $userMessage';
}

abstract interface class IStorageService {
  /// Uploads a CSV report to `reports/{uid}/{fileName}`.
  /// [onProgress] receives values in 0.0..1.0 while bytes are transferred.
  /// Throws [StorageFailure]; never fabricates a download URL.
  Future<StorageUploadResult> uploadReport({
    required String fileName,
    required String content,
    required String classCode,
    void Function(double progress)? onProgress,
  });

  /// Lists the signed-in user's real files in Cloud Storage.
  Future<List<StorageUploadResult>> getUploadedReports();
}

class FirebaseStorageService implements IStorageService {
  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String _requireUid() {
    if (!_isFirebaseReady) {
      throw const StorageFailure(
        StorageFailureKind.unknown,
        'Firebase chưa được khởi tạo, không thể tải lên Cloud Storage.',
      );
    }
    final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw const StorageFailure(
        StorageFailureKind.notSignedIn,
        'Bạn cần đăng nhập để tải báo cáo lên Cloud Storage.',
      );
    }
    return uid;
  }

  StorageFailure _map(Object e) {
    if (e is StorageFailure) return e;
    if (e is FirebaseException) {
      switch (e.code) {
        case 'unauthorized':
        case 'unauthenticated':
          return StorageFailure(
            StorageFailureKind.permissionDenied,
            'Không có quyền truy cập tệp này (storage.rules từ chối).',
            cause: e,
          );
        case 'retry-limit-exceeded':
        case 'network-request-failed':
          return StorageFailure(
            StorageFailureKind.network,
            'Mất kết nối mạng, tải lên không hoàn tất. Kiểm tra mạng rồi thử lại.',
            cause: e,
          );
      }
    }
    if (e is TimeoutException) {
      return StorageFailure(
        StorageFailureKind.network,
        'Hết thời gian chờ khi tải lên. Kiểm tra mạng rồi thử lại.',
        cause: e,
      );
    }
    return StorageFailure(
      StorageFailureKind.unknown,
      'Tải lên thất bại: $e',
      cause: e,
    );
  }

  @override
  Future<StorageUploadResult> uploadReport({
    required String fileName,
    required String content,
    required String classCode,
    void Function(double progress)? onProgress,
  }) async {
    final data = Uint8List.fromList(utf8.encode(content));
    final timestamp = DateTime.now();

    try {
      final uid = _requireUid();
      // Must match storage.rules: match /reports/{uid}/{allPaths=**}
      final storagePath = 'reports/$uid/$fileName';

      FirebaseEvidenceLogger.log(
        service: 'Cloud Storage',
        action: 'Uploading file to storage bucket',
        payload: {
          'path': storagePath,
          'bytes': data.length,
          'classCode': classCode,
        },
      );

      final ref = FirebaseStorage.instance.ref(storagePath);
      final task = ref.putData(
        data,
        SettableMetadata(
          contentType: 'text/csv',
          customMetadata: {
            'classCode': classCode,
            'uploadedAt': timestamp.toIso8601String(),
          },
        ),
      );

      final sub = task.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      });

      try {
        await task.timeout(const Duration(seconds: 60));
      } on TimeoutException {
        // timeout() does not stop the transfer; cancel so a retry cannot race it.
        await task.cancel();
        rethrow;
      } finally {
        await sub.cancel();
      }
      onProgress?.call(1.0);

      final downloadUrl = await ref.getDownloadURL();
      final result = StorageUploadResult(
        fileName: fileName,
        storagePath: storagePath,
        downloadUrl: downloadUrl,
        bytes: data.length,
        uploadedAt: timestamp,
      );

      FirebaseEvidenceLogger.log(
        service: 'Cloud Storage',
        action: 'Upload completed successfully',
        payload: {
          'downloadUrl': downloadUrl,
          'path': storagePath,
          'sizeBytes': data.length,
        },
        isSuccess: true,
      );
      return result;
    } catch (e) {
      final failure = _map(e);
      FirebaseEvidenceLogger.log(
        service: 'Cloud Storage',
        action: 'Upload failed (${failure.kind.name})',
        payload: {'fileName': fileName},
        isSuccess: false,
        errorMessage: failure.userMessage,
      );
      throw failure;
    }
  }

  @override
  Future<List<StorageUploadResult>> getUploadedReports() async {
    try {
      final uid = _requireUid();
      final listing = await FirebaseStorage.instance.ref('reports/$uid').listAll();
      final results = <StorageUploadResult>[];
      for (final item in listing.items.take(50)) {
        final meta = await item.getMetadata();
        results.add(
          StorageUploadResult(
            fileName: item.name,
            storagePath: item.fullPath,
            downloadUrl: await item.getDownloadURL(),
            bytes: meta.size ?? 0,
            uploadedAt: meta.timeCreated ?? DateTime.now(),
          ),
        );
      }
      results.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return results;
    } catch (e) {
      throw _map(e);
    }
  }
}
