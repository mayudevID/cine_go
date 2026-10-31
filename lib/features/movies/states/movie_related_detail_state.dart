import 'package:equatable/equatable.dart';

import '../model/movie_related_content_model.dart';

enum MovieRelatedDetailStatus { initial, loading, success, failure }

class MovieRelatedDetailState extends Equatable {
  const MovieRelatedDetailState({
    this.status = MovieRelatedDetailStatus.initial,
    this.detail,
    this.errorMessage,
  });

  final MovieRelatedDetailStatus status;
  final MovieRelatedDetailModel? detail;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, detail, errorMessage];
}
