import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_shell.dart';
import 'features/ai_assistant/ai_assistant_page.dart';
import 'features/attendance/attendance_browse_page.dart';
import 'features/attendance/attendance_detail_page.dart';
import 'features/auth/login_page.dart';
import 'features/classes/my_classes_page.dart';
import 'features/export/export_page.dart';
import 'features/home/home_page.dart';
import 'features/profile/profile_page.dart';
import 'features/reports/reports_page.dart';
import 'features/settings/settings_page.dart';
import 'features/timetable/timetable_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Could not load .env file: $e');
  }

  // Initialize Firebase native connection with google-services.json
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully with native config.');
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Pre-initialize Firebase & Remote Config services
  await ServiceLocator.instance.remoteConfigService.initialize();
  await ServiceLocator.instance.messagingService.initialize();

  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locator = ServiceLocator.instance;

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginPage(
            viewModel: locator.createAuthViewModel(),
            loggedOut: state.uri.queryParameters['logout'] == '1',
          ),
        ),
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => HomePage(
                viewModel: locator.createHomeViewModel(),
                onSessionSelected: (sessionId) =>
                    context.go('/attendance/$sessionId'),
              ),
            ),
            GoRoute(
              path: '/take-attendance',
              builder: (context, state) => AttendanceBrowsePage(
                viewModel: locator.createAttendanceBrowseViewModel(),
                onSessionSelected: (session) =>
                    context.go('/attendance/${session.id}'),
              ),
            ),
            GoRoute(
              path: '/attendance/:sessionId',
              builder: (context, state) {
                final sessionId = state.pathParameters['sessionId']!;
                return AttendanceDetailPage(
                  viewModel: locator.createAttendanceDetailViewModel(sessionId),
                  onAttendanceSaved: () => locator.statsService.load(force: true),
                );
              },
            ),
            GoRoute(
              path: '/my-classes',
              builder: (context, state) => MyClassesPage(
                viewModel: locator.createMyClassesViewModel(),
                onSessionSelected: (sessionId) =>
                    context.go('/attendance/$sessionId'),
              ),
            ),
            GoRoute(
              path: '/timetable',
              builder: (context, state) => TimetablePage(
                viewModel: locator.createTimetableViewModel(),
                onSessionSelected: (sessionId) =>
                    context.go('/attendance/$sessionId'),
              ),
            ),
            GoRoute(
              path: '/reports',
              builder: (context, state) => ReportsPage(
                viewModel: locator.createReportsViewModel(),
              ),
            ),
            GoRoute(
              path: '/fap-sync',
              builder: (context, state) => ExportPage(
                viewModel: locator.createExportViewModel(),
              ),
            ),
            GoRoute(
              path: '/ai-assistant',
              builder: (context, state) => AiAssistantPage(
                viewModel: locator.createAiAssistantViewModel(),
              ),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => ProfilePage(
                viewModel: locator.createProfileViewModel(),
              ),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => SettingsPage(
                viewModel: locator.createSettingsViewModel(),
              ),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'AttendEase - FPT Academic Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
