import '../model/movie_related_content_model.dart';

sealed class MovieRelatedDetailEvent {}

final class MovieRelatedDetailRequested extends MovieRelatedDetailEvent {
  MovieRelatedDetailRequested(this.item);

  final MovieRelatedItemModel item;
}
