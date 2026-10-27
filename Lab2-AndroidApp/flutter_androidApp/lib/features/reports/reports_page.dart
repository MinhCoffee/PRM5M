import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/state_view.dart';
import '../../services/attendance_stats_service.dart';
import 'viewmodel/reports_viewmodel.dart';

class ReportsPage extends StatefulWidget {
  final ReportsViewModel viewModel;

  const ReportsPage({super.key, required this.viewModel});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadReports();
    });
  }

  Future<void> _handleExport() async {
    final path = await widget.viewModel.exportCsv();
    if (!mounted) return;

    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Xuất báo cáo thành công & đã đồng bộ đám mây: $path',
          ),
          backgroundColor: AppColors.green,
        ),
      );
    } else if (widget.viewModel.exportErrorMessage != null) {
      _showExportErrorDialog(widget.viewModel.exportErrorMessage!);
    }
  }

  void _showExportErrorDialog(String error) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lỗi xuất báo cáo (Error Recovery)'),
        content: Text(
          '$error\n\nHướng dẫn: Bạn có thể chọn lại bộ lọc có dữ liệu hoặc bấm "Thử lại".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleExport();
            },
            child: const Text('Thử lại (Try Again)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final state = widget.viewModel.state;

        return StateView<ReportsData>(
          state: state,
          loadingMessage: 'Đang tổng hợp dữ liệu báo cáo...',
          onRetry: () => widget.viewModel.loadReports(),
          emptyTitle: 'Chưa có dữ liệu điểm danh',
          emptyMessage: state.errorMessage ??
              'Chưa có buổi học nào được điểm danh trong bộ lọc này.',
          emptyActionLabel: 'Đặt lại bộ lọc (Reset Filter)',
          onEmptyAction: () => widget.viewModel.resetFilters(),
          onData: (context, data) => _buildContent(context, data),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ReportsData data) {
    final narrow = MediaQuery.sizeOf(context).width < 700;
    final isExporting = widget.viewModel.isExporting;

    return ListView(
      padding: EdgeInsets.all(narrow ? 16 : 24),
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Báo cáo chuyên cần',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Thống kê tỷ lệ vắng và danh sách sinh viên cảnh báo theo lớp/môn.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: isExporting ? null : _handleExport,
              icon: isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.download_outlined),
              label: Text(isExporting ? 'Đang xuất...' : 'Export CSV'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Filter Bar
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _filterDropdown(
                  'Học kỳ / Năm',
                  data.selectedSemester,
                  data.semesters,
                  (val) => widget.viewModel.setSemester(val!),
                ),
                _filterDropdown(
                  'Môn học',
                  data.selectedSubject,
                  data.subjects,
                  (val) => widget.viewModel.setSubject(val!),
                ),
                _filterDropdown(
                  'Lớp học',
                  data.selectedClass,
                  data.classes,
                  (val) => widget.viewModel.setClassCode(val!),
                ),
                TextButton.icon(
                  onPressed: () => widget.viewModel.resetFilters(),
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Xóa bộ lọc'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Data Presentation
        if (narrow)
          ...data.rows.map((row) => _studentRiskCard(context, row))
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: const WidgetStatePropertyAll(AppColors.primaryDark),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                columns: const [
                  DataColumn(label: Text('SINH VIÊN')),
                  DataColumn(label: Text('LỚP')),
                  DataColumn(label: Text('SỐ BUỔI ĐÃ DẠY')),
                  DataColumn(label: Text('VẮNG')),
                  DataColumn(label: Text('TỶ LỆ VẮNG')),
                  DataColumn(label: Text('TRẠNG THÁI')),
                ],
                rows: data.rows.map((row) {
                  final statusColor = row.status == StudentRiskStatus.banned
                      ? AppColors.error
                      : row.status == StudentRiskStatus.warning
                          ? AppColors.tertiary
                          : AppColors.green;

                  return DataRow(
                    cells: [
                      DataCell(
                        Text('${row.student.studentCode}  ${row.student.fullName}'),
                      ),
                      DataCell(Text(row.student.classId)),
                      DataCell(Text('${row.sessionsHeld}')),
                      DataCell(Text('${row.absentCount}')),
                      DataCell(
                        Text('${(row.absenceRate * 100).toStringAsFixed(1)}%'),
                      ),
                      DataCell(
                        Text(
                          row.status.value.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _studentRiskCard(BuildContext context, AttendanceStudentStats row) {
    final statusColor = row.status == StudentRiskStatus.banned
        ? AppColors.error
        : row.status == StudentRiskStatus.warning
            ? AppColors.tertiary
            : AppColors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${row.student.studentCode}  ${row.student.fullName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lớp ${row.student.classId}  ·  Vắng ${row.absentCount}/${row.sessionsHeld} buổi  ·  ${(row.absenceRate * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                row.status.value.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterDropdown(
    String label,
    String value,
    List<String> values,
    ValueChanged<String?> onChanged,
  ) =>
      SizedBox(
        width: 190,
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: value,
          decoration: InputDecoration(labelText: label, isDense: true),
          items: values
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item == 'all' ? 'Tất cả' : item),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      );
}
