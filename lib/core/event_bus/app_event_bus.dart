import 'package:event_bus/event_bus.dart';

import 'app_events.dart';

class AppEventBus {
  final EventBus _bus = EventBus();

  Stream<T> on<T extends AppEvent>() => _bus.on<T>();
  void fire(AppEvent event) => _bus.fire(event);
  void close() => _bus.destroy();
}
