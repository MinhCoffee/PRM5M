import 'package:flutter/material.dart';
import 'data/attendance_repository.dart';

class AttendanceBrowsePage extends StatefulWidget {
  final AttendanceRepository repository;
  final void Function(AttendanceSession session) onSessionSelected;

  const AttendanceBrowsePage({super.key, required this.repository, required this.onSessionSelected});

  @override
  State<AttendanceBrowsePage> createState() => _AttendanceBrowsePageState();
}

class _AttendanceBrowsePageState extends State<AttendanceBrowsePage> {
  final _todayController = ScrollController();
  final _upcomingController = ScrollController();
  double _dragStart = 0;
  late Future<List<AttendanceSession>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = widget.repository.getSessions();
  }

  @override
  void dispose() {
    _todayController.dispose();
    _upcomingController.dispose();
    super.dispose();
  }

  void _scrollBy(ScrollController controller, double offset) {
    final target = (controller.offset + offset).clamp(0.0, controller.position.maxScrollExtent);
    controller.animateTo(target, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  Future<void> _seedSampleData() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Regenerate sample data?'),
            content: const Text(
              'This will DELETE all existing data in the students, schedule, and attendance tabs, '
              'then generate a fresh randomized dataset.\n\nOnly use this on a test spreadsheet.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete & regenerate'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    try {
      final result = await widget.repository.seedSampleData();
      if (!mounted) return;
      setState(() => _sessionsFuture = widget.repository.getSessions());
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Generated ${result.subjectCount} subjects, ${result.classCount} classes, '
          '${result.studentsAdded} students, ${result.sessionsAdded} sessions.',
        ),
        duration: const Duration(seconds: 5),
      ));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create sample data: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AttendanceSession>>(
      future: _sessionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Could not load sessions: ${snapshot.error}')));
        }
        final sessions = snapshot.data ?? const <AttendanceSession>[];
        if (sessions.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('No sessions found in the schedule sheet.'),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: _seedSampleData, icon: const Icon(Icons.science_outlined), label: const Text('Create sample data')),
          ]));
        }
        return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Take Attendance', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 4),
                Text('Select a class session to open the attendance workbench.', style: Theme.of(context).textTheme.bodyMedium),
              ])),
              OutlinedButton.icon(onPressed: _seedSampleData, icon: const Icon(Icons.science_outlined), label: const Text('Seed sample data')),
            ]),
            const SizedBox(height: 28),
            _subjectRow(context, 'Today\'s sessions', sessions, _todayController),
            const SizedBox(height: 28),
            _subjectRow(context, 'Upcoming classes', [...sessions.reversed, sessions.first], _upcomingController),
          ]),
        ),
      ),
        );
      },
    );
  }

  Widget _subjectRow(BuildContext context, String title, List<AttendanceSession> sessions, ScrollController controller) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const Spacer(),
          IconButton(tooltip: 'Scroll left', onPressed: () => _scrollBy(controller, -320), icon: const Icon(Icons.chevron_left)),
          IconButton(tooltip: 'Scroll right', onPressed: () => _scrollBy(controller, 320), icon: const Icon(Icons.chevron_right)),
        ]),
        const SizedBox(height: 12),
        GestureDetector(
          onHorizontalDragStart: (details) => _dragStart = details.globalPosition.dx,
          onHorizontalDragUpdate: (details) {
            final delta = _dragStart - details.globalPosition.dx;
            _dragStart = details.globalPosition.dx;
            controller.jumpTo((controller.offset + delta).clamp(0.0, controller.position.maxScrollExtent));
          },
          child: SingleChildScrollView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            child: Row(children: sessions.map((session) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _sessionCard(context, session),
            )).toList()),
          ),
        ),
      ]);

  Widget _sessionCard(BuildContext context, AttendanceSession session) => SizedBox(
        width: 300,
        child: InkWell(
          onTap: () => widget.onSessionSelected(session),
          borderRadius: BorderRadius.circular(6),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(height: 8, color: session.accentColor),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(session.subjectCode, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: session.accentColor)),
                  const SizedBox(height: 4),
                  Text(session.subjectName, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 18),
                  Text('${session.className}  ·  ${session.room}', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text('${session.date}  ·  ${session.schedule}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 14),
                  Row(children: [
                    Text('Session ${session.sessionNumber}/${session.totalSessions}', style: Theme.of(context).textTheme.labelMedium),
                    const Spacer(),
                    const Icon(Icons.arrow_forward, size: 18),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      );
}