import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/state_view.dart';
import '../../services/attendance_stats_service.dart';
import 'viewmodel/my_classes_viewmodel.dart';

class MyClassesPage extends StatefulWidget {
  final MyClassesViewModel viewModel;
  final void Function(String sessionId) onSessionSelected;

  const MyClassesPage({
    super.key,
    required this.viewModel,
    required this.onSessionSelected,
  });

  @override
  State<MyClassesPage> createState() => _MyClassesPageState();
}

class _MyClassesPageState extends State<MyClassesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return StateView<MyClassesData>(
          state: widget.viewModel.state,
          loadingMessage: 'Đang tải danh sách lớp học...',
          onRetry: () => widget.viewModel.loadClasses(),
          emptyTitle: 'Chưa có lớp học',
          emptyMessage: 'Hiện chưa có dữ liệu lớp học nào được phân công.',
          onData: (context, data) {
            if (data.selectedClass != null) {
              return _sessionsView(context, data);
            }
            return _classesList(context, data);
          },
        );
      },
    );
  }

  Widget _classesList(BuildContext context, MyClassesData data) {
    final narrow = MediaQuery.sizeOf(context).width < 700;

    return ListView(
      padding: EdgeInsets.all(narrow ? 16 : 24),
      children: [
        Text('Lớp học của tôi', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 4),
        Text(
          'Tổng quan tiến độ giảng dạy và số lượng sinh viên cảnh báo chuyên cần.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        if (narrow)
          ...data.classStats.map((item) => _classCard(item))
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    const WidgetStatePropertyAll(AppColors.primaryDark),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                columns: const [
                  DataColumn(label: Text('LỚP HỌC')),
                  DataColumn(label: Text('MÔN HỌC')),
                  DataColumn(label: Text('SỐ SINH VIÊN')),
                  DataColumn(label: Text('TIẾN ĐỘ')),
                  DataColumn(label: Text('CẢNH BÁO')),
                  DataColumn(label: Text('CẤM THI')),
                ],
                rows: data.classStats
                    .map((item) => DataRow(
                          onSelectChanged: (_) =>
                              widget.viewModel.selectClass(item.classCode),
                          cells: [
                            DataCell(Text(
                              item.classCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )),
                            DataCell(Text(item.subjectName)),
                            DataCell(Text('${item.studentCount}')),
                            DataCell(SizedBox(
                              width: 160,
                              child: LinearProgressIndicator(
                                value: item.progress,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            )),
                            DataCell(Text(
                              '${item.warningCount}',
                              style: const TextStyle(
                                color: AppColors.tertiary,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                            DataCell(Text(
                              '${item.bannedCount}',
                              style: const TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _classCard(AttendanceClassStats item) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => widget.viewModel.selectClass(item.classCode),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.classCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.subjectName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.outline),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: item.progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Text('${item.studentCount} sinh viên'),
                    Text('${(item.progress * 100).toStringAsFixed(0)}% tiến độ'),
                    Text(
                      'Cảnh báo: ${item.warningCount}',
                      style: const TextStyle(
                        color: AppColors.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Cấm thi: ${item.bannedCount}',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _sessionsView(BuildContext context, MyClassesData data) {
    final narrow = MediaQuery.sizeOf(context).width < 700;
    final classCode = data.selectedClass!;
    final classSummary = data.classStats.firstWhere(
      (item) => item.classCode == classCode,
      orElse: () => AttendanceClassStats(
        classCode: classCode,
        subjectName: '',
        studentCount: 0,
        progress: 0,
        warningCount: 0,
        bannedCount: 0,
      ),
    );

    return ListView(
      padding: EdgeInsets.all(narrow ? 16 : 24),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Quay lại danh sách lớp',
              onPressed: () => widget.viewModel.selectClass(null),
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lớp $classCode',
                      style: Theme.of(context).textTheme.headlineLarge),
                  Text(
                    '${classSummary.subjectName}  ·  ${classSummary.studentCount} sinh viên  ·  ${(classSummary.progress * 100).toStringAsFixed(0)}% tiến độ',
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ...data.selectedClassSessions.map((session) {
          final status = widget.viewModel.sessionStatus(session);
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              onTap: () => widget.onSessionSelected(session.sessionId),
              title: Text(
                'Buổi ${session.sessionNo}/${session.totalSessions}  ·  ${session.subjectCode}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${session.sessionDate}  ·  ${session.slot}  ·  Phòng ${session.room}',
              ),
              trailing: Chip(label: Text(status.value)),
            ),
          );
        }),
      ],
    );
  }
}
