import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/state_view.dart';
import '../../services/attendance_stats_service.dart';
import '../../services/google_sheet_service.dart';
import 'viewmodel/home_viewmodel.dart';

class HomePage extends StatefulWidget {
  final HomeViewModel viewModel;
  final void Function(String sessionId) onSessionSelected;

  const HomePage({
    super.key,
    required this.viewModel,
    required this.onSessionSelected,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return StateView<HomeDashboardData>(
          state: widget.viewModel.state,
          loadingMessage: 'Đang tải dữ liệu tổng quan...',
          onRetry: () => widget.viewModel.loadDashboard(force: true),
          onData: (context, data) => _buildContent(context, data),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, HomeDashboardData data) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final now = DateTime.now();

    return ListView(
      padding: EdgeInsets.all(narrow ? 16 : 24),
      children: [
        // Announcement from Remote Config
        if (data.announcement.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.campaign_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data.announcement,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Header Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trang chủ', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Tổng quan điểm danh ngày ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Làm mới dữ liệu',
              icon: const Icon(Icons.refresh),
              onPressed: () => widget.viewModel.loadDashboard(force: true),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 4 KPI Summary Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = narrow ? (constraints.maxWidth - 12) / 2 : 250.0;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _statCard(
                  'Ca học hôm nay',
                  '${data.todaySessions.length}',
                  Icons.calendar_today_outlined,
                  AppColors.primary,
                  cardWidth,
                ),
                _statCard(
                  'Tỷ lệ có mặt chung',
                  '${(data.overallRate * 100).toStringAsFixed(1)}%',
                  Icons.how_to_reg_outlined,
                  AppColors.green,
                  cardWidth,
                ),
                _statCard(
                  'Sinh viên nguy cơ cấm thi',
                  '${data.bannedStudentsCount}',
                  Icons.warning_amber_outlined,
                  AppColors.error,
                  cardWidth,
                ),
                _statCard(
                  'Ca đang lưu nháp',
                  '${data.draftSessionsCount}',
                  Icons.drafts_outlined,
                  AppColors.tertiary,
                  cardWidth,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),

        // Today's Sessions Section
        Text("Ca học hôm nay", style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        if (data.todaySessions.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_available, size: 36, color: AppColors.outline),
                    SizedBox(height: 8),
                    Text(
                      'Hôm nay không có ca học nào được xếp lịch.',
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...data.todaySessions.map((session) {
            final status = widget.viewModel.sessionStatus(session);
            final statusColor = _statusColor(status);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => widget.onSessionSelected(session.sessionId),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: statusColor.withValues(alpha: 0.14),
                        child: Icon(Icons.class_outlined, color: statusColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${session.subjectCode}  ·  Lớp ${session.classCode}',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${session.subjectName}  ·  Phòng ${session.room}  ·  ${session.slot}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                            ),
                            if (narrow) ...[
                              const SizedBox(height: 8),
                              _statusBadge(status.value, statusColor),
                            ],
                          ],
                        ),
                      ),
                      if (!narrow) ...[
                        const SizedBox(width: 12),
                        _statusBadge(status.value, statusColor),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),

        const SizedBox(height: 28),

        // Quick User Flow Guide
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_stories_outlined, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Hướng dẫn 3 luồng chức năng (User Flows)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _flowStep(
                  '1. Authentication',
                  'Đăng nhập tài khoản Google @fpt.edu.vn, cấp quyền truy cập hệ thống.',
                ),
                _flowStep(
                  '2. Take Attendance',
                  'Mở ca học từ danh sách, tích chọn Có mặt/Vắng mặt, Lưu nháp hoặc Nộp chính thức.',
                ),
                _flowStep(
                  '3. View Reports & Export',
                  'Lọc báo cáo theo học kỳ/môn/lớp, theo dõi tỷ lệ vắng và xuất tệp CSV/lưu trữ đám mây.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
    double width,
  ) =>
      SizedBox(
        width: width,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
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

  Widget _statusBadge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );

  Widget _flowStep(String title, String desc) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 13, color: AppColors.onSurface),
                  children: [
                    TextSpan(
                      text: '$title: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: desc),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Color _statusColor(SessionStatus status) => switch (status) {
        SessionStatus.taken => AppColors.green,
        SessionStatus.inProgress => AppColors.tertiary,
        SessionStatus.overdueNotTaken => AppColors.error,
        SessionStatus.notTaken => AppColors.primary,
      };
}
