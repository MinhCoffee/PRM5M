import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/models/cloud_backup_mixin.dart';
import 'package:flutter_application_1/core/services/firebase/firebase_messaging_service.dart';
import 'package:flutter_application_1/core/services/firebase/firebase_remote_config_service.dart';
import 'package:flutter_application_1/core/services/firebase/firebase_storage_service.dart';
import 'package:flutter_application_1/features/home/viewmodel/home_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeStorage implements IStorageService {
  Object? failure;
  final List<double> progressSteps = [0.25, 0.75];
  int uploads = 0;

  @override
  Future<StorageUploadResult> uploadReport({
    required String fileName,
    required String content,
    required String classCode,
    void Function(double progress)? onProgress,
  }) async {
    if (failure != null) throw failure!;
    for (final p in progressSteps) {
      onProgress?.call(p);
    }
    uploads++;
    return StorageUploadResult(
      fileName: fileName,
      storagePath: 'reports/uid-1/$fileName',
      downloadUrl: 'https://example.test/$fileName',
      bytes: content.length,
      uploadedAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<List<StorageUploadResult>> getUploadedReports() async => const [];
}

class _BackupVm extends ChangeNotifier with CloudBackupMixin {
  _BackupVm(this.storage);
  final IStorageService storage;

  @override
  IStorageService get backupStorageService => storage;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cloud Storage backup (error case + recovery)', () {
    test('success exposes the real download URL and clears progress', () async {
      final vm = _BackupVm(_FakeStorage());
      final seen = <double?>[];
      vm.addListener(() => seen.add(vm.backupProgress));

      final ok = await vm.backupToCloud(
        fileName: 'a.csv',
        content: 'x',
        classCode: 'SE1801',
      );

      expect(ok, isTrue);
      expect(vm.backupFailed, isFalse);
      expect(vm.backupDownloadUrl, 'https://example.test/a.csv');
      expect(vm.isBackingUp, isFalse);
      expect(seen, containsAllInOrder([0.0, 0.25, 0.75]));
    });

    test('no-permission failure is shown and can be retried', () async {
      final storage = _FakeStorage()
        ..failure = const StorageFailure(
          StorageFailureKind.permissionDenied,
          'Không có quyền truy cập tệp này.',
        );
      final vm = _BackupVm(storage);

      final ok = await vm.backupToCloud(
        fileName: 'a.csv',
        content: 'x',
        classCode: 'SE1801',
      );

      expect(ok, isFalse);
      expect(vm.backupFailed, isTrue);
      expect(vm.backupMessage, contains('Không có quyền'));
      expect(vm.backupDownloadUrl, isNull);
      expect(vm.canRetryBackup, isTrue);

      storage.failure = null; // network/permission fixed
      expect(await vm.retryBackup(), isTrue);
      expect(vm.backupFailed, isFalse);
      expect(vm.canRetryBackup, isFalse);
      expect(storage.uploads, 1);
    });

    test('offline failure keeps a readable message', () async {
      final vm = _BackupVm(
        _FakeStorage()
          ..failure = const StorageFailure(
            StorageFailureKind.network,
            'Mất kết nối mạng, tải lên không hoàn tất.',
          ),
      );
      await vm.backupToCloud(fileName: 'a.csv', content: 'x', classCode: 'all');
      expect(vm.backupMessage, contains('Mất kết nối mạng'));
    });
  });

  group('FCM notification centre', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    PushNotificationMessage msg(Map<String, dynamic> data) =>
        PushNotificationMessage(
          id: 'm1',
          title: 't',
          body: 'b',
          data: data,
          sentAt: DateTime(2026, 1, 1),
        );

    test('tap routing maps payload to a screen, unknown -> notification centre', () {
      expect(routeForNotification(msg({'route': '/reports'})), '/reports');
      expect(routeForNotification(msg({'type': 'risk_alert'})), '/ai-assistant');
      expect(routeForNotification(msg({'type': 'attendance_reminder'})),
          '/take-attendance');
      expect(routeForNotification(msg({})), '/notifications');
      // A malformed route must not be trusted.
      expect(routeForNotification(msg({'route': 'https://evil.test'})),
          '/notifications');
    });

    test('JSON round trip keeps source and app state', () {
      final original = PushNotificationMessage(
        id: 'x',
        title: 'Cảnh báo',
        body: 'Nội dung',
        data: const {'type': 'risk_alert'},
        sentAt: DateTime(2026, 5, 4, 10, 30),
        source: NotificationSource.fcm,
        receivedIn: NotificationAppState.terminated,
      );
      final copy = PushNotificationMessage.fromJson(original.toJson());
      expect(copy.id, 'x');
      expect(copy.source, NotificationSource.fcm);
      expect(copy.receivedIn, NotificationAppState.terminated);
      expect(copy.data['type'], 'risk_alert');
    });

    test('history is stored, marked read, persisted and cleared', () async {
      final service = FirebaseMessagingService();
      await service.initialize(); // Firebase not initialised in unit tests
      expect(service.permission, NotificationPermission.notDetermined);
      expect(await service.getFcmToken(), isNull,
          reason: 'must never invent a token');

      await service.sendLocalNotification(title: 'A', body: 'B');
      expect(service.notificationHistory, hasLength(1));
      expect(service.notificationHistory.first.source, NotificationSource.local);
      expect(service.unreadCount, 1);

      await service.markAllRead();
      expect(service.unreadCount, 0);

      // A fresh instance (app restart) sees the stored history.
      final restarted = FirebaseMessagingService();
      await restarted.initialize();
      expect(restarted.notificationHistory, hasLength(1));

      await restarted.clearHistory();
      expect(restarted.notificationHistory, isEmpty);
    });
  });

  group('Remote Config', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('defaults cover the two observable Lab 3 parameters', () async {
      final rc = FirebaseRemoteConfigService();
      await rc.initialize();
      expect(rc.getBool('show_banner', false), isTrue);
      expect(rc.getInt('max_items', 0), 10);
      expect(rc.getAllValues().keys, containsAll(['show_banner', 'max_items']));
    });

    test('offline fetch keeps defaults and reports failure', () async {
      final rc = FirebaseRemoteConfigService();
      await rc.initialize();
      expect(await rc.fetchAndActivate(), isFalse);
      expect(rc.getInt('max_items', 0), 10);
    });

    test('a user override wins and survives restart', () async {
      final rc = FirebaseRemoteConfigService();
      await rc.initialize();
      await rc.setLocalOverride('attendance_warn_threshold', 0.3);
      expect(rc.getDouble('attendance_warn_threshold', 0), 0.3);

      final restarted = FirebaseRemoteConfigService();
      await restarted.initialize();
      expect(restarted.getDouble('attendance_warn_threshold', 0), 0.3);
    });
  });

  group('Home dashboard honours max_items', () {
    test('reports how many sessions the cap hid', () {
      const data = HomeDashboardData(
        todaySessions: [],
        totalTodaySessions: 7,
        maxItems: 3,
        overallRate: 0,
        bannedStudentsCount: 0,
        draftSessionsCount: 0,
        announcement: '',
      );
      expect(data.hiddenSessionCount, 7);
    });
  });
}
