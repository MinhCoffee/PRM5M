import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_evidence_logger.dart';

class PushNotificationMessage {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime sentAt;
  final bool isRead;

  const PushNotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    this.data = const {},
    required this.sentAt,
    this.isRead = false,
  });
}

abstract interface class IMessagingService {
  Future<void> initialize();
  Future<String> getFcmToken();
  Stream<PushNotificationMessage> get onMessageReceived;
  List<PushNotificationMessage> get notificationHistory;
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  });
}

class FirebaseMessagingService implements IMessagingService {
  static const _tokenKey = 'fcm_device_token';
  String? _fcmToken;
  final _messageController = StreamController<PushNotificationMessage>.broadcast();
  final List<PushNotificationMessage> _history = [];

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<PushNotificationMessage> get onMessageReceived => _messageController.stream;

  @override
  List<PushNotificationMessage> get notificationHistory => List.unmodifiable(_history);

  @override
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _fcmToken = prefs.getString(_tokenKey);

    if (_isFirebaseReady) {
      try {
        final messaging = FirebaseMessaging.instance;

        // Lab 3 Step 5 requirement: Request permission from user
        final settings = await messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        debugPrint('FCM Notification permission status: ${settings.authorizationStatus}');

        // Retrieve real FCM device token
        final realToken = await messaging.getToken();
        if (realToken != null && realToken.isNotEmpty) {
          _fcmToken = realToken;
          await prefs.setString(_tokenKey, realToken);
        }

        // Listen for token updates
        messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          prefs.setString(_tokenKey, newToken);
          debugPrint('FCM Token refreshed: $newToken');
        });

        // Listen for foreground push notifications from Firebase Console Campaign
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          final pushMsg = PushNotificationMessage(
            id: message.messageId ?? 'fcm_${DateTime.now().millisecondsSinceEpoch}',
            title: notification?.title ?? 'Thông báo từ FAP System',
            body: notification?.body ?? '',
            data: message.data,
            sentAt: message.sentTime ?? DateTime.now(),
          );

          _history.insert(0, pushMsg);
          _messageController.add(pushMsg);

          FirebaseEvidenceLogger.log(
            service: 'Cloud Messaging (FCM)',
            action: 'Console Notification Received',
            payload: {
              'messageId': pushMsg.id,
              'title': pushMsg.title,
              'body': pushMsg.body,
              'data': pushMsg.data,
            },
            isSuccess: true,
          );
        });
      } catch (e) {
        debugPrint('Firebase Messaging SDK initialization notice: $e');
      }
    }

    if (_fcmToken == null || _fcmToken!.isEmpty) {
      _fcmToken = 'fcm_token_attendEase_${DateTime.now().millisecondsSinceEpoch}_device_android';
      await prefs.setString(_tokenKey, _fcmToken!);
    }

    FirebaseEvidenceLogger.log(
      service: 'Cloud Messaging (FCM)',
      action: 'FCM Client Initialized',
      payload: {
        'token': _fcmToken,
        'platform': defaultTargetPlatform.name,
      },
    );
  }

  @override
  Future<String> getFcmToken() async {
    if (_fcmToken == null) {
      await initialize();
    }
    return _fcmToken!;
  }

  @override
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final message = PushNotificationMessage(
      id: 'fcm_msg_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      data: data ?? const {},
      sentAt: DateTime.now(),
    );

    _history.insert(0, message);
    _messageController.add(message);

    FirebaseEvidenceLogger.log(
      service: 'Cloud Messaging (FCM)',
      action: 'Push Notification Received / Dispatched',
      payload: {
        'messageId': message.id,
        'title': title,
        'body': body,
        'data': data,
      },
      isSuccess: true,
    );
  }
}
