sealed class MovieDetailEvent {}

final class MovieDetailRequested extends MovieDetailEvent {
  MovieDetailRequested(this.id);
  final int id;
}

final class MovieRelatedContentRequested extends MovieDetailEvent {
  MovieRelatedContentRequested();
}
