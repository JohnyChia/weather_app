import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';
import '../Utils/translator.dart';
import '../models/hourly_data.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final Set<int> _loopingAlarmIds = {};

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) async {
        final id = response.id ?? 0;
        final action = response.actionId;

        if (action == 'OK') {
          _loopingAlarmIds.remove(id);
          await _notificationsPlugin.cancel(id);

        } else if (action == 'IGNORE') {
          if (await Vibration.hasVibrator()) {
            Vibration.vibrate(duration: 1000);
          }

          if (_loopingAlarmIds.add(id)) {
            _startAlarmLoop(id);
          }
        }
      },
    );

    if (Platform.isAndroid) {
      _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<String> _translate(String text) async {
    return await TranslatorHelper.translate(text);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.cancel(id);

    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default',
      channelDescription: 'Default notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id,
      await _translate(title),
      await _translate(body),
      details,
    );
  }

  Future<void> showAlertNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Weather Alarms',
      channelDescription: 'Weather alert channel',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      autoCancel: false,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'OK',
          'OK',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'IGNORE',
          'IGNORE',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],

    );

    final details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      id,
      await _translate(title),
      await _translate(body),
      details,
    );
  }

  Future<void> _startAlarmLoop(int id) async {
    while (_loopingAlarmIds.contains(id)) {

      await Future.delayed(const Duration(minutes: 1));

      if (!_loopingAlarmIds.contains(id)) break;

      await showAlertNotification(
        id: id,
        title: "Weather Alarm",
        body: "Weather alert!",
      );

      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 1000);
      }
    }
  }

  Future<void> checkRainAndNotify(List<HourlyData> hourlyList) async {
    final rainList = hourlyList
        .where((h) => h.condition.toLowerCase().contains('rain'))
        .toList();

    if (rainList.isNotEmpty) {
      final rain = rainList.first;
      await showNotification(
        id: 1,
        title: 'Rain Alert',
        body: 'Rain at ${rain.weatherTime}. Bring umbrella!',
      );
    } else {
      await showNotification(
        id: 2,
        title: 'Weather Update',
        body: 'No rain today. Enjoy!',
      );
    }
  }

  Future<void> showUvNotify(double currentUV) async {
    int score = ((currentUV / 12.0).clamp(0.0, 1.0) * 100).toInt();
    String body;

    if (score >= 70) {
      body = "Excellent solar energy conditions now! Score: $score%";
    } else if (score >= 40) {
      body = "Good solar energy conditions. Score: $score%";
    } else {
      body = "Low solar energy potential currently. Score: $score%";
    }

    final androidDetails = AndroidNotificationDetails(
      'solar_alerts_channel',
      'Solar Alerts',
      channelDescription: 'Solar energy notification channel',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      autoCancel: false,
    );

    final details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      3,
      await _translate("Solar Notifications"),
      await _translate(body),
      details,
    );
  }
}