import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/movie_repository.dart';
import 'movie_list_event.dart';
import 'movie_list_state.dart';

class MovieListBloc extends Bloc<MovieListEvent, MovieListState> {
  MovieListBloc(this._repository) : super(const MovieListState()) {
    on<MovieListRequested>(_onRequested);
  }

  final MovieRepository _repository;

  Future<void> _onRequested(
    MovieListRequested event,
    Emitter<MovieListState> emit,
  ) async {
    emit(state.copyWith(status: MovieListStatus.loading));
    try {
      final movies = await _repository.getMovies();
      emit(
        MovieListState(
          status: movies.isEmpty
              ? MovieListStatus.empty
              : MovieListStatus.success,
          movies: movies,
        ),
      );
    } catch (_) {
      emit(
        MovieListState(
          status: MovieListStatus.failure,
          errorMessage:
              'Film belum bisa dimuat. Periksa koneksi internet, lalu coba lagi.',
        ),
      );
    }
  }
}
