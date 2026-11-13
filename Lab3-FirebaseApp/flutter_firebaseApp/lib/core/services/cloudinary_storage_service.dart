import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase/firebase_evidence_logger.dart';
import 'storage_service.dart';

/// Stores exported CSV reports in Cloudinary (free plan) instead of Firebase
/// Storage, which needs the paid Blaze plan.
///
/// Uses an *unsigned* upload preset, so no API secret ships inside the app.
/// `.env` must define `CLOUDINARY_CLOUD_NAME` and `CLOUDINARY_UPLOAD_PRESET`.
///
/// Cloudinary's list API needs the API secret, so the upload history is kept
/// locally per Firebase user. Entries are only added after Cloudinary really
/// answered with a `secure_url`; nothing is fabricated.
class CloudinaryStorageService implements IStorageService {
  CloudinaryStorageService({
    http.Client? client,
    String? cloudName,
    String? uploadPreset,
    String? Function()? currentUid,
  })  : _client = client ?? http.Client(),
        _cloudName = cloudName,
        _uploadPreset = uploadPreset,
        _currentUid = currentUid;

  static const _historyLimit = 50;

  final http.Client _client;
  final String? _cloudName;
  final String? _uploadPreset;
  final String? Function()? _currentUid;

  String get _cloud => _cloudName ?? dotenv.maybeGet('CLOUDINARY_CLOUD_NAME') ?? '';
  String get _preset =>
      _uploadPreset ?? dotenv.maybeGet('CLOUDINARY_UPLOAD_PRESET') ?? '';

  String _requireUid() {
    final custom = _currentUid;
    if (custom != null) {
      final uid = custom();
      if (uid != null) return uid;
    } else {
      try {
        if (Firebase.apps.isNotEmpty) {
          final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) return uid;
        }
      } catch (_) {}
    }
    throw const StorageFailure(
      StorageFailureKind.notSignedIn,
      'Bạn cần đăng nhập để tải báo cáo lên Cloudinary.',
    );
  }

  void _requireConfig() {
    if (_cloud.isEmpty || _preset.isEmpty) {
      throw const StorageFailure(
        StorageFailureKind.unknown,
        'Chưa cấu hình Cloudinary: thêm CLOUDINARY_CLOUD_NAME và '
        'CLOUDINARY_UPLOAD_PRESET vào file .env.',
      );
    }
  }

  StorageFailure _map(Object e) {
    if (e is StorageFailure) return e;
    if (e is TimeoutException) {
      return StorageFailure(
        StorageFailureKind.network,
        'Hết thời gian chờ khi tải lên. Kiểm tra mạng rồi thử lại.',
        cause: e,
      );
    }
    if (e is http.ClientException) {
      return StorageFailure(
        StorageFailureKind.network,
        'Mất kết nối mạng, tải lên không hoàn tất. Kiểm tra mạng rồi thử lại.',
        cause: e,
      );
    }
    return StorageFailure(
      StorageFailureKind.unknown,
      'Tải lên thất bại: $e',
      cause: e,
    );
  }

  String _historyKey(String uid) => 'cloudinary_reports_$uid';

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
      _requireConfig();

      // Unsigned uploads cannot overwrite, so make every public_id unique.
      final publicId =
          'reports/$uid/${timestamp.millisecondsSinceEpoch}_$fileName';

      FirebaseEvidenceLogger.log(
        service: 'Cloud Storage (Cloudinary)',
        action: 'Uploading file to Cloudinary',
        payload: {
          'publicId': publicId,
          'bytes': data.length,
          'classCode': classCode,
        },
      );

      onProgress?.call(0);
      final request = http.MultipartRequest(
        'POST',
        Uri.https('api.cloudinary.com', '/v1_1/$_cloud/raw/upload'),
      )
        ..fields['upload_preset'] = _preset
        ..fields['public_id'] = publicId
        ..fields['context'] = 'classCode=$classCode'
        ..files.add(
          http.MultipartFile.fromBytes('file', data, filename: fileName),
        );

      final streamed =
          await _client.send(request).timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed)
          .timeout(const Duration(seconds: 60));

      Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        body = const {};
      }

      if (response.statusCode != 200 || body['secure_url'] is! String) {
        final apiMessage = (body['error'] is Map)
            ? (body['error'] as Map)['message']?.toString()
            : null;
        final denied = response.statusCode == 401 || response.statusCode == 403;
        throw StorageFailure(
          denied ? StorageFailureKind.permissionDenied : StorageFailureKind.unknown,
          response.statusCode == 200
              ? 'Cloudinary không trả về đường dẫn tệp (thiếu secure_url).'
              : 'Cloudinary từ chối yêu cầu (HTTP ${response.statusCode})'
                  '${apiMessage != null ? ': $apiMessage' : ''}.',
        );
      }
      onProgress?.call(1.0);

      final result = StorageUploadResult(
        fileName: fileName,
        storagePath: (body['public_id'] as String?) ?? publicId,
        downloadUrl: body['secure_url'] as String,
        bytes: (body['bytes'] as num?)?.toInt() ?? data.length,
        uploadedAt: timestamp,
      );
      await _remember(uid, result);

      FirebaseEvidenceLogger.log(
        service: 'Cloud Storage (Cloudinary)',
        action: 'Upload completed successfully',
        payload: {
          'downloadUrl': result.downloadUrl,
          'publicId': result.storagePath,
          'sizeBytes': result.bytes,
        },
        isSuccess: true,
      );
      return result;
    } catch (e) {
      final failure = _map(e);
      FirebaseEvidenceLogger.log(
        service: 'Cloud Storage (Cloudinary)',
        action: 'Upload failed (${failure.kind.name})',
        payload: {'fileName': fileName},
        isSuccess: false,
        errorMessage: failure.userMessage,
      );
      throw failure;
    }
  }

  Future<void> _remember(String uid, StorageUploadResult r) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_historyKey(uid)) ?? <String>[];
      list.insert(
        0,
        jsonEncode({
          'fileName': r.fileName,
          'storagePath': r.storagePath,
          'downloadUrl': r.downloadUrl,
          'bytes': r.bytes,
          'uploadedAt': r.uploadedAt.toIso8601String(),
        }),
      );
      await prefs.setStringList(
        _historyKey(uid),
        list.take(_historyLimit).toList(),
      );
    } catch (_) {
      // History is a convenience; the file is already safely uploaded.
    }
  }

  @override
  Future<List<StorageUploadResult>> getUploadedReports() async {
    try {
      final uid = _requireUid();
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_historyKey(uid)) ?? const <String>[];
      final results = <StorageUploadResult>[];
      for (final item in raw) {
        try {
          final m = jsonDecode(item) as Map<String, dynamic>;
          results.add(
            StorageUploadResult(
              fileName: m['fileName'] as String,
              storagePath: m['storagePath'] as String,
              downloadUrl: m['downloadUrl'] as String,
              bytes: (m['bytes'] as num).toInt(),
              uploadedAt: DateTime.parse(m['uploadedAt'] as String),
            ),
          );
        } catch (_) {
          // Skip a corrupted entry instead of hiding the whole list.
        }
      }
      return results;
    } catch (e) {
      throw _map(e);
    }
  }
}
