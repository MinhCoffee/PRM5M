import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_shell.dart';
import 'core/widgets/placeholder_page.dart';
import 'features/attendance/attendance_browse_page.dart';
import 'features/attendance/attendance_detail_page.dart';
import 'features/attendance/data/attendance_repository.dart';
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
    final repository = MockAttendanceRepository();
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/take-attendance',
              builder: (context, state) => AttendanceBrowsePage(
                repository: repository,
                onSessionSelected: (session) => context.go('/attendance/${session.id}'),
              ),
            ),
            GoRoute(
              path: '/attendance/:sessionId',
              builder: (context, state) => AttendanceDetailPage(
                sessionId: state.pathParameters['sessionId']!,
                repository: repository,
              ),
            ),
            _placeholderRoute('/home', 'Home'),
            _placeholderRoute('/my-classes', 'My Classes'),
            _placeholderRoute('/timetable', 'Timetable'),
            _placeholderRoute('/reports', 'Reports'),
            _placeholderRoute('/fap-sync', 'FAP Sync'),
            _placeholderRoute('/ai-assistant', 'AI Assistant'),
            _placeholderRoute('/settings', 'Settings'),
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

  GoRoute _placeholderRoute(String path, String title) => GoRoute(
        path: path,
        builder: (context, state) => PlaceholderPage(title: title),
      );
}
