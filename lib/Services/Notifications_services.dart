import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import '../models/hourly_data.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:io';


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
          final action = response.actionId?.toUpperCase();
          print("CLICKED: $action");

          if (action == 'OK') {
            print("User pressed OK");
          }

          if (action == 'IGNORE') {
            print("User pressed IGNORE");
            if (await Vibration.hasVibrator() ?? false) {
              Vibration.vibrate(duration: 1000);
            }
          }
        }
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

  /// Show current weather notification
  Future<void> showCurrentWeatherNotification({
    required String cityName,
    required String condition,
    required double temperature,
  }) async {
    await showNotification(
      id: 0,
      title: "Current Weather in $cityName",
      body: "$condition | ${temperature.round()}°C",
    );
  }

  Future<void> showAlarmNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'weather_alerts_channel',
      'Weather Alerts',
      channelDescription: 'Weather notification channel',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true, // 🔥 关键，让 Action 回调可触发
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('OK', 'OK'),
        AndroidNotificationAction('IGNORE', 'IGNORE'),
      ],
    );

    final details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(id, title, body, details);
  }

}