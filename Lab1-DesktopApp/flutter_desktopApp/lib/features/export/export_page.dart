import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
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
    _loadFuture = widget.stats.load();
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
    final selected = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2035), initialDate: from ? (_from ?? DateTime.now()) : (_to ?? DateTime.now()));
    if (selected != null) setState(() => from ? _from = selected : _to = selected);
  }

  Future<void> _exportCsv() async {
    try {
      final sessionIds = _sessions.map((session) => session.sessionId).toSet();
      final rows = <String>['roll_number,full_name,class_code,session_date,slot,status'];
      for (final attendance in widget.stats.attendance.where((row) => sessionIds.contains(row.sessionId))) {
        final session = _sessions.firstWhere((item) => item.sessionId == attendance.sessionId);
        final student = widget.stats.students.firstWhere((item) => item.studentId == attendance.studentId, orElse: () => Student(studentId: attendance.studentId, studentName: 'Unknown student', classId: session.classCode, email: ''));
        rows.add([student.studentCode, student.fullName, session.classCode, session.sessionDate, session.slot, attendance.status].map(_csv).join(','));
      }
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}${Platform.pathSeparator}fap_attendance_export.csv');
      await file.writeAsString('${rows.join('\n')}\n');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported ${rows.length - 1} rows to ${file.path}')));
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
        final classes = ['all', ...widget.stats.students.map((student) => student.classId).toSet().where((value) => value.isNotEmpty).toList()..sort()];
        return ListView(padding: const EdgeInsets.all(24), children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Export', style: Theme.of(context).textTheme.headlineLarge), const SizedBox(height: 4), Text('Review synchronization status and export attendance rows.', style: Theme.of(context).textTheme.bodyMedium)])),
            FilledButton.icon(onPressed: _exportCsv, icon: const Icon(Icons.download_outlined), label: const Text('Export CSV')),
          ]),
          const SizedBox(height: 18),
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Wrap(spacing: 12, runSpacing: 10, children: [
            SizedBox(width: 180, child: DropdownButtonFormField<String>(initialValue: _classCode, decoration: const InputDecoration(labelText: 'Class'), items: classes.map((value) => DropdownMenuItem(value: value, child: Text(value == 'all' ? 'All classes' : value))).toList(), onChanged: (value) => setState(() => _classCode = value ?? 'all'))),
            OutlinedButton.icon(onPressed: () => _pickDate(true), icon: const Icon(Icons.date_range), label: Text(_from == null ? 'From date' : _dateText(_from!))),
            OutlinedButton.icon(onPressed: () => _pickDate(false), icon: const Icon(Icons.date_range), label: Text(_to == null ? 'To date' : _dateText(_to!))),
            TextButton(onPressed: () => setState(() { _from = null; _to = null; _classCode = 'all'; }), child: const Text('Clear filters')),
          ]))),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: const WidgetStatePropertyAll(AppColors.primaryDark),
                headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                columns: const [DataColumn(label: Text('SESSION')), DataColumn(label: Text('CLASS')), DataColumn(label: Text('DATE')), DataColumn(label: Text('SLOT')), DataColumn(label: Text('SYNC STATUS'))],
                rows: _sessions.map((session) => DataRow(cells: [
                  DataCell(Text(session.sessionId)),
                  DataCell(Text(session.classCode)),
                  DataCell(Text(session.sessionDate)),
                  DataCell(Text(session.slot)),
                  DataCell(Text(_syncStatus(session.sessionId), style: const TextStyle(fontWeight: FontWeight.w700))),
                ])).toList(),
              ),
            ),
          ),
        ]);
      },
    );
  }

  String _syncStatus(String sessionId) {
    final statuses = widget.stats.attendance.where((row) => row.sessionId == sessionId).map((row) => row.syncStatus).toSet();
    if (statuses.isEmpty) return 'not_taken';
    if (statuses.contains('draft')) return 'draft';
    return 'submitted';
  }

  String _dateText(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
