import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_service.dart';

class PushService {
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Firebase init should be done by caller (main)
    // Local notifications initialization
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(const InitializationSettings(android: androidInit, iOS: iosInit));

    // Request permissions for iOS
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission();
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Show local notification for foreground messages
      _showFromRemote(message);
      // Persist in app notification center
      NotificationService.getInstance().then((svc) {
        final title = message.notification?.title ?? 'Notificação';
        final body = message.notification?.body ?? '';
        svc.addLocalFromPayload(title: title, body: body);
      });
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  }

  static Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    final title = message.notification?.title ?? 'Notificação';
    final body = message.notification?.body ?? '';
    // persist via NotificationService when possible - background isolates can't access plugin state easily
    // We'll save minimal data to SharedPreferences directly in NotificationService._saveFromBackground if needed.
    try {
      final svc = await NotificationService.getInstance();
      await svc.addLocalFromPayload(title: title, body: body);
    } catch (_) {}
    await _showSimpleNotification(title: title, body: body);
  }

  static Future<void> _showFromRemote(RemoteMessage message) async {
    final title = message.notification?.title ?? 'Notificação';
    final body = message.notification?.body ?? '';
    await _showSimpleNotification(title: title, body: body);
  }

  static Future<void> _showSimpleNotification({required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails('ponto_digital_channel', 'Notificações', importance: Importance.max, priority: Priority.high);
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _local.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details);
  }

  // Ongoing notification update (persistent) - Android only features ongoing notifications
  static Future<void> showOngoingNotification({required int id, required String title, required String body}) async {
    final androidDetails = AndroidNotificationDetails('ponto_digital_ongoing', 'Permanente', channelDescription: 'Notificação permanente de jornada', importance: Importance.low, priority: Priority.low, ongoing: true, onlyAlertOnce: true, autoCancel: false);
    final iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _local.show(id, title, body, details);
  }

  static Future<void> cancelNotification(int id) async {
    await _local.cancel(id);
  }
}
