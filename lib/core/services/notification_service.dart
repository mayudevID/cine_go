import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as timezone;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        defaultPresentAlert: true,
        defaultPresentBanner: true,
        defaultPresentList: true,
        defaultPresentSound: true,
      ),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<bool> schedule({
    required String reminderId,
    required String title,
    required DateTime scheduledAt,
  }) async {
    await initialize();
    final notificationsAllowed = await _requestPermissions();
    final exactAlarmsAllowed = await _requestExactAlarmPermission();
    final scheduledDate = timezone.TZDateTime.from(
      scheduledAt.toUtc(),
      timezone.UTC,
    );
    await _plugin.zonedSchedule(
      _notificationId(reminderId),
      'Waktunya menonton!',
      'Pengingat untuk $title.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'cinego_reminders',
          'Pengingat film',
          channelDescription: 'Pengingat jadwal pemutaran film.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: exactAlarmsAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
    return notificationsAllowed && exactAlarmsAllowed;
  }

  Future<bool> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          true;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          true;
    }
    return true;
  }

  Future<bool> _requestExactAlarmPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final canSchedule = await androidPlugin?.canScheduleExactNotifications();
    if (canSchedule == true) return true;
    return await androidPlugin?.requestExactAlarmsPermission() ?? false;
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    await initialize();
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'cinego_reminders',
          'Pengingat film',
          channelDescription: 'Pengingat jadwal pemutaran film.',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancel(String reminderId) async {
    await initialize();
    await _plugin.cancel(_notificationId(reminderId));
  }

  int _notificationId(String id) =>
      id.codeUnits.fold(0, (hash, unit) => (hash * 31 + unit) & 0x7fffffff);
}
