import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/event_bus/app_event_bus.dart';
import '../../../core/event_bus/app_events.dart';
import '../model/reminder_repository.dart';
import 'reminder_event.dart';
import 'reminder_state.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  ReminderBloc(this._repository, this._eventBus)
    : super(const ReminderState()) {
    on<RemindersRequested>(_onRequested);
    on<ReminderSaved>(_onSaved);
    on<ReminderDeleted>(_onDeleted);
  }

  final ReminderRepository _repository;
  final AppEventBus _eventBus;
  StreamSubscription<ReminderCreatedEvent>? _createdSubscription;
  StreamSubscription<ReminderDeletedEvent>? _deletedSubscription;

  Future<void> _onRequested(
    RemindersRequested event,
    Emitter<ReminderState> emit,
  ) async {
    _listenForReminderChanges();
    emit(const ReminderState(status: ReminderStatus.loading));
    try {
      emit(
        ReminderState(
          status: ReminderStatus.success,
          reminders: await _repository.getReminders(),
        ),
      );
    } catch (_) {
      emit(
        const ReminderState(
          status: ReminderStatus.failure,
          errorMessage: 'Pengingat belum bisa dimuat. Silakan coba lagi.',
        ),
      );
    }
  }

  Future<void> _onSaved(
    ReminderSaved event,
    Emitter<ReminderState> emit,
  ) async {
    emit(
      ReminderState(status: ReminderStatus.saving, reminders: state.reminders),
    );
    try {
      final notificationsAllowed = await _repository.save(event.reminder);
      _eventBus.fire(ReminderCreatedEvent(event.reminder.id));
      emit(
        ReminderState(
          status: ReminderStatus.success,
          reminders: await _repository.getReminders(),
          notificationsAllowed: notificationsAllowed,
        ),
      );
    } catch (_) {
      emit(
        ReminderState(
          status: ReminderStatus.failure,
          reminders: state.reminders,
          errorMessage: 'Pengingat belum bisa disimpan. Silakan coba lagi.',
        ),
      );
    }
  }

  Future<void> _onDeleted(
    ReminderDeleted event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      await _repository.delete(event.id);
      final updatedReminders = state.reminders
          .where((reminder) => reminder.id != event.id)
          .toList(growable: false);
      emit(
        ReminderState(
          status: ReminderStatus.success,
          reminders: updatedReminders,
        ),
      );
      _eventBus.fire(ReminderDeletedEvent(event.id));
    } catch (_) {
      emit(
        ReminderState(
          status: ReminderStatus.failure,
          reminders: state.reminders,
          errorMessage: 'Pengingat belum bisa dihapus. Silakan coba lagi.',
        ),
      );
    }
  }

  void _listenForReminderChanges() {
    if (_createdSubscription != null) return;
    _createdSubscription = _eventBus.on<ReminderCreatedEvent>().listen((event) {
      if (state.status == ReminderStatus.success &&
          !state.reminders.any((reminder) => reminder.id == event.reminderId)) {
        add(RemindersRequested());
      }
    });
    _deletedSubscription = _eventBus.on<ReminderDeletedEvent>().listen((event) {
      if (state.status == ReminderStatus.success &&
          state.reminders.any((reminder) => reminder.id == event.reminderId)) {
        add(RemindersRequested());
      }
    });
  }

  @override
  Future<void> close() async {
    await _createdSubscription?.cancel();
    await _deletedSubscription?.cancel();
    await super.close();
  }
}
