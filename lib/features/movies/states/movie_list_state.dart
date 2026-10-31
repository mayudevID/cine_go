import 'package:equatable/equatable.dart';

import '../model/movie_model.dart';

enum MovieListStatus { initial, loading, success, empty, failure }

class MovieListState extends Equatable {
  const MovieListState({
    this.status = MovieListStatus.initial,
    this.movies = const [],
    this.errorMessage,
  });

  final MovieListStatus status;
  final List<MovieModel> movies;
  final String? errorMessage;

  MovieListState copyWith({
    MovieListStatus? status,
    List<MovieModel>? movies,
    String? errorMessage,
  }) => MovieListState(
    status: status ?? this.status,
    movies: movies ?? this.movies,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [status, movies, errorMessage];
}
