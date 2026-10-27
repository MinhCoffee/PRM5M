import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/state_view.dart';
import '../../core/widgets/status_chip.dart';
import '../../services/google_sheet_service.dart';
import 'viewmodel/export_viewmodel.dart';

class ExportPage extends StatefulWidget {
  final ExportViewModel viewModel;

  const ExportPage({super.key, required this.viewModel});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  final _importClassController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadExportData();
    });
  }

  @override
  void dispose() {
    _importClassController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isFrom) async {
    final currentData = widget.viewModel.state.data;
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: isFrom
          ? (currentData?.fromDate ?? DateTime.now())
          : (currentData?.toDate ?? DateTime.now()),
    );
    if (selected != null) {
      if (isFrom) {
        widget.viewModel.setDateRange(selected, currentData?.toDate);
      } else {
        widget.viewModel.setDateRange(currentData?.fromDate, selected);
      }
    }
  }

  Future<void> _handleExport() async {
    final path = await widget.viewModel.exportFapCsv();
    if (!mounted) return;

    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xuất CSV thành công & đã đồng bộ đám mây: $path'),
          backgroundColor: AppColors.green,
        ),
      );
    } else if (widget.viewModel.operationMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.viewModel.operationMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleImport({required bool isExcel}) async {
    final fallback = _importClassController.text.trim().toUpperCase();
    if (fallback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mã lớp mặc định trước khi tải tệp lên.'),
        ),
      );
      return;
    }

    final added = await widget.viewModel.importStudents(
      isExcel: isExcel,
      fallbackClass: fallback,
    );
    if (!mounted) return;

    if (added > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã nhập thành công $added sinh viên vào hệ thống!'),
          backgroundColor: AppColors.green,
        ),
      );
    } else if (widget.viewModel.operationMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.viewModel.operationMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final state = widget.viewModel.state;

        return StateView<ExportData>(
          state: state,
          loadingMessage: 'Đang tải danh sách ca học để xuất FAP...',
          onRetry: () => widget.viewModel.loadExportData(force: true),
          emptyTitle: 'Không có ca học nào thỏa mãn',
          emptyMessage: state.errorMessage ??
              'Không tìm thấy ca học nào phù hợp với lớp và khoảng thời gian đã chọn.',
          emptyActionLabel: 'Đặt lại bộ lọc',
          onEmptyAction: () => widget.viewModel.resetFilters(),
          onData: (context, data) => _buildContent(context, data),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ExportData data) {
    final narrow = MediaQuery.sizeOf(context).width < 700;
    final isExporting = widget.viewModel.isExporting;
    final isImporting = widget.viewModel.isImporting;

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
                  Text('Đồng bộ FAP & Xuất dữ liệu',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Xuất tệp CSV điểm danh chuẩn FAP hoặc nhập danh sách lớp từ Excel/CSV.',
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
              label: Text(
                isExporting
                    ? 'Đang xuất...'
                    : (data.selectedClass == 'all'
                        ? 'Xuất CSV (Tất cả lớp)'
                        : 'Xuất CSV (${data.selectedClass})'),
              ),
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
                SizedBox(
                  width: narrow ? double.infinity : 200,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: data.selectedClass,
                    decoration: const InputDecoration(
                      labelText: 'Lớp học mục tiêu',
                      isDense: true,
                    ),
                    items: data.classes
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c == 'all' ? '🏫 Tất cả các lớp' : '📘 Lớp $c'),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        widget.viewModel.setClassCode(val ?? 'all'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickDate(true),
                  icon: const Icon(Icons.date_range),
                  label: Text(data.fromDate == null
                      ? 'Từ ngày'
                      : _formatDate(data.fromDate!)),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickDate(false),
                  icon: const Icon(Icons.date_range),
                  label: Text(data.toDate == null
                      ? 'Đến ngày'
                      : _formatDate(data.toDate!)),
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
        const SizedBox(height: 14),

        // Import Box
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: narrow ? double.infinity : 200,
                  child: TextField(
                    controller: _importClassController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Mã lớp bổ sung (Fallback)',
                      hintText: 'SE1801',
                      isDense: true,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: isImporting ? null : () => _handleImport(isExcel: false),
                  icon: const Icon(Icons.upload_file),
                  label: Text(isImporting ? 'Đang nhập...' : 'Nhập SV từ CSV'),
                ),
                OutlinedButton.icon(
                  onPressed: isImporting ? null : () => _handleImport(isExcel: true),
                  icon: const Icon(Icons.table_view),
                  label: Text(isImporting ? 'Đang nhập...' : 'Nhập SV từ Excel (.xlsx)'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Session list / table
        if (narrow)
          ...data.sessions.map((s) => _sessionCard(context, s))
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
                  DataColumn(label: Text('LỚP')),
                  DataColumn(label: Text('MÔN HỌC')),
                  DataColumn(label: Text('BUỔI SỐ')),
                  DataColumn(label: Text('NGÀY HỌC')),
                  DataColumn(label: Text('CA HỌC')),
                  DataColumn(label: Text('TRẠNG THÁI ĐỒNG BỘ')),
                ],
                rows: data.sessions.map((s) {
                  final status = widget.viewModel.syncStatus(s.sessionId);
                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            s.classCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text('${s.subjectCode} - ${s.subjectName}')),
                      DataCell(Text('Buổi ${s.sessionNo}/${s.totalSessions}')),
                      DataCell(Text(s.sessionDate)),
                      DataCell(Text(s.slot)),
                      DataCell(_statusBadge(status)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _sessionCard(BuildContext context, SheetScheduleRow session) {
    final status = widget.viewModel.syncStatus(session.sessionId);

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
                    '${session.classCode}  ·  ${session.subjectCode}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(session.subjectName),
                  Text(
                    'Buổi ${session.sessionNo}/${session.totalSessions}  ·  ${session.sessionDate}  ·  ${session.slot}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _statusBadge(status),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    return switch (status) {
      'submitted' => const StatusChip(
          label: 'Đã nộp',
          type: StatusChipType.present,
        ),
      'draft' => const StatusChip(
          label: 'Bản nháp',
          type: StatusChipType.warning,
        ),
      _ => const StatusChip(
          label: 'Chưa điểm danh',
          type: StatusChipType.neutral,
        ),
    };
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
