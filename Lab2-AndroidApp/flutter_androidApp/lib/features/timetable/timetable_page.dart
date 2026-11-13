import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/attendance_stats_service.dart';

class TimetablePage extends StatefulWidget {
  final AttendanceStatsService stats;
  final void Function(String sessionId) onSessionSelected;

  const TimetablePage({super.key, required this.stats, required this.onSessionSelected});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  late Future<void> _loadFuture;
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _weekStart = DateTime(today.year, today.month, today.day).subtract(Duration(days: today.weekday - 1));
    _loadFuture = widget.stats.load();
  }

  void _moveWeek(int amount) => setState(() => _weekStart = _weekStart.add(Duration(days: amount * 7)));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Could not load timetable: ${snapshot.error}'));
        final narrow = MediaQuery.sizeOf(context).width < 700;
        return ListView(padding: EdgeInsets.all(narrow ? 16 : 24), children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Timetable', style: Theme.of(context).textTheme.headlineLarge),
              Text('${_formatDate(_weekStart)} - ${_formatDate(_weekStart.add(const Duration(days: 6)))}'),
            ])),
            IconButton(tooltip: 'Previous week', onPressed: () => _moveWeek(-1), icon: const Icon(Icons.chevron_left)),
            OutlinedButton(onPressed: () => setState(() => _weekStart = _startOfWeek(DateTime.now())), child: const Text('Today')),
            IconButton(tooltip: 'Next week', onPressed: () => _moveWeek(1), icon: const Icon(Icons.chevron_right)),
          ]),
          const SizedBox(height: 18),
          // A 7-day grid needs ~1280px, so phones get a day-by-day list instead.
          if (narrow) ..._dayList(context) else Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1280,
                child: Column(children: [
                  _headerRow(),
                  ...List.generate(8, (slotIndex) => _slotRow(slotIndex + 1)),
                ]),
              ),
            ),
          ),
        ]);
      },
    );
  }

  List<Widget> _dayList(BuildContext context) {
    final widgets = <Widget>[];
    for (var i = 0; i < 7; i++) {
      final date = _weekStart.add(Duration(days: i));
      final sessions = widget.stats.sessions.where((session) => _sameDate(session.sessionDate, date)).toList()
        ..sort((a, b) => _slotNumber(a.slot).compareTo(_slotNumber(b.slot)));
      widgets.add(Padding(
        padding: EdgeInsets.only(top: i == 0 ? 0 : 16, bottom: 8),
        child: Text('${_dayName(date.weekday)}  ${_formatDate(date)}', style: Theme.of(context).textTheme.headlineMedium),
      ));
      if (sessions.isEmpty) {
        widgets.add(Text('No sessions', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)));
      }
      for (final session in sessions) {
        final status = widget.stats.sessionStatus(session);
        final color = _statusColor(status);
        widgets.add(Card(
          margin: const EdgeInsets.only(bottom: 8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => widget.onSessionSelected(session.sessionId),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.08), border: Border(left: BorderSide(color: color, width: 4))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Slot ${_slotNumber(session.slot)}  ·  ${session.subjectCode}  ·  ${session.classCode}', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${session.subjectName}  ·  ${session.room}'),
                const SizedBox(height: 2),
                Text(status.value, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
              ]),
            ),
          ),
        ));
      }
    }
    return widgets;
  }

  Widget _headerRow() => Row(children: [
        const SizedBox(width: 92, child: Padding(padding: EdgeInsets.all(10), child: Text('SLOT', style: TextStyle(fontWeight: FontWeight.w700)))),
        ...List.generate(7, (index) {
          final date = _weekStart.add(Duration(days: index));
          return Expanded(child: Container(color: AppColors.primaryDark, padding: const EdgeInsets.all(10), child: Text('${_dayName(date.weekday)}\n${_formatDate(date)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))));
        }),
      ]);

  Widget _slotRow(int slot) => SizedBox(height: 92, child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(width: 92, child: Container(color: AppColors.surfaceContainer, padding: const EdgeInsets.all(12), child: Text('Slot $slot', style: const TextStyle(fontWeight: FontWeight.w700)))),
        ...List.generate(7, (dayIndex) {
          final date = _weekStart.add(Duration(days: dayIndex));
          final sessions = widget.stats.sessions.where((session) => _sameDate(session.sessionDate, date) && _slotNumber(session.slot) == slot).toList();
          return Expanded(
            child: Container(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)), right: BorderSide(color: Color(0xFFE2E8F0)))),
              padding: const EdgeInsets.all(4),
              child: Column(children: sessions.map((session) {
                final status = widget.stats.sessionStatus(session);
                return Expanded(
                  child: InkWell(
                    onTap: () => widget.onSessionSelected(session.sessionId),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: _statusColor(status).withValues(alpha: 0.12), border: Border(left: BorderSide(color: _statusColor(status), width: 4)), borderRadius: BorderRadius.circular(4)),
                      child: Text('${session.subjectCode}\n${session.classCode}\n${status.value}', style: TextStyle(fontSize: 11, color: _statusColor(status), fontWeight: FontWeight.w700)),
                    ),
                  ),
                );
              }).toList()),
            ),
          );
        }),
      ]));

  DateTime _startOfWeek(DateTime date) => DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));

  bool _sameDate(String value, DateTime date) {
    final parsed = DateTime.tryParse(value);
    return parsed != null && parsed.year == date.year && parsed.month == date.month && parsed.day == date.day;
  }

  int _slotNumber(String value) => int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  String _formatDate(DateTime date) => '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  String _dayName(int weekday) => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];

  Color _statusColor(SessionStatus status) => switch (status) {
        SessionStatus.taken => AppColors.green,
        SessionStatus.inProgress => AppColors.tertiary,
        SessionStatus.overdueNotTaken => AppColors.error,
        SessionStatus.notTaken => AppColors.primary,
      };
}
