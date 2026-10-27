import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/user_profile.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/state_view.dart';
import '../../core/widgets/status_chip.dart';
import 'viewmodel/profile_viewmodel.dart';

class ProfilePage extends StatefulWidget {
  final ProfileViewModel viewModel;

  const ProfilePage({super.key, required this.viewModel});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return StateView<UserProfile>(
          state: widget.viewModel.state,
          loadingMessage: 'Đang tải hồ sơ giảng viên...',
          onRetry: () => widget.viewModel.loadProfile(),
          onData: (context, user) => _buildProfileContent(context, user),
        );
      },
    );
  }

  Widget _buildProfileContent(BuildContext context, UserProfile user) {
    final narrow = MediaQuery.sizeOf(context).width < 700;

    return ListView(
      padding: EdgeInsets.all(narrow ? 16 : 24),
      children: [
        // Title Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hồ sơ cá nhân',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Thông tin giảng viên và trạng thái kết nối các dịch vụ Firebase.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Làm mới thông tin',
              icon: const Icon(Icons.refresh),
              onPressed: () => widget.viewModel.loadProfile(),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // User Info Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary,
                  child: user.photoUrl.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            user.photoUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        )
                      : Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : 'M',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.displayName,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          const StatusChip(
                            label: 'Đã xác thực',
                            type: StatusChipType.present,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          _badge('Mã GV: ${user.lecturerCode}'),
                          _badge(user.department),
                          _badge(user.campus),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Firebase 6-Services Integration Monitor
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.cloud_done_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tích hợp 6 dịch vụ Firebase',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _serviceStatusItem(
                  '1. Authentication',
                  'Đăng nhập Google OAuth + Firebase Auth',
                  'Hoạt động (UID: ${user.id.substring(0, user.id.length > 12 ? 12 : user.id.length)}...)',
                  Icons.verified_user_outlined,
                  AppColors.green,
                ),
                _serviceStatusItem(
                  '2. Cloud Storage',
                  'Lưu trữ file xuất báo cáo CSV/PDF lên Storage bucket',
                  'Sẵn sàng (${widget.viewModel.uploadedReportsCount} file đã đồng bộ)',
                  Icons.cloud_upload_outlined,
                  AppColors.primary,
                ),
                _serviceStatusItem(
                  '3. Cloud Messaging (FCM)',
                  'Nhận thông báo đẩy cảnh báo chuyên cần',
                  'Token: ${widget.viewModel.fcmToken.substring(0, widget.viewModel.fcmToken.length > 24 ? 24 : widget.viewModel.fcmToken.length)}...',
                  Icons.notifications_active_outlined,
                  AppColors.tertiary,
                ),
                _serviceStatusItem(
                  '4. Analytics',
                  'Theo dõi sự kiện người dùng và hành vi',
                  'Đang ghi nhận (login, attendance, export, view)',
                  Icons.insights_outlined,
                  AppColors.secondary,
                ),
                _serviceStatusItem(
                  '5. Crashlytics',
                  'Theo dõi lỗi và ghi nhận ngoại lệ tự động',
                  'Đang bảo vệ (ghi nhận log & fatal crash)',
                  Icons.bug_report_outlined,
                  AppColors.error,
                ),
                _serviceStatusItem(
                  '6. Remote Config',
                  'Thay đổi cấu hình ngưỡng vắng từ xa qua Console',
                  'Đang áp dụng (ngưỡng 15% warn / 20% ban)',
                  Icons.tune_outlined,
                  AppColors.orange,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Diagnostics & Lab Verification Actions
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thử nghiệm dịch vụ (Kiểm thử & Bằng chứng Console)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        await widget.viewModel.triggerTestPushNotification();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Đã kích hoạt gửi thử nghiệm FCM Notification thành công!',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.notification_add_outlined),
                      label: const Text('Thử nghiệm FCM Push Notification'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        widget.viewModel.triggerTestCrash();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Đã ghi nhận sự kiện Test Crash vào Crashlytics!',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bug_report_outlined),
                      label: const Text('Thử nghiệm Crashlytics Report'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.errorText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Sign Out Button
        Center(
          child: FilledButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Đăng xuất'),
                  content: const Text(
                    'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản giảng viên?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Hủy'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await widget.viewModel.signOut();
                if (context.mounted) {
                  context.go('/login?logout=1');
                }
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất khỏi hệ thống'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _badge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _serviceStatusItem(
    String name,
    String desc,
    String status,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
