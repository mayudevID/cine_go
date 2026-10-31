import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/notification_service.dart';
import 'reminder_model.dart';

class ReminderRepository {
  ReminderRepository(this._notifications);

  static const _storageKey = 'cinego.reminders';
  final NotificationService _notifications;
  Future<void> _writeQueue = Future<void>.value();

  Future<List<ReminderModel>> getReminders() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getStringList(_storageKey) ?? const [];
    return raw
        .map(
          (item) =>
              ReminderModel.fromJson(jsonDecode(item) as Map<String, Object?>),
        )
        .toList(growable: false)
      ..sort(
        (first, second) => first.scheduledAt.compareTo(second.scheduledAt),
      );
  }

  Future<bool> save(ReminderModel reminder) => _serialize(() async {
    final reminders = await getReminders();
    final updated = [
      ...reminders.where((item) => item.id != reminder.id),
      reminder,
    ];
    final notificationsAllowed = await _notifications.schedule(
      reminderId: reminder.id,
      title: reminder.title,
      scheduledAt: reminder.scheduledAt,
    );
    final preferences = await SharedPreferences.getInstance();
    try {
      await preferences.setStringList(
        _storageKey,
        updated.map((item) => jsonEncode(item.toJson())).toList(),
      );
    } catch (_) {
      await _notifications.cancel(reminder.id);
      rethrow;
    }
    return notificationsAllowed;
  });

  Future<void> delete(String id) => _serialize(() async {
    final reminders = await getReminders();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _storageKey,
      reminders
          .where((item) => item.id != id)
          .map((item) => jsonEncode(item.toJson()))
          .toList(),
    );
    await _notifications.cancel(id);
  });

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _writeQueue.then((_) => operation());
    _writeQueue = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }
}
