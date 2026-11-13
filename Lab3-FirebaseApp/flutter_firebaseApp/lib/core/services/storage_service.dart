/// Storage contract shared by the ViewModels. The only implementation is
/// `CloudinaryStorageService`; it has no Firebase dependency.
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

  /// Lists the signed-in user's uploaded files (from local history).
  Future<List<StorageUploadResult>> getUploadedReports();
}
