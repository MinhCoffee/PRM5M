import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cloud_backup_mixin.dart';
import '../theme/app_theme.dart';

/// Shows real Cloud Storage upload progress, the final download URL, or a
/// readable failure with a retry action. Renders nothing while idle.
class CloudBackupBanner extends StatelessWidget {
  final CloudBackupMixin viewModel;

  const CloudBackupBanner({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final message = viewModel.backupMessage;
    if (message == null) return const SizedBox.shrink();

    final uploading = viewModel.isBackingUp;
    final failed = viewModel.backupFailed;
    final url = viewModel.backupDownloadUrl;

    final background = failed
        ? AppColors.errorContainer
        : uploading
            ? AppColors.surfaceLow
            : const Color(0xFFE6F4EA);
    final foreground = failed
        ? AppColors.errorText
        : uploading
            ? AppColors.onSurface
            : AppColors.successText;
    final icon = failed
        ? Icons.cloud_off_outlined
        : uploading
            ? Icons.cloud_upload_outlined
            : Icons.cloud_done_outlined;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        key: const Key('cloud_backup_banner'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: foreground, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(message, style: TextStyle(color: foreground)),
                ),
                if (!uploading)
                  InkWell(
                    onTap: viewModel.dismissBackupMessage,
                    child: Icon(Icons.close, size: 18, color: foreground),
                  ),
              ],
            ),
            if (uploading) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(value: viewModel.backupProgress),
              const SizedBox(height: 4),
              Text(
                '${((viewModel.backupProgress ?? 0) * 100).round()}%',
                style: TextStyle(color: foreground, fontSize: 12),
              ),
            ],
            if (url != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                url,
                maxLines: 2,
                style: TextStyle(color: foreground, fontSize: 12),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép URL tải xuống')),
                    );
                  }
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Sao chép URL'),
              ),
            ],
            if (viewModel.canRetryBackup)
              TextButton.icon(
                key: const Key('cloud_backup_retry'),
                onPressed: viewModel.retryBackup,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Thử lại tải lên'),
              ),
          ],
        ),
      ),
    );
  }
}
