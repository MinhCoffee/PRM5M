import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/attendance_stats_service.dart';

class ReportsPage extends StatefulWidget {
  final AttendanceStatsService stats;

  const ReportsPage({super.key, required this.stats});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late Future<void> _loadFuture;
  String _semester = 'all';
  String _subject = 'all';
  String _classCode = 'all';

  @override
  void initState() {
    super.initState();
    _loadFuture = widget.stats.load();
  }

  List<String> get _semesters {
    final values = widget.stats.sessions.map((session) => DateTime.tryParse(session.sessionDate)?.year.toString()).whereType<String>().toSet().toList()..sort((a, b) => b.compareTo(a));
    return ['all', ...values];
  }

  List<String> get _subjects => ['all', ...widget.stats.sessions.map((session) => session.subjectCode).where((value) => value.isNotEmpty).toSet().toList()..sort()];

  List<String> get _classes => ['all', ...widget.stats.students.map((student) => student.classId).where((value) => value.isNotEmpty).toSet().toList()..sort()];

  List<AttendanceStudentStats> get _rows {
    final allowedClasses = _classCode == 'all' ? null : {_classCode};
    final allowedSessions = widget.stats.sessions.where((session) {
      final yearMatches = _semester == 'all' || session.sessionDate.startsWith('$_semester-');
      final subjectMatches = _subject == 'all' || session.subjectCode == _subject;
      final classMatches = _classCode == 'all' || session.classCode == _classCode;
      return yearMatches && subjectMatches && classMatches;
    }).map((session) => session.classCode).toSet();
    final result = widget.stats.students.where((student) => (allowedClasses == null || allowedClasses.contains(student.classId)) && allowedSessions.contains(student.classId)).map(widget.stats.studentStats).toList();
    result.sort((a, b) => b.absenceRate.compareTo(a.absenceRate));
    return result;
  }

  Future<void> _exportCsv() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}${Platform.pathSeparator}fap_attendance_report.csv');
      final lines = <String>['student_code,full_name,class_code,sessions_held,absent_count,absence_rate,status'];
      for (final row in _rows) {
        lines.add([
          row.student.studentCode,
          row.student.fullName,
          row.student.classId,
          row.sessionsHeld,
          row.absentCount,
          '${(row.absenceRate * 100).toStringAsFixed(1)}%',
          row.status.value,
        ].map(_csv).join(','));
      }
      await file.writeAsString('${lines.join('\n')}\n');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report exported to ${file.path}')));
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
        if (snapshot.hasError) return Center(child: Text('Could not load report data: ${snapshot.error}'));
        return ListView(padding: const EdgeInsets.all(24), children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Reports', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 4),
              Text('Student attendance risk by class and subject.', style: Theme.of(context).textTheme.bodyMedium),
            ])),
            OutlinedButton.icon(onPressed: _exportCsv, icon: const Icon(Icons.download_outlined), label: const Text('Export CSV')),
          ]),
          const SizedBox(height: 20),
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Wrap(spacing: 12, runSpacing: 10, children: [
            _filter('Semester', _semester, _semesters, (value) => setState(() => _semester = value!)),
            _filter('Subject', _subject, _subjects, (value) => setState(() => _subject = value!)),
            _filter('Class', _classCode, _classes, (value) => setState(() => _classCode = value!)),
          ]))),
          const SizedBox(height: 16),
          Card(clipBehavior: Clip.antiAlias, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
            headingRowColor: const WidgetStatePropertyAll(AppColors.primaryDark),
            headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            columns: const [
              DataColumn(label: Text('STUDENT')),
              DataColumn(label: Text('CLASS')),
              DataColumn(label: Text('SESSIONS HELD')),
              DataColumn(label: Text('ABSENT')),
              DataColumn(label: Text('ABSENCE %')),
              DataColumn(label: Text('STATUS')),
            ],
            rows: _rows.map((row) => DataRow(cells: [
              DataCell(Text('${row.student.studentCode}  ${row.student.fullName}')),
              DataCell(Text(row.student.classId)),
              DataCell(Text('${row.sessionsHeld}')),
              DataCell(Text('${row.absentCount}')),
              DataCell(Text('${(row.absenceRate * 100).toStringAsFixed(1)}%')),
              DataCell(Text(row.status.value.toUpperCase(), style: TextStyle(color: row.status == StudentRiskStatus.banned ? AppColors.error : row.status == StudentRiskStatus.warning ? AppColors.tertiary : AppColors.green, fontWeight: FontWeight.w700))),
            ])).toList(),
          ))),
        ]);
      },
    );
  }

  Widget _filter(String label, String value, List<String> values, ValueChanged<String?> onChanged) => SizedBox(width: 190, child: DropdownButtonFormField<String>(initialValue: value, decoration: InputDecoration(labelText: label), items: values.map((item) => DropdownMenuItem(value: item, child: Text(item == 'all' ? 'All' : item))).toList(), onChanged: onChanged));
}
