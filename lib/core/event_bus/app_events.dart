abstract interface class AppEvent {}

class ReminderCreatedEvent implements AppEvent {
  const ReminderCreatedEvent(this.reminderId);
  final String reminderId;
}

class ReminderDeletedEvent implements AppEvent {
  const ReminderDeletedEvent(this.reminderId);
  final String reminderId;
}
