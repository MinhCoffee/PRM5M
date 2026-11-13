import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_evidence_logger.dart';

/// Where a notification came from. Only [fcm] ones were delivered by Firebase.
enum NotificationSource { fcm, local }

/// Which app state the notification was received/tapped in (Lab 3: 3 states).
enum NotificationAppState { foreground, background, terminated }

enum NotificationPermission { granted, denied, notDetermined }

const _historyKey = 'notification_history_v1';
const _maxHistory = 50;

class PushNotificationMessage {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime sentAt;
  final bool isRead;
  final NotificationSource source;
  final NotificationAppState? receivedIn;

  const PushNotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    this.data = const {},
    required this.sentAt,
    this.isRead = false,
    this.source = NotificationSource.fcm,
    this.receivedIn,
  });

  PushNotificationMessage copyWith({bool? isRead}) => PushNotificationMessage(
        id: id,
        title: title,
        body: body,
        data: data,
        sentAt: sentAt,
        isRead: isRead ?? this.isRead,
        source: source,
        receivedIn: receivedIn,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'data': data,
        'sentAt': sentAt.toIso8601String(),
        'isRead': isRead,
        'source': source.name,
        'receivedIn': receivedIn?.name,
      };

  factory PushNotificationMessage.fromJson(Map<String, dynamic> json) {
    return PushNotificationMessage(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: Map<String, dynamic>.from((json['data'] as Map?) ?? const {}),
      sentAt: DateTime.tryParse(json['sentAt']?.toString() ?? '') ??
          DateTime.now(),
      isRead: json['isRead'] == true,
      source: json['source'] == 'local'
          ? NotificationSource.local
          : NotificationSource.fcm,
      receivedIn: NotificationAppState.values
          .where((s) => s.name == json['receivedIn'])
          .firstOrNull,
    );
  }
}

/// Maps a tapped notification to an in-app route. Unknown payloads fall back
/// to the home screen so a tap never dead-ends.
String routeForNotification(PushNotificationMessage message) {
  final explicit = message.data['route']?.toString();
  // Only plain in-app paths from a remote payload; never `//host` or login/logout.
  if (explicit != null &&
      explicit.startsWith('/') &&
      !explicit.startsWith('//') &&
      !explicit.startsWith('/login')) {
    return explicit;
  }

  switch (message.data['type']?.toString()) {
    case 'risk_alert':
      return '/ai-assistant';
    case 'attendance_reminder':
      return '/take-attendance';
    case 'report_ready':
      return '/reports';
    default:
      return '/notifications';
  }
}

abstract interface class IMessagingService {
  Future<void> initialize();

  /// The real FCM registration token, or null when unavailable
  /// (permission denied, Firebase not configured, offline).
  Future<String?> getFcmToken();

  NotificationPermission get permission;

  Stream<PushNotificationMessage> get onMessageReceived;

  /// Emits when the user taps a notification (background or cold start).
  Stream<PushNotificationMessage> get onNotificationOpened;

  /// A tap that launched the app from the terminated state, if not yet consumed.
  PushNotificationMessage? takeLaunchNotification();

  List<PushNotificationMessage> get notificationHistory;

  /// Bumps on every change to the history/read state (for badges and lists).
  ValueListenable<int> get historyRevision;
  int get unreadCount;
  Future<void> markAllRead();
  Future<void> clearHistory();

  /// Re-reads history written by the background isolate (call on app resume).
  Future<void> refreshHistory();

  /// In-app only notification (NOT delivered by FCM). Stored with
  /// [NotificationSource.local] so it can never be mistaken for a push.
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  });
}

/// Runs in a separate isolate while the app is in the background/terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final raw = prefs.getString(_historyKey);
  final list = raw == null
      ? <Map<String, dynamic>>[]
      : (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  final id = message.messageId ?? 'fcm_${DateTime.now().millisecondsSinceEpoch}';
  if (list.any((e) => e['id'] == id)) return;
  list.insert(
    0,
    PushNotificationMessage(
      id: id,
      title: message.notification?.title ?? message.data['title']?.toString() ?? '',
      body: message.notification?.body ?? message.data['body']?.toString() ?? '',
      data: message.data,
      sentAt: message.sentTime ?? DateTime.now(),
      receivedIn: NotificationAppState.background,
    ).toJson(),
  );
  await prefs.setString(_historyKey, jsonEncode(list.take(_maxHistory).toList()));
}

class FirebaseMessagingService implements IMessagingService {
  String? _fcmToken;
  NotificationPermission _permission = NotificationPermission.notDetermined;
  bool _initialized = false;
  PushNotificationMessage? _launchNotification;

  final _messageController =
      StreamController<PushNotificationMessage>.broadcast();
  final _openedController =
      StreamController<PushNotificationMessage>.broadcast();
  final List<PushNotificationMessage> _history = [];
  final ValueNotifier<int> _revision = ValueNotifier<int>(0);

  @override
  ValueListenable<int> get historyRevision => _revision;

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  NotificationPermission get permission => _permission;

  @override
  Stream<PushNotificationMessage> get onMessageReceived =>
      _messageController.stream;

  @override
  Stream<PushNotificationMessage> get onNotificationOpened =>
      _openedController.stream;

  @override
  List<PushNotificationMessage> get notificationHistory =>
      List.unmodifiable(_history);

  @override
  int get unreadCount => _history.where((m) => !m.isRead).length;

  @override
  PushNotificationMessage? takeLaunchNotification() {
    final m = _launchNotification;
    _launchNotification = null;
    return m;
  }

  PushNotificationMessage _fromRemote(
    RemoteMessage message,
    NotificationAppState state,
  ) {
    final n = message.notification;
    return PushNotificationMessage(
      id: message.messageId ?? 'fcm_${DateTime.now().millisecondsSinceEpoch}',
      title: n?.title ?? message.data['title']?.toString() ?? 'Thông báo',
      body: n?.body ?? message.data['body']?.toString() ?? '',
      data: message.data,
      sentAt: message.sentTime ?? DateTime.now(),
      receivedIn: state,
    );
  }

  /// Returns false when the id is already stored (e.g. written by the
  /// background isolate before the user tapped it).
  bool _remember(PushNotificationMessage m) {
    if (_history.any((e) => e.id == m.id)) return false;
    _history.insert(0, m);
    if (_history.length > _maxHistory) {
      _history.removeRange(_maxHistory, _history.length);
    }
    unawaited(_persist());
    return true;
  }

  /// Saves the history. Unless [replace] is true (clear), first merges in
  /// pushes the background isolate wrote since we last loaded, so a persist
  /// never drops them.
  Future<void> _persist({bool replace = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!replace) {
        await prefs.reload();
        final raw = prefs.getString(_historyKey);
        if (raw != null) {
          var added = false;
          for (final e in (jsonDecode(raw) as List)) {
            final stored =
                PushNotificationMessage.fromJson(Map<String, dynamic>.from(e as Map));
            if (!_history.any((m) => m.id == stored.id)) {
              _history.add(stored);
              added = true;
            }
          }
          if (added) {
            _history.sort((a, b) => b.sentAt.compareTo(a.sentAt));
            if (_history.length > _maxHistory) {
              _history.removeRange(_maxHistory, _history.length);
            }
          }
        }
      }
      _revision.value++;
      await prefs.setString(
        _historyKey,
        jsonEncode(_history.map((m) => m.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Notification history persist error: $e');
      _revision.value++;
    }
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final raw = prefs.getString(_historyKey);
      if (raw == null) return;
      _history
        ..clear()
        ..addAll(
          (jsonDecode(raw) as List)
              .map((e) => PushNotificationMessage.fromJson(
                  Map<String, dynamic>.from(e as Map))),
        );
    } catch (e) {
      debugPrint('Notification history load error: $e');
    }
    _revision.value++;
  }

  void _handleTap(RemoteMessage message, NotificationAppState state) {
    final m = _fromRemote(message, state);
    final existing = _history.where((e) => e.id == m.id).firstOrNull;
    if (existing == null) {
      _remember(m.copyWith(isRead: true));
    } else {
      final idx = _history.indexOf(existing);
      _history[idx] = existing.copyWith(isRead: true);
      unawaited(_persist());
    }

    FirebaseEvidenceLogger.log(
      service: 'Cloud Messaging (FCM)',
      action: 'Notification tapped (${state.name})',
      payload: {
        'messageId': m.id,
        'route': routeForNotification(m),
      },
      isSuccess: true,
    );

    if (state == NotificationAppState.terminated) {
      // Router is not built yet: hold it until main() consumes it.
      _launchNotification = m;
    }
    _openedController.add(m);
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _loadHistory();

    if (!_isFirebaseReady) {
      FirebaseEvidenceLogger.log(
        service: 'Cloud Messaging (FCM)',
        action: 'Skipped: Firebase not initialized',
        payload: const {},
        isSuccess: false,
        errorMessage: 'Firebase.apps is empty (google-services.json missing?)',
      );
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      // Android 13+ requires the runtime POST_NOTIFICATIONS permission.
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      _permission = switch (settings.authorizationStatus) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional =>
          NotificationPermission.granted,
        AuthorizationStatus.denied ||
        AuthorizationStatus.deniedPermanently =>
          NotificationPermission.denied,
        AuthorizationStatus.notDetermined => NotificationPermission.notDetermined,
      };

      FirebaseEvidenceLogger.log(
        service: 'Cloud Messaging (FCM)',
        action: 'Notification permission: ${settings.authorizationStatus.name}',
        payload: {'platform': defaultTargetPlatform.name},
        isSuccess: _permission == NotificationPermission.granted,
      );

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 1) Foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final m = _fromRemote(message, NotificationAppState.foreground);
        _remember(m);
        _messageController.add(m);
        FirebaseEvidenceLogger.log(
          service: 'Cloud Messaging (FCM)',
          action: 'Notification received (foreground)',
          payload: {'messageId': m.id, 'title': m.title},
          isSuccess: true,
        );
      });

      // 2) Background -> user taps the system notification
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _handleTap(message, NotificationAppState.background),
      );

      // 3) Terminated -> user taps the notification that launched the app
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _handleTap(initial, NotificationAppState.terminated);
      }

      messaging.onTokenRefresh.listen((t) => _fcmToken = t);
      _fcmToken = await messaging.getToken();

      FirebaseEvidenceLogger.log(
        service: 'Cloud Messaging (FCM)',
        action: 'FCM Client Initialized',
        payload: {
          'tokenAvailable': _fcmToken != null,
          'platform': defaultTargetPlatform.name,
        },
        isSuccess: _fcmToken != null,
      );
    } catch (e) {
      debugPrint('Firebase Messaging init failed: $e');
      FirebaseEvidenceLogger.log(
        service: 'Cloud Messaging (FCM)',
        action: 'Initialization failed',
        payload: const {},
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<String?> getFcmToken() async {
    if (_fcmToken != null) return _fcmToken;
    if (!_isFirebaseReady) return null;
    try {
      _fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('getToken failed: $e');
    }
    return _fcmToken;
  }

  @override
  Future<void> refreshHistory() => _loadHistory();

  @override
  Future<void> markAllRead() async {
    for (var i = 0; i < _history.length; i++) {
      _history[i] = _history[i].copyWith(isRead: true);
    }
    await _persist();
  }

  @override
  Future<void> clearHistory() async {
    _history.clear();
    await _persist(replace: true);
  }

  @override
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final message = PushNotificationMessage(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      body: body,
      data: data ?? const {},
      sentAt: DateTime.now(),
      source: NotificationSource.local,
      receivedIn: NotificationAppState.foreground,
    );
    _remember(message);
    _messageController.add(message);

    FirebaseEvidenceLogger.log(
      service: 'Cloud Messaging (FCM)',
      action: 'Local in-app notification (not delivered by FCM)',
      payload: {'messageId': message.id, 'title': title},
      isSuccess: true,
    );
  }
}
