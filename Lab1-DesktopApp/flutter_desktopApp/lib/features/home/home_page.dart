import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/attendance_stats_service.dart';

class HomePage extends StatefulWidget {
  final AttendanceStatsService stats;
  final void Function(String sessionId) onSessionSelected;

  const HomePage({super.key, required this.stats, required this.onSessionSelected});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = widget.stats.load();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isToday(String value) {
    final date = DateTime.tryParse(value);
    return date != null && DateTime(date.year, date.month, date.day) == _today;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Could not load home data: ${snapshot.error}'));
        final todaySessions = widget.stats.sessions.where((session) => _isToday(session.sessionDate)).toList()..sort((a, b) => _slotNumber(a.slot).compareTo(_slotNumber(b.slot)));
        final heldRows = widget.stats.attendance.where((row) => widget.stats.sessions.any((session) => session.sessionId == row.sessionId && _isOnOrBeforeToday(session.sessionDate))).toList();
        final overallRate = heldRows.isEmpty ? 0.0 : heldRows.where((row) => row.status == 'present').length / heldRows.length;
        final bannedStudents = widget.stats.students.map(widget.stats.studentStats).where((row) => row.status == StudentRiskStatus.banned).length;
        final draftSessions = widget.stats.attendance.where((row) => row.syncStatus == 'draft').map((row) => row.sessionId).toSet().length;
        return ListView(padding: const EdgeInsets.all(24), children: [
          Text('Home', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text('Attendance overview for ${_today.year}-${_twoDigits(_today.month)}-${_twoDigits(_today.day)}.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _statCard('Classes today', '${todaySessions.length}', Icons.calendar_today_outlined, AppColors.primary),
            _statCard('Overall attendance', '${(overallRate * 100).toStringAsFixed(1)}%', Icons.how_to_reg_outlined, AppColors.green),
            _statCard('Banned students', '$bannedStudents', Icons.warning_amber_outlined, AppColors.error),
            _statCard('Draft sessions', '$draftSessions', Icons.drafts_outlined, AppColors.tertiary),
          ]),
          const SizedBox(height: 24),
          Text("Today's sessions", style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          if (todaySessions.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No sessions scheduled for today.'))),
          ...todaySessions.map((session) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  onTap: () => widget.onSessionSelected(session.sessionId),
                  leading: CircleAvatar(backgroundColor: _statusColor(widget.stats.sessionStatus(session)).withValues(alpha: 0.14), child: Icon(Icons.class_outlined, color: _statusColor(widget.stats.sessionStatus(session)))),
                  title: Text('${session.subjectCode}  ·  ${session.classCode}'),
                  subtitle: Text('${session.subjectName}  ·  ${session.room}  ·  ${session.slot}'),
                  trailing: Chip(label: Text(widget.stats.sessionStatus(session).value)),
                ),
              )),
          const SizedBox(height: 32),
          Text('How to use this app', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📚 Quick Guide for Teachers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Text('1. Take Attendance: Click on a class session under "Today\'s sessions" or via the "Take Attendance" tab. You can mark students as Present or Absent and add notes.'),
                  SizedBox(height: 8),
                  Text('2. My Classes: Monitor your ongoing classes. A progress bar indicates how many sessions have passed out of the total. You can see how many students are at risk.'),
                  SizedBox(height: 8),
                  Text('3. Reports: View a detailed breakdown of student absences across all classes. Use filters to narrow down by semester, subject, or class.'),
                  SizedBox(height: 16),
                  Text('🔍 Session Status Glossary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('• Upcoming: The session is scheduled in the future.'),
                  Text('• Taking Attendance: The session is today and attendance is being recorded.'),
                  Text('• Completed: The session has passed and attendance has been successfully submitted.'),
                  Text('• Missing Attendance: The session has passed, but attendance was never recorded.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ]);
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) => SizedBox(width: 250, child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)), child: Icon(icon, color: color)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12)), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))]),
      ]))));

  int _slotNumber(String slot) => int.tryParse(slot.replaceAll(RegExp(r'[^0-9]'), '')) ?? 99;

  bool _isOnOrBeforeToday(String value) {
    final date = DateTime.tryParse(value);
    return date != null && !date.isAfter(_today);
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  Color _statusColor(SessionStatus status) => switch (status) {
        SessionStatus.taken => AppColors.green,
        SessionStatus.inProgress => AppColors.tertiary,
        SessionStatus.overdueNotTaken => AppColors.error,
        SessionStatus.notTaken => AppColors.primary,
      };
}
