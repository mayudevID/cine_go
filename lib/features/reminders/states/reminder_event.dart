import '../model/reminder_model.dart';

sealed class ReminderEvent {}

final class RemindersRequested extends ReminderEvent {}

final class ReminderSaved extends ReminderEvent {
  ReminderSaved(this.reminder);
  final ReminderModel reminder;
}

final class ReminderDeleted extends ReminderEvent {
  ReminderDeleted(this.id);
  final String id;
}
