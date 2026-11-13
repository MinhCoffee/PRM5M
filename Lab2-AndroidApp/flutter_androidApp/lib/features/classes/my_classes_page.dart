import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/attendance_stats_service.dart';

class MyClassesPage extends StatefulWidget {
  final AttendanceStatsService stats;
  final void Function(String sessionId) onSessionSelected;

  const MyClassesPage({super.key, required this.stats, required this.onSessionSelected});

  @override
  State<MyClassesPage> createState() => _MyClassesPageState();
}

class _MyClassesPageState extends State<MyClassesPage> {
  late Future<void> _loadFuture;
  String? _selectedClass;

  @override
  void initState() {
    super.initState();
    _loadFuture = widget.stats.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Could not load classes: ${snapshot.error}'));
        final classStats = widget.stats.classStats();
        if (_selectedClass != null) return _sessionsView(context, _selectedClass!, classStats);
        final narrow = MediaQuery.sizeOf(context).width < 700;
        return ListView(padding: EdgeInsets.all(narrow ? 16 : 24), children: [
          Text('My Classes', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text('Class progress and student risk overview.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          // The six-column table is wider than a phone, so show one card per class there.
          if (narrow) ...classStats.map(_classCard) else Card(clipBehavior: Clip.antiAlias, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
            headingRowColor: const WidgetStatePropertyAll(AppColors.primaryDark),
            headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            columns: const [
              DataColumn(label: Text('CLASS')),
              DataColumn(label: Text('SUBJECT')),
              DataColumn(label: Text('STUDENTS')),
              DataColumn(label: Text('PROGRESS')),
              DataColumn(label: Text('WARNING')),
              DataColumn(label: Text('BANNED')),
            ],
            rows: classStats.map((item) => DataRow(onSelectChanged: (_) => setState(() => _selectedClass = item.classCode), cells: [
              DataCell(Text(item.classCode, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary))),
              DataCell(Text(item.subjectName)),
              DataCell(Text('${item.studentCount}')),
              DataCell(SizedBox(width: 180, child: LinearProgressIndicator(value: item.progress, minHeight: 8))),
              DataCell(Text('${item.warningCount}', style: const TextStyle(color: AppColors.tertiary, fontWeight: FontWeight.w700))),
              DataCell(Text('${item.bannedCount}', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700))),
            ])).toList(),
          ))),
        ]);
      },
    );
  }

  Widget _classCard(AttendanceClassStats item) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => _selectedClass = item.classCode),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(item.classCode, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(width: 10),
                Expanded(child: Text(item.subjectName, overflow: TextOverflow.ellipsis)),
                const Icon(Icons.chevron_right, color: AppColors.outline),
              ]),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: item.progress, minHeight: 8),
              const SizedBox(height: 10),
              Wrap(spacing: 16, runSpacing: 4, children: [
                Text('${item.studentCount} students'),
                Text('${(item.progress * 100).toStringAsFixed(0)}% progress'),
                Text('Warning ${item.warningCount}', style: const TextStyle(color: AppColors.tertiary, fontWeight: FontWeight.w700)),
                Text('Banned ${item.bannedCount}', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
              ]),
            ]),
          ),
        ),
      );

  Widget _sessionsView(BuildContext context, String classCode, List<AttendanceClassStats> classStats) {
    final sessions = widget.stats.sessions.where((session) => session.classCode == classCode).toList()..sort((a, b) => a.sessionNo.compareTo(b.sessionNo));
    final classSummary = classStats.firstWhere((item) => item.classCode == classCode);
    final narrow = MediaQuery.sizeOf(context).width < 700;
    return ListView(padding: EdgeInsets.all(narrow ? 16 : 24), children: [
      Row(children: [
        IconButton(tooltip: 'Back to classes', onPressed: () => setState(() => _selectedClass = null), icon: const Icon(Icons.arrow_back)),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(classCode, style: Theme.of(context).textTheme.headlineLarge),
          Text('${classSummary.subjectName}  ·  ${classSummary.studentCount} students  ·  ${(classSummary.progress * 100).toStringAsFixed(0)}% progress'),
        ])),
      ]),
      const SizedBox(height: 18),
      ...sessions.map((session) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              onTap: () => widget.onSessionSelected(session.sessionId),
              title: Text('Session ${session.sessionNo}/${session.totalSessions}  ·  ${session.subjectCode}'),
              subtitle: Text('${session.sessionDate}  ·  ${session.slot}  ·  ${session.room}'),
              trailing: Chip(label: Text(widget.stats.sessionStatus(session).value)),
            ),
          )),
    ]);
  }
}
