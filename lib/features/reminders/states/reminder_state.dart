import '../model/reminder_model.dart';

enum ReminderStatus { initial, loading, saving, success, failure }

class ReminderState {
  const ReminderState({
    this.status = ReminderStatus.initial,
    this.reminders = const [],
    this.errorMessage,
    this.notificationsAllowed,
  });

  final ReminderStatus status;
  final List<ReminderModel> reminders;
  final String? errorMessage;
  final bool? notificationsAllowed;
}
