import '../model/cinema_model.dart';

sealed class CinemaEvent {}

final class CinemasRequested extends CinemaEvent {}

final class CinemaSelected extends CinemaEvent {
  CinemaSelected(this.cinema);

  final CinemaModel cinema;
}
