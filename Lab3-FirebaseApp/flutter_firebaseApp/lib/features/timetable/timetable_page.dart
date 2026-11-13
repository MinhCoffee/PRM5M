import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/state_view.dart';
import '../../services/attendance_stats_service.dart';
import 'viewmodel/timetable_viewmodel.dart';

class TimetablePage extends StatefulWidget {
  final TimetableViewModel viewModel;
  final void Function(String sessionId) onSessionSelected;

  const TimetablePage({
    super.key,
    required this.viewModel,
    required this.onSessionSelected,
  });

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadTimetable();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return StateView<TimetableData>(
          state: widget.viewModel.state,
          loadingMessage: 'Đang tải lịch giảng dạy...',
          onRetry: () => widget.viewModel.loadTimetable(),
          onData: (context, data) => _buildContent(context, data),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, TimetableData data) {
    final narrow = MediaQuery.sizeOf(context).width < 700;
    final weekStart = data.weekStart;
    final weekEnd = weekStart.add(const Duration(days: 6));

    return ListView(
      padding: EdgeInsets.all(narrow ? 16 : 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thời khóa biểu tuần',
                      style: Theme.of(context).textTheme.headlineLarge),
                  Text(
                    '${_formatDate(weekStart)}  đến  ${_formatDate(weekEnd)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Tuần trước',
              onPressed: () => widget.viewModel.moveWeek(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            OutlinedButton(
              onPressed: () => widget.viewModel.resetToCurrentWeek(),
              child: const Text('Tuần này'),
            ),
            IconButton(
              tooltip: 'Tuần sau',
              onPressed: () => widget.viewModel.moveWeek(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (narrow)
          ..._dayList(context, data)
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1280,
                child: Column(
                  children: [
                    _headerRow(weekStart),
                    ...List.generate(
                      8,
                      (slotIndex) => _slotRow(slotIndex + 1, data),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _dayList(BuildContext context, TimetableData data) {
    final widgets = <Widget>[];

    for (var i = 0; i < 7; i++) {
      final date = data.weekStart.add(Duration(days: i));
      final sessions = data.sessions
          .where((s) => _sameDate(s.sessionDate, date))
          .toList()
        ..sort((a, b) => _slotNumber(a.slot).compareTo(_slotNumber(b.slot)));

      widgets.add(Padding(
        padding: EdgeInsets.only(top: i == 0 ? 0 : 16, bottom: 8),
        child: Text(
          '${_dayName(date.weekday)}  -  ${_formatDate(date)}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ));

      if (sessions.isEmpty) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              'Không có ca học',
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
            ),
          ),
        );
      }

      for (final session in sessions) {
        final status = widget.viewModel.sessionStatus(session);
        final color = _statusColor(status);

        widgets.add(Card(
          margin: const EdgeInsets.only(bottom: 8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => widget.onSessionSelected(session.sessionId),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                border: Border(left: BorderSide(color: color, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ca ${_slotNumber(session.slot)}  ·  ${session.subjectCode}  ·  Lớp ${session.classCode}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text('${session.subjectName}  ·  Phòng ${session.room}'),
                  const SizedBox(height: 4),
                  Text(
                    status.value,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
      }
    }
    return widgets;
  }

  Widget _headerRow(DateTime weekStart) => Row(
        children: [
          const SizedBox(
            width: 92,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Text('CA HỌC', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          ...List.generate(7, (index) {
            final date = weekStart.add(Duration(days: index));
            return Expanded(
              child: Container(
                color: AppColors.primaryDark,
                padding: const EdgeInsets.all(10),
                child: Text(
                  '${_dayName(date.weekday)}\n${_formatDate(date)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ],
      );

  Widget _slotRow(int slot, TimetableData data) => SizedBox(
        height: 92,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 92,
              child: Container(
                color: AppColors.surfaceContainer,
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Slot $slot',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ...List.generate(7, (dayIndex) {
              final date = data.weekStart.add(Duration(days: dayIndex));
              final sessions = data.sessions
                  .where((s) =>
                      _sameDate(s.sessionDate, date) &&
                      _slotNumber(s.slot) == slot)
                  .toList();

              return Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                      right: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: sessions.map((s) {
                      final status = widget.viewModel.sessionStatus(s);
                      final color = _statusColor(status);

                      return Expanded(
                        child: InkWell(
                          onTap: () => widget.onSessionSelected(s.sessionId),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              border: Border(left: BorderSide(color: color, width: 4)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${s.subjectCode}\n${s.classCode}\n${status.value}',
                              style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            }),
          ],
        ),
      );

  bool _sameDate(String value, DateTime date) {
    final parsed = DateTime.tryParse(value);
    return parsed != null &&
        parsed.year == date.year &&
        parsed.month == date.month &&
        parsed.day == date.day;
  }

  int _slotNumber(String value) =>
      int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

  String _dayName(int weekday) =>
      const ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'][weekday - 1];

  Color _statusColor(SessionStatus status) => switch (status) {
        SessionStatus.taken => AppColors.green,
        SessionStatus.inProgress => AppColors.tertiary,
        SessionStatus.overdueNotTaken => AppColors.error,
        SessionStatus.notTaken => AppColors.primary,
      };
}
