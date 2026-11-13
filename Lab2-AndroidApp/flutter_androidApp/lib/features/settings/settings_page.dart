import 'package:flutter/material.dart';
import '../../services/attendance_stats_service.dart';

class SettingsPage extends StatefulWidget {
  final AttendanceStatsService stats;

  const SettingsPage({super.key, required this.stats});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<void> _loadFuture;
  final _warnController = TextEditingController();
  final _banController = TextEditingController();
  bool _seeding = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadSettings();
  }

  Future<void> _loadSettings() async {
    await widget.stats.load();
    _warnController.text = (widget.stats.warnThreshold * 100).toStringAsFixed(1);
    _banController.text = (widget.stats.banThreshold * 100).toStringAsFixed(1);
  }

  @override
  void dispose() {
    _warnController.dispose();
    _banController.dispose();
    super.dispose();
  }

  Future<void> _seedSampleData() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Regenerate sample data?'),
            content: const Text(
              'This will DELETE all existing data in the students, schedule, and attendance tabs, '
              'then generate a fresh randomized dataset with varied subjects, classes, and students.\n\n'
              'Only use this on a test spreadsheet.',
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
    setState(() => _seeding = true);
    try {
      final result = await widget.stats.seedSampleData();
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Generated ${result.subjectCount} subjects, ${result.classCount} classes, '
          '${result.studentsAdded} students, ${result.sessionsAdded} sessions, '
          '${result.attendanceAdded} attendance rows.',
        ),
        duration: const Duration(seconds: 5),
      ));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Seed failed: $error')));
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Future<void> _saveThresholds() async {
    final warn = double.tryParse(_warnController.text.trim());
    final ban = double.tryParse(_banController.text.trim());
    if (warn == null || ban == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thresholds must be numbers between 0 and 100.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.stats.setThresholds(warn: warn / 100, ban: ban / 100);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thresholds saved and shared across all pages.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save thresholds: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Could not load settings: ${snapshot.error}'));
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 6),
            Text('Configure shared attendance rules and demo data.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Attendance thresholds', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Warning and banned statuses are calculated by AttendanceStatsService and used by Reports, Home, My Classes, Timetable, and AI Assistant.'),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: TextField(controller: _warnController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Warning threshold (%)'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _banController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Banned threshold (%)'))),
                const SizedBox(width: 12),
                FilledButton.icon(onPressed: _saving ? null : _saveThresholds, icon: const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving...' : 'Save')),
              ]),
            ]))),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Demo data', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text('Clears all 3 tabs then generates randomized subjects, classes, students, schedule, and attendance. Each run produces a fresh dataset.'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _seeding ? null : _seedSampleData,
                    icon: _seeding ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.science_outlined),
                    label: Text(_seeding ? 'Generating...' : 'Regenerate sample data'),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Card(child: ListTile(leading: const Icon(Icons.account_circle_outlined), title: const Text('Google account'), subtitle: Text(widget.stats.sheetService.isLive ? 'Connected through Google OAuth' : 'Connect from the login page'))),
          ],
            ),
          ),
        );
      },
    );
  }
}
