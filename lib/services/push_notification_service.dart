import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

/// Top-level handler required by FCM for background/terminated state.
@pragma('vm:entry-point')
Future<void> onFirebaseBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background messages are shown automatically by FCM on Android/iOS.
}

class PushNotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifs = FlutterLocalNotificationsPlugin();
  final _api = ApiService();

  static const _channelId = 'motivup_main';
  static const _channelName = 'MotivUp Notifications';

  static bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Request user permission (iOS requires this; Android 13+ too)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Local notifications plugin (used for foreground display)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifs.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Create the Android high-importance channel once
    await _localNotifs
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          importance: Importance.high,
          description: 'Points, récompenses et rappels de liquidation',
        ));

    // Foreground messages → show as heads-up via local_notifications
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // Background messages (app in background/terminated)
    FirebaseMessaging.onBackgroundMessage(onFirebaseBackgroundMessage);

    // Register/refresh FCM token with backend
    final token = await _messaging.getToken();
    if (token != null) await _uploadToken(token);
    _messaging.onTokenRefresh.listen(_uploadToken);
  }

  void _handleForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _localNotifs.show(
      n.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> _uploadToken(String token) async {
    try {
      await _api.patch('/users/me/fcm-token', {'fcmToken': token});
    } catch (_) {
      // Best-effort — app still works without it
    }
  }
}
