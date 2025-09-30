import 'dart:io';
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../firebase_options.dart';

final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'ponto_digital_channel', // id
  'Notificações Ponto Digital', // title
  description: 'Canal de notificações do app Ponto Digital',
  importance: Importance.max,
);

Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // background isolate: inicializar Firebase com opções
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializar local notifications no background quando possível
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  await _local.initialize(const InitializationSettings(android: androidInit, iOS: iosInit));

  final title = message.notification?.title ?? 'Notificação';
  final body = message.notification?.body ?? '';
    try {
      final androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _local.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details);
  } catch (_) {}
}

class PushService {
  // --- Ongoing shift notification state (Android) ---
  static Timer? _progressTimer;
  static DateTime? _shiftStart;
  static Duration _pauseDuration = Duration.zero;
  static DateTime? _ongoingPauseStart;
  static Duration _shiftDuration = Duration(hours: 8);
  static const int _shiftNotificationId = 1111;

  /// Inicia a notificação contínua de jornada e atualiza a cada [tickInterval].
  /// [start] é a data/hora de entrada. [pauseTotal] é a duração acumulada de pausas.
  /// [shiftDuration] é a duração prevista da jornada usada para calcular a barra de progresso.
  static Future<void> startShiftNotification({
    required DateTime start,
    Duration pauseTotal = Duration.zero,
    Duration? shiftDuration,
    // se uma pausa já estiver em andamento, passe o instante de início aqui
    DateTime? ongoingPauseStart,
    Duration tickInterval = const Duration(seconds: 1),
  }) async {
    _shiftStart = start;
    _pauseDuration = pauseTotal;
    _ongoingPauseStart = ongoingPauseStart;
    if (shiftDuration != null) _shiftDuration = shiftDuration;

    // garante que o canal existe (Android)
    await _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(tickInterval, (_) => _updateShiftNotification());
    // primeira atualização imediata
    await _updateShiftNotification();
  }

  /// Para a atualização da notificação de jornada e remove a notificação.
  static Future<void> stopShiftNotification() async {
    _progressTimer?.cancel();
    _progressTimer = null;
    _shiftStart = null;
    _pauseDuration = Duration.zero;
    _ongoingPauseStart = null;
    await _local.cancel(_shiftNotificationId);
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours.remainder(100).toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  static Future<void> _updateShiftNotification() async {
    if (_shiftStart == null) return;
    final now = DateTime.now();
    // se há uma pausa em andamento, inclua sua duração transitória
    Duration effectivePause = _pauseDuration;
    if (_ongoingPauseStart != null) {
      final ongoing = now.difference(_ongoingPauseStart!);
      if (ongoing.isNegative == false) effectivePause += ongoing;
    }
    Duration worked = now.difference(_shiftStart!) - effectivePause;
    if (worked.isNegative) worked = Duration.zero;
    final totalSeconds = _shiftDuration.inSeconds;
    final workedSeconds = worked.inSeconds.clamp(0, totalSeconds);

    final title = 'Jornada em andamento';
    final body = 'Trabalhado: ${_formatDuration(worked)} • Pausa: ${_formatDuration(_pauseDuration)}';

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: totalSeconds,
      progress: workedSeconds,
      // mostra uma notificação persistente
      autoCancel: false,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _local.show(_shiftNotificationId, title, body, details);
  }

  static Future<void> init() async {
    // Assumimos que Firebase já foi inicializado em main().

    // Inicializar plugin de notificações locais
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  await _local.initialize(const InitializationSettings(android: androidInit, iOS: iosInit));

    // Criar canal Android
    await _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Pedir permisses em iOS/macOS e Android (Android 13+ exige POST_NOTIFICATIONS)
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
      }
      if (Platform.isAndroid) {
        // Android 13+ exige permissão runtime POST_NOTIFICATIONS
        try {
          final status = await Permission.notification.status;
          if (!status.isGranted) {
            final res = await Permission.notification.request();
            // ignore: avoid_print
            print('Notification permission status: $res');
          } else {
            // ignore: avoid_print
            print('Notification permission already granted');
          }
        } catch (e) {
          // ignore: avoid_print
          print('Failed to request notification permission: $e');
        }
      }
    } catch (_) {}

    // Registrar handlers
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final title = message.notification?.title ?? 'Notificação';
      final body = message.notification?.body ?? '';

        final androidDetails = AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
        );
        const iosDetails = DarwinNotificationDetails();
        final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _local.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details);
    });

    // Abrir notificao (tap) quando o app estava em background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Aqui poderia navegar para a tela correspondente
      // ignore: avoid_print
      print('onMessageOpenedApp: ${message.messageId}');
    });

    // obter mensagem que abriu o app quando estava terminated
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        // ignore: avoid_print
        print('initialMessage: ${message.messageId}');
      }
    });

    // obter e logar token FCM
    try {
      final token = await FirebaseMessaging.instance.getToken();
      // ignore: avoid_print
      print('FCM token: $token');
    } catch (e) {
      // ignore: avoid_print
      print('Failed to get FCM token: $e');
    }
  }

  static Future<String?> getToken() => FirebaseMessaging.instance.getToken();

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
