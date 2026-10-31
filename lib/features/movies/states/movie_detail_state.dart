import 'package:equatable/equatable.dart';

import '../model/movie_related_content_model.dart';
import '../model/movie_model.dart';

enum MovieDetailStatus { initial, loading, success, failure }

enum MovieRelatedStatus { initial, loading, success, failure }

class MovieDetailState extends Equatable {
  const MovieDetailState({
    this.status = MovieDetailStatus.initial,
    this.movie,
    this.errorMessage,
    this.relatedStatus = MovieRelatedStatus.initial,
    this.relatedContent,
    this.relatedError,
  });

  final MovieDetailStatus status;
  final MovieModel? movie;
  final String? errorMessage;
  final MovieRelatedStatus relatedStatus;
  final MovieRelatedContentModel? relatedContent;
  final String? relatedError;

  @override
  List<Object?> get props => [
    status,
    movie,
    errorMessage,
    relatedStatus,
    relatedContent,
    relatedError,
  ];
}
