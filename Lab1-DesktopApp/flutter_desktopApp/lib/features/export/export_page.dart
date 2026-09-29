import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/status_chip.dart';
import '../../models/student.dart';
import '../../services/attendance_stats_service.dart';
import '../../services/google_sheet_service.dart';

class ExportPage extends StatefulWidget {
  final AttendanceStatsService stats;

  const ExportPage({super.key, required this.stats});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  late Future<void> _loadFuture;
  String _classCode = 'all';
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _loadFuture = widget.stats.load(force: true);
  }

  List<SheetScheduleRow> get _sessions => widget.stats.sessions.where((session) {
        final date = DateTime.tryParse(session.sessionDate);
        final classMatches = _classCode == 'all' || session.classCode == _classCode;
        final fromMatches = _from == null || (date != null && !date.isBefore(_from!));
        final toMatches = _to == null || (date != null && !date.isAfter(_to!));
        return classMatches && fromMatches && toMatches;
      }).toList()
    ..sort((a, b) => a.sessionDate.compareTo(b.sessionDate));

  Future<void> _pickDate(bool from) async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: from ? (_from ?? DateTime.now()) : (_to ?? DateTime.now()),
    );
    if (selected != null) setState(() => from ? _from = selected : _to = selected);
  }

  Future<void> _exportCsv() async {
    try {
      final sessionIds = _sessions.map((session) => session.sessionId).toSet();
      final relevantAttendance = widget.stats.attendance.where((row) => sessionIds.contains(row.sessionId)).toList();

      if (relevantAttendance.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No attendance records found for the selected filter.')),
        );
        return;
      }

      final rows = <String>[
        'class_code,subject_code,session_no,session_date,slot,roll_number,full_name,status,note',
      ];

      for (final attendance in relevantAttendance) {
        final session = _sessions.firstWhere((item) => item.sessionId == attendance.sessionId);
        final student = widget.stats.students.firstWhere(
          (item) => item.studentId == attendance.studentId || item.studentCode == attendance.studentId,
          orElse: () => Student(
            studentId: attendance.studentId,
            studentName: 'Unknown student',
            classId: session.classCode,
            email: '',
          ),
        );
        final rollNo = student.studentCode.isNotEmpty ? student.studentCode : student.studentId;
        rows.add([
          session.classCode,
          session.subjectCode,
          session.sessionNo.toString(),
          session.sessionDate,
          session.slot,
          rollNo,
          student.fullName,
          attendance.status,
          attendance.note,
        ].map(_csv).join(','));
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final classLabel = _classCode == 'all' ? 'AllClasses' : _classCode;
      final defaultFileName = 'FAP_Attendance_${classLabel}_$timestamp.csv';

      String? savePath;
      try {
        savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save FAP Attendance CSV',
          fileName: defaultFileName,
          type: FileType.custom,
          allowedExtensions: ['csv'],
        );
      } catch (_) {}

      // Fallback to Documents folder if dialog was bypassed
      if (savePath == null) {
        final directory = await getApplicationDocumentsDirectory();
        savePath = '${directory.path}${Platform.pathSeparator}$defaultFileName';
      }

      final file = File(savePath);
      await file.writeAsString('${rows.join('\n')}\n');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Exported ${rows.length - 1} records for [ $classLabel ] to $savePath'),
          action: SnackBarAction(
            label: 'Open Folder',
            onPressed: () => Process.run('explorer.exe', ['/select,', savePath!]),
          ),
          duration: const Duration(seconds: 10),
        ));
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $error')));
    }
  }

  String _csv(Object value) => '"${value.toString().replaceAll('"', '""')}"';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Could not load export data: ${snapshot.error}'));

        final classes = [
          'all',
          ...{
            ...widget.stats.students.map((student) => student.classId),
            ...widget.stats.sessions.map((session) => session.classCode),
          }.where((value) => value.isNotEmpty).toList()
            ..sort(),
        ];

        return ListView(padding: const EdgeInsets.all(24), children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Export Attendance', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 4),
                Text(
                  'Select class and date range to export official FAP attendance records with Class Code & Roll Number.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ]),
            ),
            IconButton.filledTonal(
              tooltip: 'Refresh data from Google Sheets',
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() => _loadFuture = widget.stats.load(force: true)),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _exportCsv,
              icon: const Icon(Icons.download_outlined),
              label: Text(_classCode == 'all' ? 'Export CSV (All Classes)' : 'Export CSV ()'),
            ),
          ]),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(spacing: 12, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    initialValue: _classCode,
                    decoration: const InputDecoration(labelText: 'Target Class', isDense: true),
                    items: classes
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(value == 'all' ? '🏫 All classes' : '📘 Class '),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _classCode = value ?? 'all'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickDate(true),
                  icon: const Icon(Icons.date_range),
                  label: Text(_from == null ? 'From date' : _dateText(_from!)),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickDate(false),
                  icon: const Icon(Icons.date_range),
                  label: Text(_to == null ? 'To date' : _dateText(_to!)),
                ),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _from = null;
                    _to = null;
                    _classCode = 'all';
                  }),
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Reset filters'),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: const WidgetStatePropertyAll(AppColors.primaryDark),
                headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                columns: const [
                  DataColumn(label: Text('CLASS')),
                  DataColumn(label: Text('SUBJECT')),
                  DataColumn(label: Text('SESSION NO.')),
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('SLOT')),
                  DataColumn(label: Text('SYNC STATUS')),
                ],
                rows: _sessions.map((session) {
                  final status = _syncStatus(session.sessionId);
                  return DataRow(cells: [
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(session.classCode, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    )),
                    DataCell(Text('${session.subjectCode} - ${session.subjectName}')),
                    DataCell(Text('Session ${session.sessionNo} / ${session.totalSessions}')),
                    DataCell(Text(session.sessionDate)),
                    DataCell(Text(session.slot)),
                    DataCell(_statusBadge(status)),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ]);
      },
    );
  }

  Widget _statusBadge(String status) {
    return switch (status) {
      'submitted' => const StatusChip(label: 'Submitted', type: StatusChipType.present),
      'draft' => const StatusChip(label: 'Draft', type: StatusChipType.warning),
      _ => const StatusChip(label: 'Not Taken', type: StatusChipType.neutral),
    };
  }

  String _syncStatus(String sessionId) {
    final statuses = widget.stats.attendance.where((row) => row.sessionId == sessionId).map((row) => row.syncStatus).toSet();
    if (statuses.isEmpty) return 'not_taken';
    if (statuses.contains('draft')) return 'draft';
    return 'submitted';
  }

  String _dateText(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
