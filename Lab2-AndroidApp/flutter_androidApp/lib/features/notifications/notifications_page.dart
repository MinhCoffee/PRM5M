import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/firebase/firebase_messaging_service.dart';
import '../../core/theme/app_theme.dart';
import 'viewmodel/notifications_viewmodel.dart';

class NotificationsPage extends StatefulWidget {
  final NotificationsViewModel viewModel;

  const NotificationsPage({super.key, required this.viewModel});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final items = vm.items;
        final narrow = MediaQuery.sizeOf(context).width < 700;

        return ListView(
          padding: EdgeInsets.all(narrow ? 16 : 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trung tâm thông báo',
                          style: Theme.of(context).textTheme.headlineLarge),
                      const SizedBox(height: 4),
                      Text(
                        vm.unreadCount == 0
                            ? 'Không có thông báo chưa đọc.'
                            : '${vm.unreadCount} thông báo chưa đọc.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: vm.unreadCount == 0 ? null : vm.markAllRead,
                  child: const Text('Đánh dấu đã đọc'),
                ),
                TextButton(
                  onPressed: items.isEmpty ? null : vm.clear,
                  child: const Text('Xóa tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (vm.permission == NotificationPermission.denied)
              Container(
                key: const Key('notification_permission_denied'),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.notifications_off_outlined,
                        color: AppColors.errorText),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bạn đã từ chối quyền thông báo nên sẽ không nhận được '
                        'thông báo đẩy. Bật lại trong Cài đặt hệ thống > Ứng dụng '
                        '> Thông báo. Các thông báo trong ứng dụng vẫn hiển thị ở đây.',
                        style: TextStyle(color: AppColors.errorText),
                      ),
                    ),
                  ],
                ),
              ),
            if (items.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.notifications_none,
                            size: 40, color: AppColors.outline),
                        SizedBox(height: 8),
                        Text(
                          'Chưa có thông báo nào.',
                          style: TextStyle(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...items.map((m) => _tile(context, m)),
          ],
        );
      },
    );
  }

  Widget _tile(BuildContext context, PushNotificationMessage m) {
    final isLocal = m.source == NotificationSource.local;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(widget.viewModel.routeFor(m)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: (m.isRead ? AppColors.outline : AppColors.primary)
                    .withValues(alpha: 0.14),
                child: Icon(
                  isLocal ? Icons.notifications_active_outlined : Icons.cloud_outlined,
                  color: m.isRead ? AppColors.outline : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: m.isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                    ),
                    if (m.body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(m.body, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '${isLocal ? 'Trong ứng dụng' : 'FCM'}'
                      '${m.receivedIn == null ? '' : ' · ${_stateLabel(m.receivedIn!)}'}'
                      ' · ${_formatTime(m.sentAt)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stateLabel(NotificationAppState s) => switch (s) {
        NotificationAppState.foreground => 'đang mở',
        NotificationAppState.background => 'chạy nền',
        NotificationAppState.terminated => 'đã đóng',
      };

  String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}/${two(t.month)} ${two(t.hour)}:${two(t.minute)}';
  }
}
