import '../model/cinema_model.dart';
import '../model/cinema_route_model.dart';

enum CinemaStatus { initial, loading, success, empty, failure }

enum CinemaRouteStatus { initial, loading, success, failure }

class CinemaState {
  const CinemaState({
    this.status = CinemaStatus.initial,
    this.cinemas = const [],
    this.errorMessage,
    this.selectedCinema,
    this.routeStatus = CinemaRouteStatus.initial,
    this.route,
    this.routeError,
  });

  final CinemaStatus status;
  final List<CinemaModel> cinemas;
  final String? errorMessage;
  final CinemaModel? selectedCinema;
  final CinemaRouteStatus routeStatus;
  final CinemaRouteModel? route;
  final String? routeError;
}
