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

  @override
  Widget build(BuildContext context) {
    final sessions = widget.repository.sessions;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Take Attendance', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 4),
            Text('Select a class session to open the attendance workbench.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 28),
            _subjectRow(context, 'Today\'s sessions', sessions, _todayController),
            const SizedBox(height: 28),
            _subjectRow(context, 'Upcoming classes', [...sessions.reversed, sessions.first], _upcomingController),
          ]),
        ),
      ),
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