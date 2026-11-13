import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/status_chip.dart';
import '../../models/student.dart';
import '../../services/attendance_stats_service.dart';
import '../../services/file_service.dart';
import '../../services/google_sheet_service.dart';

class ExportPage extends StatefulWidget {
  final AttendanceStatsService stats;

  const ExportPage({super.key, required this.stats});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  final _fileService = FileService();
  final _importClassController = TextEditingController();
  late Future<void> _loadFuture;
  String _classCode = 'all';
  DateTime? _from;
  DateTime? _to;
  bool _exporting = false;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = widget.stats.load(force: true);
  }

  @override
  void dispose() {
    _importClassController.dispose();
    super.dispose();
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
    if (_exporting) return;
    setState(() => _exporting = true);
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

      final savePath = await _fileService.saveTextFile(
        dialogTitle: 'Save FAP Attendance CSV',
        fileName: defaultFileName,
        content: '${rows.join('\n')}\n',
        extensions: ['csv'],
      );
      if (savePath == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Exported ${rows.length - 1} records for [ $classLabel ] to $savePath'),
          action: Platform.isWindows
              ? SnackBarAction(
                  label: 'Open Folder',
                  onPressed: () => Process.run('explorer.exe', ['/select,', savePath]),
                )
              : null,
          duration: const Duration(seconds: 10),
        ));
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $error')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _importStudents({required bool excel}) async {
    if (_importing) return;
    final fallbackClass = (_importClassController.text.trim().isNotEmpty
            ? _importClassController.text
            : (_classCode == 'all' ? '' : _classCode))
        .trim()
        .toUpperCase();
    if (fallbackClass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a fallback class code before importing.')),
      );
      return;
    }

    setState(() => _importing = true);
    try {
      final students = excel
          ? await _fileService.importStudentsFromExcel(fallbackClass)
          : await _fileService.importStudentsFromCsv(fallbackClass);
      if (students.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No students were imported.')));
        return;
      }
      final added = await widget.stats.sheetService.appendStudents(students);
      await widget.stats.load(force: true);
      if (!mounted) return;
      final importedClasses = students
          .map((student) => student.classId.trim().toUpperCase())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      final selectedClass = importedClasses.contains(fallbackClass) ? fallbackClass : importedClasses.first;
      setState(() {
        _classCode = selectedClass;
        _importClassController.text = selectedClass;
      });
      final skipped = students.length - added;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $added new students. Skipped $skipped duplicate rows.')),
      );
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $error')));
    } finally {
      if (mounted) setState(() => _importing = false);
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

        final narrow = MediaQuery.sizeOf(context).width < 700;
        final titleBlock = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Export & FAP Sync', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text(
            'Select class and date range to export official FAP attendance records or import class roster from CSV/Excel.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ]);
        final refreshButton = IconButton.filledTonal(
          tooltip: 'Refresh data from Google Sheets',
          icon: const Icon(Icons.refresh),
          onPressed: () => setState(() => _loadFuture = widget.stats.load(force: true)),
        );
        final exportButton = FilledButton.icon(
          onPressed: _exporting ? null : _exportCsv,
          icon: const Icon(Icons.download_outlined),
          label: Text(_exporting ? 'Exporting...' : (_classCode == 'all' ? 'Export CSV (All Classes)' : 'Export CSV ($_classCode)')),
        );
        return ListView(padding: EdgeInsets.all(narrow ? 16 : 24), children: [
          // On a phone the title would be squeezed between the buttons, so stack them.
          if (narrow) ...[
            titleBlock,
            const SizedBox(height: 12),
            Row(children: [refreshButton, const SizedBox(width: 8), Expanded(child: exportButton)]),
          ] else
            Row(children: [
              Expanded(child: titleBlock),
              refreshButton,
              const SizedBox(width: 8),
              exportButton,
            ]),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(spacing: 12, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
                SizedBox(
                  width: narrow ? double.infinity : 200,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _classCode,
                    decoration: const InputDecoration(labelText: 'Target Class', isDense: true),
                    items: classes
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(value == 'all' ? '🏫 All classes' : '📘 Class $value'),
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
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(spacing: 12, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
                SizedBox(
                  width: narrow ? double.infinity : 200,
                  child: TextField(
                    controller: _importClassController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Fallback class code',
                      hintText: 'SE1804',
                      isDense: true,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _importing ? null : () => _importStudents(excel: false),
                  icon: const Icon(Icons.upload_file),
                  label: Text(_importing ? 'Importing...' : 'Import Students (CSV)'),
                ),
                OutlinedButton.icon(
                  onPressed: _importing ? null : () => _importStudents(excel: true),
                  icon: const Icon(Icons.table_view),
                  label: Text(_importing ? 'Importing...' : 'Import Students (Excel)'),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          // Six columns do not fit on a phone, so list one card per session there.
          if (narrow)
            ..._sessions.map((session) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${session.classCode}  ·  ${session.subjectCode}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                          const SizedBox(height: 2),
                          Text(session.subjectName),
                          Text('Session ${session.sessionNo} / ${session.totalSessions}  ·  ${session.sessionDate}  ·  ${session.slot}', style: Theme.of(context).textTheme.bodySmall),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      _statusBadge(_syncStatus(session.sessionId)),
                    ]),
                  ),
                ))
          else Card(
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
