import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/app_shell.dart';
import 'features/attendance/attendance_browse_page.dart';
import 'features/attendance/attendance_detail_page.dart';
import 'features/attendance/data/attendance_repository.dart';
import 'features/settings/settings_page.dart';
import 'features/reports/reports_page.dart';
import 'features/home/home_page.dart';
import 'features/classes/my_classes_page.dart';
import 'features/timetable/timetable_page.dart';
import 'features/export/export_page.dart';
import 'features/ai_assistant/ai_assistant_page.dart';
import 'services/attendance_stats_service.dart';
import 'services/google_sheet_service.dart';
import 'features/auth/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Could not load .env file: $e');
  }
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final sheetService = GoogleSheetService();
    final repository = GoogleSheetsAttendanceRepository(sheetService);
    final stats = AttendanceStatsService(sheetService);
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginPage(service: sheetService),
        ),
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/take-attendance',
              builder: (context, state) => AttendanceBrowsePage(
                repository: repository,
                onSessionSelected: (session) =>
                    context.go('/attendance/${session.id}'),
              ),
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) => HomePage(
                stats: stats,
                onSessionSelected: (sessionId) =>
                    context.go('/attendance/$sessionId'),
              ),
            ),
            GoRoute(
              path: '/my-classes',
              builder: (context, state) => MyClassesPage(
                stats: stats,
                onSessionSelected: (sessionId) =>
                    context.go('/attendance/$sessionId'),
              ),
            ),
            GoRoute(
              path: '/timetable',
              builder: (context, state) => TimetablePage(
                stats: stats,
                onSessionSelected: (sessionId) =>
                    context.go('/attendance/$sessionId'),
              ),
            ),
            GoRoute(
              path: '/fap-sync',
              builder: (context, state) => ExportPage(stats: stats),
            ),
            GoRoute(
              path: '/ai-assistant',
              builder: (context, state) => AiAssistantPage(stats: stats),
            ),
            GoRoute(
              path: '/attendance/:sessionId',
              builder: (context, state) => AttendanceDetailPage(
                sessionId: state.pathParameters['sessionId']!,
                repository: repository,
                onAttendanceSaved: () => stats.load(force: true),
              ),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => SettingsPage(stats: stats),
            ),
            GoRoute(
              path: '/reports',
              builder: (context, state) => ReportsPage(stats: stats),
            ),
          ],
        ),
      ],
    );
    return MaterialApp.router(
      title: 'Academic Portal - Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
