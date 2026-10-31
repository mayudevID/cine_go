import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/movie_repository.dart';
import 'movie_related_detail_event.dart';
import 'movie_related_detail_state.dart';

class MovieRelatedDetailBloc
    extends Bloc<MovieRelatedDetailEvent, MovieRelatedDetailState> {
  MovieRelatedDetailBloc(this._repository)
    : super(const MovieRelatedDetailState()) {
    on<MovieRelatedDetailRequested>(_onRequested);
  }

  final MovieRepository _repository;

  Future<void> _onRequested(
    MovieRelatedDetailRequested event,
    Emitter<MovieRelatedDetailState> emit,
  ) async {
    emit(
      const MovieRelatedDetailState(status: MovieRelatedDetailStatus.loading),
    );
    try {
      final detail = await _repository.getRelatedItemDetail(event.item);
      emit(
        MovieRelatedDetailState(
          status: MovieRelatedDetailStatus.success,
          detail: detail,
        ),
      );
    } catch (_) {
      emit(
        MovieRelatedDetailState(
          status: MovieRelatedDetailStatus.failure,
          errorMessage:
              'Informasi detail belum bisa dimuat. Periksa koneksi internet, lalu coba lagi.',
        ),
      );
    }
  }
}
