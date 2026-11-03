import 'package:flutter/foundation.dart';
import '../services/firebase/firebase_storage_service.dart';

/// Shared state + logic for backing a generated CSV up to Cloud Storage.
/// The view model that mixes this in only has to expose its [IStorageService].
mixin CloudBackupMixin on ChangeNotifier {
  IStorageService get backupStorageService;

  /// 0.0..1.0 while uploading, null when idle.
  double? _backupProgress;
  double? get backupProgress => _backupProgress;

  bool get isBackingUp => _backupProgress != null;

  String? _backupMessage;
  String? get backupMessage => _backupMessage;

  bool _backupFailed = false;
  bool get backupFailed => _backupFailed;

  String? _backupDownloadUrl;
  String? get backupDownloadUrl => _backupDownloadUrl;

  _PendingBackup? _pending;
  bool _backupDisposed = false;

  @override
  void notifyListeners() {
    // An upload can outlive its route; never notify a disposed view model.
    if (!_backupDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _backupDisposed = true;
    super.dispose();
  }
  bool get canRetryBackup => _backupFailed && _pending != null;

  /// Returns true when the file is really in Cloud Storage.
  Future<bool> backupToCloud({
    required String fileName,
    required String content,
    required String classCode,
  }) async {
    // A second tap while uploading would interleave progress and clobber _pending.
    if (isBackingUp) return false;
    _pending = _PendingBackup(fileName, content, classCode);
    _backupProgress = 0;
    _backupFailed = false;
    _backupMessage = 'Đang tải "$fileName" lên Cloud Storage...';
    _backupDownloadUrl = null;
    notifyListeners();

    try {
      final result = await backupStorageService.uploadReport(
        fileName: fileName,
        content: content,
        classCode: classCode,
        onProgress: (p) {
          _backupProgress = p;
          notifyListeners();
        },
      );
      _backupProgress = null;
      _backupFailed = false;
      _backupDownloadUrl = result.downloadUrl;
      _backupMessage = 'Đã sao lưu lên Cloud Storage: ${result.storagePath}';
      _pending = null;
      notifyListeners();
      return true;
    } on StorageFailure catch (e) {
      _backupProgress = null;
      _backupFailed = true;
      _backupMessage = e.userMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _backupProgress = null;
      _backupFailed = true;
      _backupMessage = 'Sao lưu thất bại: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> retryBackup() {
    final p = _pending;
    if (p == null) return Future.value(false);
    return backupToCloud(
      fileName: p.fileName,
      content: p.content,
      classCode: p.classCode,
    );
  }

  void dismissBackupMessage() {
    if (isBackingUp) return;
    _backupMessage = null;
    _backupFailed = false;
    _backupDownloadUrl = null;
    notifyListeners();
  }
}

class _PendingBackup {
  final String fileName;
  final String content;
  final String classCode;
  const _PendingBackup(this.fileName, this.content, this.classCode);
}
