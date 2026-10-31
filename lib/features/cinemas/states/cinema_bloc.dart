import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/location_service.dart';
import '../model/cinema_model.dart';
import '../model/cinema_repository.dart';
import 'cinema_event.dart';
import 'cinema_state.dart';

class CinemaBloc extends Bloc<CinemaEvent, CinemaState> {
  int _routeRequestGeneration = 0;

  CinemaBloc(this._repository, this._locationService)
    : super(const CinemaState()) {
    on<CinemasRequested>((event, emit) async {
      final previousSelection = state.selectedCinema;
      emit(
        CinemaState(
          status: CinemaStatus.loading,
          selectedCinema: previousSelection,
        ),
      );
      try {
        final cinemas = await _repository.getCinemas();
        CinemaModel? selectedCinema;
        for (final cinema in cinemas) {
          if (cinema.id == previousSelection?.id) {
            selectedCinema = cinema;
            break;
          }
        }
        emit(
          CinemaState(
            status: cinemas.isEmpty ? CinemaStatus.empty : CinemaStatus.success,
            cinemas: cinemas,
            selectedCinema: selectedCinema,
          ),
        );
        if (selectedCinema != null) add(CinemaSelected(selectedCinema));
      } catch (_) {
        emit(
          const CinemaState(
            status: CinemaStatus.failure,
            errorMessage:
                'Daftar bioskop belum bisa dimuat. Silakan coba lagi.',
          ),
        );
      }
    });
    on<CinemaSelected>((event, emit) async {
      final requestGeneration = ++_routeRequestGeneration;
      emit(
        CinemaState(
          status: state.status,
          cinemas: state.cinemas,
          selectedCinema: event.cinema,
          routeStatus: CinemaRouteStatus.loading,
        ),
      );
      try {
        final position = await _locationService.getCurrentPosition();
        final route = await _repository.getRoute(
          originLatitude: position.latitude,
          originLongitude: position.longitude,
          destination: event.cinema,
        );
        if (requestGeneration != _routeRequestGeneration) return;
        emit(
          CinemaState(
            status: state.status,
            cinemas: state.cinemas,
            selectedCinema: event.cinema,
            routeStatus: CinemaRouteStatus.success,
            route: route,
          ),
        );
      } catch (error) {
        if (requestGeneration != _routeRequestGeneration) return;
        if (kDebugMode) {
          debugPrint('[CinemaRoute] ${error.runtimeType}: $error');
        }
        emit(
          CinemaState(
            status: state.status,
            cinemas: state.cinemas,
            selectedCinema: event.cinema,
            routeStatus: CinemaRouteStatus.failure,
            routeError: _routeErrorMessage(error),
          ),
        );
      }
    });
  }

  final CinemaRepository _repository;
  final LocationService _locationService;

  String _routeErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('token')) {
      return 'Token akses peta belum dikonfigurasi.';
    }
    if (message.contains('lokasi') || message.contains('izin')) {
      return 'Izin akses lokasi diperlukan untuk menghitung rute.';
    }
    return 'Rute dan estimasi waktu belum tersedia. Silakan coba lagi.';
  }
}
