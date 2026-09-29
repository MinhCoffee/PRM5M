import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
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
    _loadFuture = widget.stats.load();
  }

  @override
  void dispose() {
    _importClassController.dispose();
    super.dispose();
  }

  List<SheetScheduleRow> get _sessions => widget.stats.sessions.where((
    session,
  ) {
    final date = DateTime.tryParse(session.sessionDate);
    final classMatches = _classCode == 'all' || session.classCode == _classCode;
    final fromMatches =
        _from == null || (date != null && !date.isBefore(_from!));
    final toMatches = _to == null || (date != null && !date.isAfter(_to!));
    return classMatches && fromMatches && toMatches;
  }).toList()..sort((a, b) => a.sessionDate.compareTo(b.sessionDate));

  Future<void> _pickDate(bool from) async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: from ? (_from ?? DateTime.now()) : (_to ?? DateTime.now()),
    );
    if (selected != null)
      setState(() => from ? _from = selected : _to = selected);
  }

  Future<void> _exportCsv() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final sessionIds = _sessions.map((session) => session.sessionId).toSet();
      final rows = <List<dynamic>>[
        [
          'session_id',
          'subject_code',
          'subject_name',
          'class_code',
          'session_date',
          'slot',
          'room',
          'student_id',
          'student_code',
          'full_name',
          'status',
          'note',
          'sync_status',
          'updated_at',
        ],
      ];
      for (final attendance in widget.stats.attendance.where(
        (row) => sessionIds.contains(row.sessionId),
      )) {
        final session = _sessions.firstWhere(
          (item) => item.sessionId == attendance.sessionId,
        );
        final student = widget.stats.students.firstWhere(
          (item) => item.studentId == attendance.studentId,
          orElse: () => Student(
            studentId: attendance.studentId,
            studentName: 'Unknown student',
            classId: session.classCode,
            email: '',
          ),
        );
        rows.add([
          session.sessionId,
          session.subjectCode,
          session.subjectName,
          session.classCode,
          session.sessionDate,
          session.slot,
          session.room,
          attendance.studentId,
          student.studentCode,
          student.fullName,
          attendance.status,
          attendance.note,
          attendance.syncStatus,
          attendance.updatedAt,
        ]);
      }
      if (rows.length == 1) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No attendance rows match the current filters.'),
            ),
          );
        return;
      }
      final scope = _classCode == 'all' ? 'all_classes' : _classCode;
      final path = await _fileService.exportCsvRows(
        dialogTitle: 'Save attendance export CSV',
        fileName: 'fap_attendance_${scope}_${_timestamp()}.csv',
        rows: rows,
      );
      if (!mounted) return;
      if (path != null)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported ${rows.length - 1} rows to $path')),
        );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $error')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _importStudents({required bool excel}) async {
    if (_importing) return;
    final fallbackClass =
        (_importClassController.text.trim().isNotEmpty
                ? _importClassController.text
                : (_classCode == 'all' ? '' : _classCode))
            .trim()
            .toUpperCase();
    if (fallbackClass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a fallback class code before importing.'),
        ),
      );
      return;
    }

    setState(() => _importing = true);
    try {
      final students = excel
          ? await _fileService.importStudentsFromExcel(fallbackClass)
          : await _fileService.importStudentsFromCsv(fallbackClass);
      if (students.isEmpty) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No students were imported.')),
          );
        return;
      }
      final added = await widget.stats.sheetService.appendStudents(students);
      await widget.stats.load(force: true);
      if (!mounted) return;
      final importedClasses =
          students
              .map((student) => student.classId.trim().toUpperCase())
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      final selectedClass = importedClasses.contains(fallbackClass)
          ? fallbackClass
          : importedClasses.first;
      setState(() {
        _classCode = selectedClass;
        _importClassController.text = selectedClass;
      });
      final skipped = students.length - added;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported $added new students. Skipped $skipped duplicate rows.',
          ),
        ),
      );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Import failed: $error')));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(
            child: Text('Could not load export data: ${snapshot.error}'),
          );
        final classCodes =
            widget.stats.students
                .map((student) => student.classId)
                .toSet()
                .where((value) => value.isNotEmpty)
                .toList()
              ..sort();
        if (_classCode != 'all' && !classCodes.contains(_classCode))
          classCodes.add(_classCode);
        final classes = ['all', ...classCodes];
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review synchronization status and export attendance rows.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _exporting ? null : _exportCsv,
                  icon: const Icon(Icons.download_outlined),
                  label: Text(_exporting ? 'Exporting...' : 'Export CSV'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        initialValue: _classCode,
                        decoration: const InputDecoration(labelText: 'Class'),
                        items: classes
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value == 'all' ? 'All classes' : value,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _classCode = value ?? 'all'),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _pickDate(true),
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        _from == null ? 'From date' : _dateText(_from!),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _pickDate(false),
                      icon: const Icon(Icons.date_range),
                      label: Text(_to == null ? 'To date' : _dateText(_to!)),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _from = null;
                        _to = null;
                        _classCode = 'all';
                      }),
                      child: const Text('Clear filters'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _importClassController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Fallback class code',
                          hintText: 'SE1801',
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _importing
                          ? null
                          : () => _importStudents(excel: false),
                      icon: const Icon(Icons.upload_file),
                      label: Text(_importing ? 'Importing...' : 'Import CSV'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _importing
                          ? null
                          : () => _importStudents(excel: true),
                      icon: const Icon(Icons.table_view),
                      label: Text(_importing ? 'Importing...' : 'Import Excel'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: const WidgetStatePropertyAll(
                    AppColors.primaryDark,
                  ),
                  headingTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  columns: const [
                    DataColumn(label: Text('SESSION')),
                    DataColumn(label: Text('CLASS')),
                    DataColumn(label: Text('DATE')),
                    DataColumn(label: Text('SLOT')),
                    DataColumn(label: Text('SYNC STATUS')),
                  ],
                  rows: _sessions
                      .map(
                        (session) => DataRow(
                          cells: [
                            DataCell(Text(session.sessionId)),
                            DataCell(Text(session.classCode)),
                            DataCell(Text(session.sessionDate)),
                            DataCell(Text(session.slot)),
                            DataCell(
                              Text(
                                _syncStatus(session.sessionId),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _syncStatus(String sessionId) {
    final statuses = widget.stats.attendance
        .where((row) => row.sessionId == sessionId)
        .map((row) => row.syncStatus)
        .toSet();
    if (statuses.isEmpty) return 'not_taken';
    if (statuses.contains('draft')) return 'draft';
    return 'submitted';
  }

  String _dateText(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _timestamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  }
}
