import 'package:cine_go/core/services/notification_service.dart';
import 'package:cine_go/features/reminders/model/reminder_model.dart';
import 'package:cine_go/features/reminders/model/reminder_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingNotificationService notifications;
  late ReminderRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    notifications = _RecordingNotificationService();
    repository = ReminderRepository(notifications);
  });

  test(
    'saves and reads a reminder, then deletes it and its notification',
    () async {
      final reminder = ReminderModel(
        id: 'reminder-1',
        title: 'Menonton Star Wars',
        scheduledAt: DateTime(2026, 11, 1, 19),
      );

      expect(await repository.getReminders(), isEmpty);
      expect(await repository.save(reminder), isTrue);

      final saved = await repository.getReminders();
      expect(saved, hasLength(1));
      expect(saved.single.toJson(), reminder.toJson());
      expect(notifications.scheduledIds, ['reminder-1']);

      await repository.delete(reminder.id);

      expect(await repository.getReminders(), isEmpty);
      expect(notifications.cancelledIds, ['reminder-1']);
    },
  );
}

class _RecordingNotificationService extends NotificationService {
  final scheduledIds = <String>[];
  final cancelledIds = <String>[];

  @override
  Future<bool> schedule({
    required String reminderId,
    required String title,
    required DateTime scheduledAt,
  }) async {
    scheduledIds.add(reminderId);
    return true;
  }

  @override
  Future<void> cancel(String reminderId) async {
    cancelledIds.add(reminderId);
  }
}
