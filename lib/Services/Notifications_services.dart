import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import '../models/hourly_data.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:io';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  final action = response.actionId;
  print("BACKGROUND CLICKED: $action");

  if (action == 'IGNORE') {
    if (await Vibration.hasVibrator() ?? false) {
      print("Vibration Trigged!");
      Vibration.vibrate(duration: 1000);
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) async {
        final action = response.actionId;
        print("CLICKED: $action");

        if (action == 'OK') {
          print("User pressed OK - do nothing");
          // OK 点击直接忽略
        } else if (action == 'IGNORE') {
          print("User pressed IGNORE");

          // 立即振动
          if (await Vibration.hasVibrator() ?? false) {
            Vibration.vibrate(duration: 1000);
            print("Immediate Vibration Triggered!");
          }

          Future.delayed(const Duration(minutes: 3), () async {
            final id = response.id ?? DateTime.now().millisecondsSinceEpoch;
            final title = response.notificationResponseType.name ?? "Weather Alert";
            final body = response.payload ?? "Check the weather!";

            await showAlarmNotification(
              id: id,
              title: title,
              body: body,
            );

            // 再次振动
            if (await Vibration.hasVibrator() ?? false) {
              Vibration.vibrate(duration: 1000);
              print("Delayed Vibration Triggered!");
            }
          });
        } else {
          print("Notification tapped without action");
        }
      },
    );

    // Android 13+
    if (Platform.isAndroid) {
      _notificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// Show notification in phone tray
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'weather_alerts_channel',
      'Weather Alerts',
      channelDescription: 'Weather notification channel',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
    );

    const NotificationDetails details =
    NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(id, title, body, details);
  }

  /// Check rain and notify user
  void checkRainAndNotify(List<HourlyData> hourlyList) {
    final rainList = hourlyList.where(
          (h) => h.condition.toLowerCase().contains('rain'),
    ).toList();

    if (rainList.isNotEmpty) {
      final rain = rainList.first;

      showNotification(
        id: 1,
        title: 'Rain Alert',
        body: 'Rain at ${rain.weatherTime}. Bring umbrella!',

      );
    } else {
      showNotification(
        id: 2,
        title: 'Weather Update',
        body: 'No rain today. Enjoy!',
      );
    }
  }

  Future<void> showAlarmNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'weather_alerts_channel', // channelId
      'Weather Alerts',          // channelName
      channelDescription: 'Weather notification channel',
      importance: Importance.max,       // 最大优先级
      priority: Priority.high,          // 让通知弹出在最上层
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,           // 关键：弹出全屏
      autoCancel: false,                // 用户滑掉不会消失
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'OK',
          'OK',
          showsUserInterface: true,   // ⭐关键
          cancelNotification: true,   // ⭐关键
        ),
        const AndroidNotificationAction(
          'IGNORE',
          'IGNORE',
          showsUserInterface: true,   // ⭐关键
          cancelNotification: true,   // ⭐关键
        ),
      ],
    );

    final details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(id, title, body, details);
  }

}