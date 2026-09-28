import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/status_chip.dart';
import 'attendance_student.dart';
import 'data/attendance_repository.dart';

class AttendanceDetailPage extends StatefulWidget {
  final String sessionId;
  final AttendanceRepository repository;

  const AttendanceDetailPage({super.key, required this.sessionId, required this.repository});

  @override
  State<AttendanceDetailPage> createState() => _AttendanceDetailPageState();
}

class _AttendanceDetailPageState extends State<AttendanceDetailPage> {
  late final List<AttendanceStudent> _students;
  late final AttendanceSession _session;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _session = widget.repository.sessions.firstWhere((session) => session.id == widget.sessionId, orElse: () => widget.repository.sessions.first);
    _students = widget.repository.studentsForSession(widget.sessionId);
  }

  int get _presentCount => _students.where((student) => student.status == AttendanceState.present).length;
  int get _absentCount => _students.length - _presentCount;

  void _setAll(AttendanceState status) => setState(() {
        for (final student in _students) {
          student.status = status;
        }
      });

  Future<void> _submit() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Submit attendance?'),
            content: Text('Submit ${_session.subjectCode} for ${_session.className}? This mock action marks the session as submitted.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
            ],
          ),
        ) ??
        false;
    if (confirmed && mounted) {
      setState(() => _submitted = true);
      _showMessage('Attendance submitted successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: _content(context));
  }

  Widget _content(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _sessionCard(context),
              const SizedBox(height: 12),
              _controlBar(context),
              const SizedBox(height: 12),
              _rosterCard(context),
              const SizedBox(height: 12),
              _autosaveBar(context),
            ]),
          ),
        ),
      );

  Widget _sessionCard(BuildContext context) => Card(
        child: Column(children: [
          const SizedBox(height: 6, child: ColoredBox(color: AppColors.primary)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              _sessionItem(context, Icons.menu_book_outlined, 'Subject & Course', _session.subjectCode, _session.subjectName),
              _sessionItem(context, Icons.groups_outlined, 'Cohort & Schedule', 'Class ${_session.className}', _session.schedule),
              _sessionItem(context, Icons.meeting_room_outlined, 'Campus Space', _session.room, _session.date),
              _sessionItem(context, Icons.calendar_month_outlined, 'Session', 'Session ${_session.sessionNumber} / ${_session.totalSessions}', ''),
            ]),
          ),
        ]),
      );

  Widget _sessionItem(BuildContext context, IconData icon, String label, String value, String detail) => Expanded(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(6)), child: Icon(icon, color: AppColors.primary, size: 20)),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 1)),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            if (detail.isNotEmpty) Text(detail, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant), overflow: TextOverflow.ellipsis),
          ])),
        ]),
      );

  Widget _controlBar(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(alignment: WrapAlignment.spaceBetween, runSpacing: 10, spacing: 16, children: [
            Wrap(spacing: 6, children: [
              _counter('Enrolled', '${_students.length}', AppColors.surfaceContainer, AppColors.onSurfaceVariant),
              _counter('Present', '$_presentCount', const Color(0xFFE0F2FE), AppColors.primary),
              _counter('Absent', '$_absentCount', AppColors.errorContainer, AppColors.error),
              _counter('Rate', '${(_presentCount / _students.length * 100).toStringAsFixed(1)}%', const Color(0xFFD1E4FF), const Color(0xFF184974)),
            ]),
            Wrap(spacing: 6, children: [
              _actionButton(Icons.done_all, 'Mark All Present', () => _setAll(AttendanceState.present), primary: true),
              _actionButton(Icons.restart_alt, 'Reset', () => _setAll(AttendanceState.present), danger: true),
              _actionButton(Icons.save_outlined, 'Save Draft', () => _showMessage('Draft saved successfully'), filled: true),
              _actionButton(Icons.cloud_sync_outlined, _submitted ? 'Submitted' : 'Submit', _submitted ? () {} : _submit, filled: true, orange: true),
            ]),
          ]),
        ),
      );

  Widget _counter(String label, String value, Color background, Color foreground) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6)),
        child: Text('$label: $value', style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  Widget _actionButton(IconData icon, String label, VoidCallback onPressed, {bool primary = false, bool filled = false, bool danger = false, bool orange = false}) => OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: orange ? Colors.white : danger ? AppColors.error : primary ? AppColors.primary : filled ? Colors.white : AppColors.onSurface,
          backgroundColor: orange ? AppColors.tertiary : filled ? AppColors.secondary : primary ? Colors.white : Colors.transparent,
          side: BorderSide(color: danger ? AppColors.error : primary ? AppColors.outlineVariant : filled ? Colors.transparent : AppColors.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );

  Widget _rosterCard(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: AppColors.surfaceHigh,
            child: Row(children: [
              const Icon(Icons.how_to_reg, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Active Roster Verification', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(width: 8),
              const StatusChip(label: 'Classroom Mode', type: StatusChipType.present),
              const Spacer(),
              const StatusChip(label: 'Present', type: StatusChipType.present),
              const SizedBox(width: 8),
              const StatusChip(label: 'Absent', type: StatusChipType.absent),
              const SizedBox(width: 8),
              const StatusChip(label: 'Critical Risk (>20%)', type: StatusChipType.warning, showIcon: true),
            ]),
          ),
          SizedBox(
            height: 420,
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
              headingRowColor: const WidgetStatePropertyAll(AppColors.primaryDark),
              dataRowMinHeight: 54,
              dataRowMaxHeight: 58,
              columnSpacing: 18,
              horizontalMargin: 12,
              headingTextStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              dataTextStyle: const TextStyle(color: AppColors.onSurface, fontSize: 13),
              columns: const [
                DataColumn(label: Text('NO.')),
                DataColumn(label: Text('PHOTO')),
                DataColumn(label: Text('ROLL NO.')),
                DataColumn(label: Text('FULL NAME + MAJOR')),
                DataColumn(label: Text('GENDER')),
                DataColumn(label: Text('ATTENDANCE STATUS')),
                DataColumn(label: Text('CUMULATIVE ABSENCE')),
                DataColumn(label: Text('NOTE / OFFICIAL REASON')),
              ],
                  rows: _students.asMap().entries.map((entry) => _studentRow(context, entry.key, entry.value)).toList(),
                ),
              ),
            ),
          ),
        ]),
      );

  DataRow _studentRow(BuildContext context, int index, AttendanceStudent student) => DataRow(
        color: WidgetStatePropertyAll(index.isOdd ? const Color(0xFFF8FAFC) : Colors.white),
        cells: [
          DataCell(Text('${index + 1}'.padLeft(2, '0'), style: const TextStyle(color: AppColors.onSurfaceVariant))),
          DataCell(CircleAvatar(radius: 16, backgroundColor: student.avatarColor.withValues(alpha: 0.18), child: Text(student.fullName[0], style: TextStyle(color: student.avatarColor, fontWeight: FontWeight.w700)))),
          DataCell(Text(student.rollNo, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
          DataCell(Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w600)), Text(student.major, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11))])),
          DataCell(Text(student.gender, style: const TextStyle(color: AppColors.onSurfaceVariant))),
          DataCell(_statusToggle(student)),
          DataCell(StatusChip(label: '${student.cumulativeAbsences}/${student.cumulativeSessions} (${(student.absenceRate * 100).toStringAsFixed(1)}%)', type: student.absenceRate > .2 ? StatusChipType.absent : student.absenceRate >= .14 ? StatusChipType.warning : StatusChipType.neutral, showIcon: student.absenceRate > .2)),
          DataCell(SizedBox(width: 220, child: TextFormField(initialValue: student.note, decoration: const InputDecoration(hintText: 'Add remarks...')))),
        ],
      );

  Widget _statusToggle(AttendanceStudent student) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(6)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _statusButton(student, AttendanceState.present, 'Present'),
          _statusButton(student, AttendanceState.absent, 'Absent'),
        ]),
      );

  Widget _statusButton(AttendanceStudent student, AttendanceState status, String label) {
    final selected = student.status == status;
    return InkWell(
      onTap: () => setState(() => student.status = status),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: selected ? (status == AttendanceState.present ? AppColors.primary : AppColors.error) : Colors.transparent, borderRadius: BorderRadius.circular(4)),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _autosaveBar(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.arrow_back, size: 16), label: const Text('Previous Class (Slot 2)')),
            const SizedBox(width: 8),
            OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.arrow_forward, size: 16), label: const Text('Next Class (Slot 4)')),
            const Spacer(),
            const Icon(Icons.cloud_done_outlined, color: AppColors.primary, size: 16),
            const SizedBox(width: 6),
            Text('Draft auto-saved at 11:22:15 AM', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant)),
          ]),
        ),
      );

  void _showMessage(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}