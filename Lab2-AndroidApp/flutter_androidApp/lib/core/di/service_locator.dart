import '../services/firebase/firebase_auth_service.dart';
import '../services/firebase/firebase_storage_service.dart';
import '../services/firebase/firebase_messaging_service.dart';
import '../services/firebase/firebase_analytics_service.dart';
import '../services/firebase/firebase_crashlytics_service.dart';
import '../services/firebase/firebase_remote_config_service.dart';
import '../../services/google_sheet_service.dart';
import '../../services/attendance_stats_service.dart';
import '../../services/file_service.dart';
import '../../services/attendance_notification_service.dart';
import '../../features/attendance/data/attendance_repository.dart';
import '../../features/auth/viewmodel/auth_viewmodel.dart';
import '../../features/home/viewmodel/home_viewmodel.dart';
import '../../features/attendance/viewmodel/attendance_browse_viewmodel.dart';
import '../../features/attendance/viewmodel/attendance_detail_viewmodel.dart';
import '../../features/classes/viewmodel/my_classes_viewmodel.dart';
import '../../features/timetable/viewmodel/timetable_viewmodel.dart';
import '../../features/reports/viewmodel/reports_viewmodel.dart';
import '../../features/export/viewmodel/export_viewmodel.dart';
import '../../features/ai_assistant/viewmodel/ai_assistant_viewmodel.dart';
import '../../features/profile/viewmodel/profile_viewmodel.dart';
import '../../features/settings/viewmodel/settings_viewmodel.dart';

class ServiceLocator {
  static ServiceLocator? _instance;
  static ServiceLocator get instance => _instance ??= ServiceLocator._default();

  final IAuthService authService;
  final IStorageService storageService;
  final IMessagingService messagingService;
  final IAnalyticsService analyticsService;
  final ICrashlyticsService crashlyticsService;
  final IRemoteConfigService remoteConfigService;
  final GoogleSheetService sheetService;
  final AttendanceRepository attendanceRepository;
  final AttendanceStatsService statsService;
  final FileService fileService;
  final AttendanceNotificationService notificationService;

  ServiceLocator({
    required this.authService,
    required this.storageService,
    required this.messagingService,
    required this.analyticsService,
    required this.crashlyticsService,
    required this.remoteConfigService,
    required this.sheetService,
    required this.attendanceRepository,
    required this.statsService,
    required this.fileService,
    required this.notificationService,
  });

  factory ServiceLocator._default() {
    final sheetService = GoogleSheetService();
    final repo = GoogleSheetsAttendanceRepository(sheetService);
    final stats = AttendanceStatsService(sheetService);
    final file = FileService();
    final notify = AttendanceNotificationService();

    final auth = FirebaseAuthService();
    final storage = FirebaseStorageService();
    final messaging = FirebaseMessagingService();
    final analytics = FirebaseAnalyticsService();
    final crashlytics = FirebaseCrashlyticsService();
    final remoteConfig = FirebaseRemoteConfigService();

    return ServiceLocator(
      authService: auth,
      storageService: storage,
      messagingService: messaging,
      analyticsService: analytics,
      crashlyticsService: crashlytics,
      remoteConfigService: remoteConfig,
      sheetService: sheetService,
      attendanceRepository: repo,
      statsService: stats,
      fileService: file,
      notificationService: notify,
    );
  }

  static void setMockInstance(ServiceLocator mock) {
    _instance = mock;
  }

  // --- ViewModel Factory Methods (for Testing & Inversion of Control) ---

  AuthViewModel createAuthViewModel() => AuthViewModel(
        authService: authService,
        sheetService: sheetService,
        analyticsService: analyticsService,
        crashlyticsService: crashlyticsService,
      );

  HomeViewModel createHomeViewModel() => HomeViewModel(
        statsService: statsService,
        remoteConfigService: remoteConfigService,
        analyticsService: analyticsService,
        crashlyticsService: crashlyticsService,
      );

  AttendanceBrowseViewModel createAttendanceBrowseViewModel() =>
      AttendanceBrowseViewModel(
        repository: attendanceRepository,
        analyticsService: analyticsService,
        crashlyticsService: crashlyticsService,
      );

  AttendanceDetailViewModel createAttendanceDetailViewModel(String sessionId) =>
      AttendanceDetailViewModel(
        sessionId: sessionId,
        repository: attendanceRepository,
        statsService: statsService,
        analyticsService: analyticsService,
        crashlyticsService: crashlyticsService,
      );

  MyClassesViewModel createMyClassesViewModel() => MyClassesViewModel(
        statsService: statsService,
        analyticsService: analyticsService,
        crashlyticsService: crashlyticsService,
      );

  TimetableViewModel createTimetableViewModel() => TimetableViewModel(
        statsService: statsService,
        analyticsService: analyticsService,
        crashlyticsService: crashlyticsService,
      );

  ReportsViewModel createReportsViewModel() => ReportsViewModel(
        statsService: statsService,
        fileService: fileService,
        storageService: storageService,
        analyticsService: analyticsService,
        crashlyticsService: crashlyticsService,
      );

  ExportViewModel createExportViewModel() => ExportViewModel(
        statsService: statsService,
        fileService: fileService,
        storageService: storageService,
        analyticsService: analyticsService,
        crashlyticsService: crashlyticsService,
      );

  AiAssistantViewModel createAiAssistantViewModel() => AiAssistantViewModel(
        statsService: statsService,
        notificationService: notificationService,
        remoteConfigService: remoteConfigService,
        messagingService: messagingService,
        analyticsService: analyticsService,
        crashlyticsService: crashlyticsService,
      );

  ProfileViewModel createProfileViewModel() => ProfileViewModel(
        authService: authService,
        messagingService: messagingService,
        crashlyticsService: crashlyticsService,
        remoteConfigService: remoteConfigService,
        storageService: storageService,
        analyticsService: analyticsService,
      );

  SettingsViewModel createSettingsViewModel() => SettingsViewModel(
        statsService: statsService,
        remoteConfigService: remoteConfigService,
        crashlyticsService: crashlyticsService,
        analyticsService: analyticsService,
      );
}
