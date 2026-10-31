import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/movie_model.dart';
import '../model/movie_repository.dart';
import 'movie_detail_event.dart';
import 'movie_detail_state.dart';

class MovieDetailBloc extends Bloc<MovieDetailEvent, MovieDetailState> {
  MovieDetailBloc(this._repository) : super(const MovieDetailState()) {
    on<MovieDetailRequested>(_onRequested);
    on<MovieRelatedContentRequested>(_onRelatedContentRequested);
  }

  final MovieRepository _repository;

  Future<void> _onRequested(
    MovieDetailRequested event,
    Emitter<MovieDetailState> emit,
  ) async {
    emit(const MovieDetailState(status: MovieDetailStatus.loading));
    try {
      final movie = await _repository.getMovie(event.id);
      emit(
        MovieDetailState(
          status: MovieDetailStatus.success,
          movie: movie,
          relatedStatus: MovieRelatedStatus.loading,
        ),
      );
      await _loadRelatedContent(movie, emit);
    } catch (_) {
      emit(
        MovieDetailState(
          status: MovieDetailStatus.failure,
          errorMessage:
              'Detail film belum bisa dimuat. Periksa koneksi internet, lalu coba lagi.',
        ),
      );
    }
  }

  Future<void> _onRelatedContentRequested(
    MovieRelatedContentRequested event,
    Emitter<MovieDetailState> emit,
  ) async {
    final movie = state.movie;
    if (movie == null) return;

    emit(
      MovieDetailState(
        status: state.status,
        movie: movie,
        errorMessage: state.errorMessage,
        relatedStatus: MovieRelatedStatus.loading,
        relatedContent: state.relatedContent,
      ),
    );
    await _loadRelatedContent(movie, emit);
  }

  Future<void> _loadRelatedContent(
    MovieModel movie,
    Emitter<MovieDetailState> emit,
  ) async {
    try {
      final relatedContent = await _repository.getRelatedContent(movie);
      emit(
        MovieDetailState(
          status: MovieDetailStatus.success,
          movie: movie,
          relatedStatus: MovieRelatedStatus.success,
          relatedContent: relatedContent,
        ),
      );
    } catch (_) {
      emit(
        MovieDetailState(
          status: MovieDetailStatus.success,
          movie: movie,
          relatedStatus: MovieRelatedStatus.failure,
          relatedError:
              'Informasi tambahan belum bisa dimuat. Silakan coba lagi.',
        ),
      );
    }
  }
}
