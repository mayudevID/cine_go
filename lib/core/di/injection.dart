import 'package:get_it/get_it.dart';

import '../../features/cinemas/model/cinema_repository.dart';
import '../../features/cinemas/states/cinema_bloc.dart';
import '../../features/movies/model/movie_repository.dart';
import '../../features/movies/states/movie_detail_bloc.dart';
import '../../features/movies/states/movie_list_bloc.dart';
import '../../features/movies/states/movie_related_detail_bloc.dart';
import '../../features/reminders/model/reminder_repository.dart';
import '../../features/reminders/states/reminder_bloc.dart';
import '../api/dio_client.dart';
import '../event_bus/app_event_bus.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt.registerLazySingleton<DioClient>(DioClient.new);
  getIt.registerLazySingleton<AppEventBus>(AppEventBus.new);
  getIt.registerLazySingleton<LocationService>(LocationService.new);
  getIt.registerLazySingleton<NotificationService>(NotificationService.new);
  getIt.registerLazySingleton<MovieRepository>(
    () => MovieRepository(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<CinemaRepository>(
    () => CinemaRepository(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<ReminderRepository>(
    () => ReminderRepository(getIt<NotificationService>()),
  );
  getIt.registerFactory(() => MovieListBloc(getIt<MovieRepository>()));
  getIt.registerFactory(() => MovieDetailBloc(getIt<MovieRepository>()));
  getIt.registerFactory(() => MovieRelatedDetailBloc(getIt<MovieRepository>()));
  getIt.registerFactory(
    () => CinemaBloc(getIt<CinemaRepository>(), getIt<LocationService>()),
  );
  getIt.registerFactory(
    () => ReminderBloc(getIt<ReminderRepository>(), getIt<AppEventBus>()),
  );
}
