import 'package:flutter/foundation.dart';
import '../../../core/services/firebase/firebase_analytics_service.dart';
import '../../../core/services/firebase/firebase_messaging_service.dart';

/// Backs the in-app notification centre (Lab 3 / FCM: "lưu thông báo nhận được").
class NotificationsViewModel extends ChangeNotifier {
  final IMessagingService _messagingService;
  final IAnalyticsService _analyticsService;

  NotificationsViewModel({
    required IMessagingService messagingService,
    required IAnalyticsService analyticsService,
  })  : _messagingService = messagingService,
        _analyticsService = analyticsService {
    _messagingService.historyRevision.addListener(notifyListeners);
  }

  List<PushNotificationMessage> get items =>
      _messagingService.notificationHistory;
  int get unreadCount => _messagingService.unreadCount;
  NotificationPermission get permission => _messagingService.permission;

  Future<void> load() async {
    await _messagingService.refreshHistory();
    _analyticsService.logScreenView('notifications_screen');
  }

  Future<void> markAllRead() => _messagingService.markAllRead();

  Future<void> clear() => _messagingService.clearHistory();

  /// Route to open when the user taps an item.
  String routeFor(PushNotificationMessage message) =>
      routeForNotification(message);

  @override
  void dispose() {
    _messagingService.historyRevision.removeListener(notifyListeners);
    super.dispose();
  }
}
