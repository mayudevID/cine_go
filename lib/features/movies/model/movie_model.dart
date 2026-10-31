class MovieModel {
  const MovieModel({
    required this.title,
    required this.episodeId,
    required this.openingCrawl,
    required this.director,
    required this.producer,
    required this.releaseDate,
    required this.url,
    this.characterUrls = const [],
    this.speciesUrls = const [],
    this.vehicleUrls = const [],
    this.planetUrls = const [],
    this.starshipUrls = const [],
  });

  final String title;
  final int episodeId;
  final String openingCrawl;
  final String director;
  final String producer;
  final DateTime? releaseDate;
  final String url;
  final List<String> characterUrls;
  final List<String> speciesUrls;
  final List<String> vehicleUrls;
  final List<String> planetUrls;
  final List<String> starshipUrls;

  factory MovieModel.fromJson(Map<String, Object?> json) => MovieModel(
    title: json['title'] as String? ?? 'Film tanpa judul',
    episodeId: (json['episode_id'] as num?)?.toInt() ?? 0,
    openingCrawl: json['opening_crawl'] as String? ?? '',
    director: json['director'] as String? ?? 'Tidak diketahui',
    producer: json['producer'] as String? ?? 'Tidak diketahui',
    releaseDate: DateTime.tryParse(json['release_date'] as String? ?? ''),
    url: json['url'] as String? ?? '',
    characterUrls: _readUrls(json['characters']),
    speciesUrls: _readUrls(json['species']),
    vehicleUrls: _readUrls(json['vehicles']),
    planetUrls: _readUrls(json['planets']),
    starshipUrls: _readUrls(json['starships']),
  );

  int? get id {
    final match = RegExp(r'/films/(\d+)/?$').firstMatch(url);
    return match == null ? null : int.tryParse(match.group(1)!);
  }
}

List<String> _readUrls(Object? value) => value is List
    ? value.whereType<String>().toList(growable: false)
    : const [];
