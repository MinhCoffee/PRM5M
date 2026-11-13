import 'package:flutter/material.dart';
import '../../core/widgets/state_view.dart';
import 'data/attendance_repository.dart';
import 'viewmodel/attendance_browse_viewmodel.dart';

class AttendanceBrowsePage extends StatefulWidget {
  final AttendanceBrowseViewModel viewModel;
  final void Function(AttendanceSession session) onSessionSelected;

  const AttendanceBrowsePage({
    super.key,
    required this.viewModel,
    required this.onSessionSelected,
  });

  @override
  State<AttendanceBrowsePage> createState() => _AttendanceBrowsePageState();
}

class _AttendanceBrowsePageState extends State<AttendanceBrowsePage> {
  final _todayController = ScrollController();
  final _upcomingController = ScrollController();
  double _dragStart = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadSessions();
    });
  }

  @override
  void dispose() {
    _todayController.dispose();
    _upcomingController.dispose();
    super.dispose();
  }

  void _scrollBy(ScrollController controller, double offset) {
    final target = (controller.offset + offset).clamp(
      0.0,
      controller.position.maxScrollExtent,
    );
    controller.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _seedSampleData() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Tạo lại dữ liệu mẫu?'),
            content: const Text(
              'Hành động này sẽ làm mới toàn bộ danh sách lớp học, sinh viên và lịch dạy mẫu.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Đồng ý'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    try {
      await widget.viewModel.seedSampleData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo dữ liệu mẫu thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tạo dữ liệu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return StateView<AttendanceBrowseData>(
          state: widget.viewModel.state,
          loadingMessage: 'Đang tải danh sách các ca học...',
          onRetry: () => widget.viewModel.loadSessions(),
          emptyTitle: 'Chưa có ca học nào',
          emptyMessage: 'Hệ thống chưa tìm thấy dữ liệu ca học trong bảng tính.',
          emptyActionLabel: 'Tạo dữ liệu mẫu (Seed Data)',
          onEmptyAction: _seedSampleData,
          onData: (context, data) => _buildContent(context, data),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, AttendanceBrowseData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Điểm danh lớp học',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chọn một ca học để mở bàn làm việc điểm danh chi tiết.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _seedSampleData,
                    icon: const Icon(Icons.science_outlined),
                    label: const Text('Seed sample data'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _subjectRow(
                context,
                'Ca học hôm nay',
                data.todaySessions,
                _todayController,
              ),
              const SizedBox(height: 28),
              _subjectRow(
                context,
                'Các ca học sắp tới',
                data.upcomingSessions,
                _upcomingController,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subjectRow(
    BuildContext context,
    String title,
    List<AttendanceSession> sessions,
    ScrollController controller,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(width: 8),
              Chip(
                label: Text(
                  title.startsWith('Ca học hôm nay')
                      ? '${sessions.length} ca'
                      : '${sessions.length} ca tiếp theo',
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Cuộn sang trái',
                onPressed: () => _scrollBy(controller, -320),
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip: 'Cuộn sang phải',
                onPressed: () => _scrollBy(controller, 320),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sessions.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Không có ca học nào trong nhóm này.'),
              ),
            ),
          if (sessions.isNotEmpty)
            GestureDetector(
              onHorizontalDragStart: (details) =>
                  _dragStart = details.globalPosition.dx,
              onHorizontalDragUpdate: (details) {
                final delta = _dragStart - details.globalPosition.dx;
                _dragStart = details.globalPosition.dx;
                controller.jumpTo(
                  (controller.offset + delta).clamp(
                    0.0,
                    controller.position.maxScrollExtent,
                  ),
                );
              },
              child: SingleChildScrollView(
                controller: controller,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: sessions
                      .map(
                        (session) => Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: _sessionCard(context, session),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      );

  Widget _sessionCard(
    BuildContext context,
    AttendanceSession session,
  ) =>
      SizedBox(
        width: 300,
        child: InkWell(
          onTap: () => widget.onSessionSelected(session),
          borderRadius: BorderRadius.circular(8),
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 8, color: session.accentColor),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.subjectCode,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: session.accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session.subjectName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Lớp ${session.className}  ·  ${session.room}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${session.date}  ·  ${session.schedule}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            'Buổi ${session.sessionNumber}/${session.totalSessions}',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
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
