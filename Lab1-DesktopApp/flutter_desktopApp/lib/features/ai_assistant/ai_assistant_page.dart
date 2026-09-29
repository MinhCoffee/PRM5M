import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/attendance_stats_service.dart';

class AiAssistantPage extends StatefulWidget {
  final AttendanceStatsService stats;

  const AiAssistantPage({super.key, required this.stats});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  late Future<void> _loadFuture;
  final List<String> _messages = [];
  String? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    _loadFuture = widget.stats.load();
  }

  void _atRisk() {
    final rows =
        widget.stats.students
            .map(
              (student) => widget.stats.studentStatsAcrossAllSubjects(
                student,
                usePolicyThresholds: true,
              ),
            )
            .where((row) => row.status != StudentRiskStatus.ok)
            .toList()
          ..sort((a, b) => b.absenceRate.compareTo(a.absenceRate));
    final warningRows = rows
        .where((row) => row.status == StudentRiskStatus.warning)
        .toList();
    final bannedRows = rows
        .where((row) => row.status == StudentRiskStatus.banned)
        .toList();
    final text = rows.isEmpty
        ? 'AI scanned all subjects and found no students above the 15% absence warning threshold.'
        : [
            'AI scanned all subjects. Rule: >15% to 20% is warning, >20% is banned.',
            if (bannedRows.isNotEmpty)
              'Banned: ${bannedRows.take(10).map(_studentRiskText).join('; ')}.',
            if (warningRows.isNotEmpty)
              'Warning: ${warningRows.take(10).map(_studentRiskText).join('; ')}.',
          ].join(' ');
    setState(() => _messages.add(text));
  }

  void _highestSubject() {
    final subjects = widget.stats.subjectStats(usePolicyThresholds: true)
      ..sort((a, b) => b.absenceRate.compareTo(a.absenceRate));
    if (subjects.isEmpty) {
      setState(() => _messages.add('No subject attendance data is available.'));
      return;
    }
    final top = subjects.first;
    setState(
      () => _messages.add(
        'Subject/class with highest absence is ${top.subjectCode} ${top.classCode} at ${_percent(top.absenceRate)} '
        '(${top.absentCount}/${top.recordsCount} attendance records), status ${_riskLabel(top.status)}.',
      ),
    );
  }

  void _studentHistory() {
    final id = _selectedStudentId;
    if (id == null) return;
    final studentList = widget.stats.students;
    // Guard: id must still exist in current list
    final matches = studentList.where((item) => item.studentId == id);
    if (matches.isEmpty) return;
    final student = matches.first;
    final row = widget.stats.studentStatsAcrossAllSubjects(
      student,
      usePolicyThresholds: true,
    );
    final subjects = widget.stats.subjectStatsForStudent(
      student,
      usePolicyThresholds: true,
    );
    final subjectText = subjects.isEmpty
        ? 'No subject-level attendance rows found.'
        : subjects
              .map(
                (subject) =>
                    '${subject.subjectCode} ${subject.classCode}: ${subject.absentCount}/${subject.recordsCount} absent, ${_percent(subject.absenceRate)}, ${_riskLabel(subject.status)}',
              )
              .join('; ');
    setState(
      () => _messages.add(
        '${student.studentCode} ${student.fullName}: ${row.absentCount} absent across ${row.sessionsHeld} attendance rows from all subjects, '
        '${_percent(row.absenceRate)}, status ${_riskLabel(row.status)}. $subjectText',
      ),
    );
  }

  String _studentRiskText(AttendanceStudentStats row) =>
      '${row.student.studentCode} ${row.student.fullName} ${_percent(row.absenceRate)} (${row.absentCount}/${row.sessionsHeld})';

  String _percent(double value) => '${(value * 100).toStringAsFixed(1)}%';

  String _riskLabel(StudentRiskStatus status) => switch (status) {
    StudentRiskStatus.ok => 'OK',
    StudentRiskStatus.warning => 'WARNING',
    StudentRiskStatus.banned => 'BANNED',
  };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load assistant data: ${snapshot.error}'),
          );
        }

        final students = [...widget.stats.students]
          ..sort((a, b) => a.fullName.compareTo(b.fullName));

        // Validate _selectedStudentId: must be null or in the current list.
        // Never set a value that isn't present in the DropdownButton's items.
        final validIds = students.map((s) => s.studentId).toSet();
        if (_selectedStudentId != null &&
            !validIds.contains(_selectedStudentId)) {
          _selectedStudentId = null;
        }
        _selectedStudentId ??= students.isEmpty
            ? null
            : students.first.studentId;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'AI Assistant',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Rule-based answers across all subjects: >15% to 20% absence is warning, >20% is banned.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: _atRisk,
                      icon: const Icon(Icons.warning_amber_outlined),
                      label: const Text('At-risk students'),
                    ),
                    FilledButton.icon(
                      onPressed: _highestSubject,
                      icon: const Icon(Icons.leaderboard_outlined),
                      label: const Text('Highest absence subject'),
                    ),
                    SizedBox(
                      width: 260,
                      child: DropdownButtonFormField<String>(
                        // initialValue and items always come from the SAME source list.
                        // Dropdown is disabled when list is empty.
                        initialValue: students.isEmpty
                            ? null
                            : _selectedStudentId,
                        decoration: const InputDecoration(
                          labelText: 'Student history',
                        ),
                        items: students
                            .map(
                              (student) => DropdownMenuItem(
                                value: student.studentId,
                                child: Text(
                                  '${student.studentCode} ${student.fullName}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: students.isEmpty
                            ? null // disables the dropdown gracefully
                            : (value) =>
                                  setState(() => _selectedStudentId = value),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: students.isEmpty ? null : _studentHistory,
                      icon: const Icon(Icons.history),
                      label: const Text('Ask history'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _messages.isEmpty
                    ? const Text('Choose a question to calculate an answer.')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _messages
                            .map(
                              (message) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.smart_toy_outlined,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(message)),
                                  ],
                                ),
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
}
