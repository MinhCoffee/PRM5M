import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/state_view.dart';
import '../../core/widgets/status_chip.dart';
import 'attendance_student.dart';
import 'data/attendance_repository.dart';
import 'viewmodel/attendance_detail_viewmodel.dart';

class AttendanceDetailPage extends StatefulWidget {
  final AttendanceDetailViewModel viewModel;
  final Future<void> Function()? onAttendanceSaved;

  const AttendanceDetailPage({
    super.key,
    required this.viewModel,
    this.onAttendanceSaved,
  });

  @override
  State<AttendanceDetailPage> createState() => _AttendanceDetailPageState();
}

class _AttendanceDetailPageState extends State<AttendanceDetailPage> {
  final _searchController = TextEditingController();
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadSessionDetails();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSave({required bool submitted}) async {
    final success = await widget.viewModel.saveAttendance(submitted: submitted);
    if (!mounted) return;

    if (success) {
      await widget.onAttendanceSaved?.call();
      _showMessage(
        submitted
            ? 'Đã nộp điểm danh thành công lên hệ thống.'
            : 'Đã lưu bản nháp điểm danh thành công.',
        isError: false,
      );
    } else {
      _showMessage(
        'Lỗi lưu dữ liệu. Đã tự động sao lưu vào bộ nhớ máy an toàn.',
        isError: true,
      );
    }
  }

  Future<void> _handleConfirmSubmit() async {
    final session = widget.viewModel.session;
    if (session == null) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận nộp điểm danh?'),
            content: Text(
              'Xác nhận nộp điểm danh môn ${session.subjectCode} cho lớp ${session.className}?\n'
              'Sĩ số: Có mặt ${widget.viewModel.presentCount} / Vắng ${widget.viewModel.absentCount}.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xác nhận nộp'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed && mounted) {
      await _handleSave(submitted: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return StateView<AttendanceDetailData>(
          state: widget.viewModel.state,
          loadingMessage: 'Đang tải danh sách sinh viên ca học...',
          onRetry: () => widget.viewModel.loadSessionDetails(),
          onData: (context, data) => _buildContent(context, data),
        );
      },
    );
  }

  bool get _narrow => MediaQuery.sizeOf(context).width < 700;

  Widget _buildContent(BuildContext context, AttendanceDetailData data) {
    final session = data.session;
    final saveError = widget.viewModel.saveErrorMessage;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        _narrow ? 12 : 20,
        _narrow ? 12 : 20,
        _narrow ? 12 : 20,
        24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error Recovery Banner (Flow 2)
              if (saveError != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off, color: AppColors.errorText),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LỖI KẾT NỐI - ĐÃ SAO LƯU BẢN NHÁP CỤC BỘ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.errorText,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              saveError,
                              style: const TextStyle(
                                color: AppColors.errorText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: widget.viewModel.isSaving
                            ? null
                            : () => widget.viewModel.retrySaving(
                                  submitted: widget.viewModel.isSubmitted,
                                ),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry Saving'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              _sessionCard(context, session),
              const SizedBox(height: 12),
              _controlBar(context, data),
              const SizedBox(height: 12),
              _rosterCard(context, data),
              const SizedBox(height: 12),
              _autosaveBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sessionCard(BuildContext context, AttendanceSession session) {
    final items = [
      _sessionItem(
        context,
        Icons.menu_book_outlined,
        'Môn học & Học phần',
        session.subjectCode,
        session.subjectName,
      ),
      _sessionItem(
        context,
        Icons.groups_outlined,
        'Lớp & Ca học',
        'Lớp ${session.className}',
        session.schedule,
      ),
      _sessionItem(
        context,
        Icons.meeting_room_outlined,
        'Phòng học & Ngày',
        session.room,
        session.date,
      ),
      _sessionItem(
        context,
        Icons.calendar_month_outlined,
        'Tiến độ buổi học',
        'Buổi ${session.sessionNumber} / ${session.totalSessions}',
        '',
      ),
    ];

    return Card(
      child: Column(
        children: [
          const SizedBox(
            height: 6,
            child: ColoredBox(color: AppColors.primary),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _narrow
                ? LayoutBuilder(
                    builder: (context, constraints) => Wrap(
                      spacing: 12,
                      runSpacing: 14,
                      children: [
                        for (final item in items)
                          SizedBox(
                            width: (constraints.maxWidth - 12) / 2,
                            child: item,
                          ),
                      ],
                    ),
                  )
                : Row(children: [for (final item in items) Expanded(child: item)]),
          ),
        ],
      ),
    );
  }

  Widget _sessionItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    String detail,
  ) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                ),
                Text(value, style: Theme.of(context).textTheme.headlineMedium),
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      );

  Widget _controlBar(BuildContext context, AttendanceDetailData data) {
    final isSaving = widget.viewModel.isSaving;
    final isSubmitted = widget.viewModel.isSubmitted;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 10,
              spacing: 16,
              children: [
                Wrap(
                  spacing: 6,
                  children: [
                    _counter(
                      'Sĩ số',
                      '${widget.viewModel.students.length}',
                      AppColors.surfaceContainer,
                      AppColors.onSurfaceVariant,
                    ),
                    _counter(
                      'Có mặt',
                      '${widget.viewModel.presentCount}',
                      const Color(0xFFE0F2FE),
                      AppColors.primaryDark,
                    ),
                    _counter(
                      'Vắng mặt',
                      '${widget.viewModel.absentCount}',
                      AppColors.errorContainer,
                      AppColors.errorText,
                    ),
                    _counter(
                      'Tỷ lệ',
                      '${(widget.viewModel.attendanceRate * 100).toStringAsFixed(1)}%',
                      const Color(0xFFD1E4FF),
                      const Color(0xFF184974),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    _actionButton(
                      Icons.done_all,
                      'Có mặt tất cả',
                      () => widget.viewModel.setAll(AttendanceState.present),
                      primary: true,
                    ),
                    _actionButton(
                      Icons.remove_done,
                      'Vắng tất cả',
                      () => widget.viewModel.setAll(AttendanceState.absent),
                      danger: true,
                    ),
                    _actionButton(
                      Icons.restart_alt,
                      'Đặt lại',
                      () => widget.viewModel.resetStatuses(),
                    ),
                    _actionButton(
                      Icons.save_outlined,
                      isSaving ? 'Đang lưu...' : 'Lưu nháp (Draft)',
                      isSaving ? () {} : () => _handleSave(submitted: false),
                      filled: true,
                    ),
                    _actionButton(
                      Icons.cloud_sync_outlined,
                      isSaving
                          ? 'Đang gửi...'
                          : (isSubmitted ? 'Cập nhật & Nộp' : 'Nộp điểm danh'),
                      isSaving ? () {} : _handleConfirmSubmit,
                      filled: true,
                      orange: true,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => widget.viewModel.setSearchQuery(value),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Tìm theo MSSV hoặc họ tên sinh viên...',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _statusFilter,
                  onChanged: (value) {
                    setState(() => _statusFilter = value ?? 'all');
                    widget.viewModel.setStatusFilter(value ?? 'all');
                  },
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tất cả sinh viên')),
                    DropdownMenuItem(value: 'present', child: Text('Có mặt')),
                    DropdownMenuItem(value: 'absent', child: Text('Vắng mặt')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _counter(
    String label,
    String value,
    Color background,
    Color foreground,
  ) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$label: $value',
          style: TextStyle(
            color: foreground,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _actionButton(
    IconData icon,
    String label,
    VoidCallback onPressed, {
    bool primary = false,
    bool filled = false,
    bool danger = false,
    bool orange = false,
  }) =>
      OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: orange
              ? Colors.white
              : danger
                  ? AppColors.error
                  : primary
                      ? AppColors.primary
                      : filled
                          ? Colors.white
                          : AppColors.onSurface,
          backgroundColor: orange
              ? AppColors.tertiary
              : filled
                  ? AppColors.secondary
                  : primary
                      ? Colors.white
                      : Colors.transparent,
          side: BorderSide(
            color: danger
                ? AppColors.error
                : primary
                    ? AppColors.outlineVariant
                    : filled
                        ? Colors.transparent
                        : AppColors.outlineVariant,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      );

  Widget _rosterCard(BuildContext context, AttendanceDetailData data) {
    final visible = widget.viewModel.visibleStudents;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surfaceHigh,
            child: Row(
              children: [
                const Icon(Icons.how_to_reg, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Bảng kiểm tra sĩ số lớp',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                Text(
                  '${visible.length}/${widget.viewModel.students.length} hiển thị',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          if (_narrow)
            ...visible.asMap().entries.map(
                  (entry) => _studentCard(context, entry.key, entry.value, data),
                )
          else
            SizedBox(
              height: 440,
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: const WidgetStatePropertyAll(
                      AppColors.primaryDark,
                    ),
                    dataRowMinHeight: 54,
                    dataRowMaxHeight: 58,
                    columnSpacing: 18,
                    horizontalMargin: 12,
                    headingTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    columns: const [
                      DataColumn(label: Text('STT')),
                      DataColumn(label: Text('ẢNH')),
                      DataColumn(label: Text('MSSV')),
                      DataColumn(label: Text('HỌ TÊN + NGÀNH')),
                      DataColumn(label: Text('GIỚI TÍNH')),
                      DataColumn(label: Text('ĐIỂM DANH')),
                      DataColumn(label: Text('VẮNG TÍCH LŨY')),
                      DataColumn(label: Text('GHI CHÚ')),
                    ],
                    rows: visible
                        .asMap()
                        .entries
                        .map(
                          (entry) => _studentRow(
                            context,
                            entry.key,
                            entry.value,
                            data,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _studentCard(
    BuildContext context,
    int index,
    AttendanceStudent student,
    AttendanceDetailData data,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: index.isOdd ? const Color(0xFFF8FAFC) : Colors.white,
        border: const Border(
          bottom: BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: student.avatarColor.withValues(alpha: 0.18),
                child: Text(
                  student.fullName.isNotEmpty ? student.fullName[0] : 'S',
                  style: TextStyle(
                    color: student.avatarColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ${student.fullName}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${student.rollNo}  ·  ${student.major}  ·  ${student.gender}',
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _absenceChip(student, data),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statusToggle(student),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: student.note,
                  onChanged: (val) => student.note = val,
                  decoration: const InputDecoration(
                    hintText: 'Thêm ghi chú...',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DataRow _studentRow(
    BuildContext context,
    int index,
    AttendanceStudent student,
    AttendanceDetailData data,
  ) =>
      DataRow(
        color: WidgetStatePropertyAll(
          index.isOdd ? const Color(0xFFF8FAFC) : Colors.white,
        ),
        cells: [
          DataCell(Text('${index + 1}'.padLeft(2, '0'))),
          DataCell(
            CircleAvatar(
              radius: 16,
              backgroundColor: student.avatarColor.withValues(alpha: 0.18),
              child: Text(
                student.fullName.isNotEmpty ? student.fullName[0] : 'S',
                style: TextStyle(
                  color: student.avatarColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          DataCell(
            Text(
              student.rollNo,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataCell(
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  student.major,
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          DataCell(Text(student.gender)),
          DataCell(_statusToggle(student)),
          DataCell(_absenceChip(student, data)),
          DataCell(
            SizedBox(
              width: 220,
              child: TextFormField(
                initialValue: student.note,
                onChanged: (val) => student.note = val,
                decoration: const InputDecoration(hintText: 'Thêm ghi chú...'),
              ),
            ),
          ),
        ],
      );

  Widget _statusToggle(AttendanceStudent student) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusButton(student, AttendanceState.present, 'Có mặt'),
            _statusButton(student, AttendanceState.absent, 'Vắng'),
          ],
        ),
      );

  Widget _statusButton(
    AttendanceStudent student,
    AttendanceState status,
    String label,
  ) {
    final selected = student.status == status;
    final isPresent = status == AttendanceState.present;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Đánh dấu ${student.fullName} là $label',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => widget.viewModel.markStudent(student, status),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 64),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? (isPresent ? AppColors.primary : AppColors.error)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(
                  isPresent ? Icons.check : Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _absenceChip(AttendanceStudent student, AttendanceDetailData data) {
    final rate = student.absenceRate;
    final banned = rate >= data.banThreshold;
    final warning = rate >= data.warnThreshold;

    return StatusChip(
      label:
          '${student.cumulativeAbsences}/${student.cumulativeSessions} (${(rate * 100).toStringAsFixed(1)}%)',
      type: banned
          ? StatusChipType.absent
          : warning
              ? StatusChipType.warning
              : StatusChipType.neutral,
      showIcon: banned,
    );
  }

  Widget _autosaveBar(BuildContext context) {
    final isSubmitted = widget.viewModel.isSubmitted;
    final hasBackup = widget.viewModel.hasOfflineBackup;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              isSubmitted
                  ? Icons.cloud_done_outlined
                  : (hasBackup ? Icons.save_as_outlined : Icons.cloud_off_outlined),
              color: isSubmitted ? AppColors.green : AppColors.onSurfaceVariant,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isSubmitted
                    ? 'Ca học đã hoàn tất điểm danh và nộp chính thức.'
                    : (hasBackup
                        ? 'Đã phát hiện bản sao lưu nháp cục bộ trong bộ nhớ máy.'
                        : 'Chưa chốt nộp. Bạn có thể bấm "Lưu nháp" hoặc "Nộp điểm danh".'),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.error : AppColors.primary,
      ),
    );
  }
}
