import 'package:flutter/material.dart';
import '../models/view_state.dart';
import '../theme/app_theme.dart';

class StateView<T> extends StatelessWidget {
  final ViewState<T> state;
  final Widget Function(BuildContext context, T data) onData;
  final VoidCallback? onRetry;
  final String? loadingMessage;
  final String? emptyTitle;
  final String? emptyMessage;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final Widget? customEmptyWidget;

  const StateView({
    super.key,
    required this.state,
    required this.onData,
    this.onRetry,
    this.loadingMessage,
    this.emptyTitle,
    this.emptyMessage,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.customEmptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                if (loadingMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    loadingMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );

      case ViewStatus.error:
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        color: AppColors.errorText,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Đã có lỗi xảy ra',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.errorText,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage ?? 'Không thể tải dữ liệu vào lúc này.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    if (onRetry != null) ...[
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Thử lại (Retry)'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );

      case ViewStatus.empty:
        if (customEmptyWidget != null) return customEmptyWidget!;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.inbox_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      emptyTitle ?? 'Không có dữ liệu',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      emptyMessage ?? 'Chưa có bản ghi nào phù hợp với yêu cầu.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    if (onEmptyAction != null && emptyActionLabel != null) ...[
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: onEmptyAction,
                        icon: const Icon(Icons.tune, size: 18),
                        label: Text(emptyActionLabel!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );

      case ViewStatus.data:
        return onData(context, state.data as T);
    }
  }
}
