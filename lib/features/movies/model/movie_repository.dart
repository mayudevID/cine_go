import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import 'movie_related_content_model.dart';
import 'movie_model.dart';

class MovieRepository {
  MovieRepository(this._client);

  final DioClient _client;

  Future<List<MovieModel>> getMovies() async {
    final json = await _client.get<Map<String, Object?>>(ApiEndpoints.films);
    final results = json['results'];
    if (results is! List) return const [];
    return results
        .whereType<Map<String, Object?>>()
        .map(MovieModel.fromJson)
        .toList(growable: false)
      ..sort((a, b) => a.episodeId.compareTo(b.episodeId));
  }

  Future<MovieModel> getMovie(int id) async {
    final json = await _client.get<Map<String, Object?>>(ApiEndpoints.film(id));
    return MovieModel.fromJson(json);
  }

  Future<MovieRelatedContentModel> getRelatedContent(MovieModel movie) async {
    final categories = await Future.wait([
      _getItems(
        movie.characterUrls,
        type: MovieRelatedType.character,
        subtitleFields: const {'gender': 'Jenis kelamin'},
        detailFields: const {'birth_year': 'Lahir', 'height': 'Tinggi'},
      ),
      _getItems(
        movie.speciesUrls,
        type: MovieRelatedType.species,
        subtitleFields: const {'classification': 'Klasifikasi'},
        detailFields: const {'language': 'Bahasa'},
      ),
      _getItems(
        movie.vehicleUrls,
        type: MovieRelatedType.vehicle,
        subtitleFields: const {'model': 'Model'},
        detailFields: const {'vehicle_class': 'Kelas'},
      ),
      _getItems(
        movie.planetUrls,
        type: MovieRelatedType.planet,
        subtitleFields: const {'climate': 'Iklim'},
        detailFields: const {'terrain': 'Medan'},
      ),
      _getItems(
        movie.starshipUrls,
        type: MovieRelatedType.starship,
        subtitleFields: const {'model': 'Model'},
        detailFields: const {'starship_class': 'Kelas'},
      ),
    ]);
    return MovieRelatedContentModel(
      characters: categories[0].items,
      species: categories[1].items,
      vehicles: categories[2].items,
      planets: categories[3].items,
      starships: categories[4].items,
      failedResourceCount: categories.fold(
        0,
        (total, category) => total + category.failedCount,
      ),
    );
  }

  Future<MovieRelatedDetailModel> getRelatedItemDetail(
    MovieRelatedItemModel item,
  ) async {
    final json = await _client.getUri<Map<String, Object?>>(
      Uri.parse(item.url),
    );
    final fields = _detailFieldsFor(item.type).entries
        .map((field) {
          final value = _firstValue(json, field.key);
          if (value == null) return null;
          final displayValue = field.key == 'height' ? '$value cm' : value;
          return MovieRelatedDetailField(
            label: field.value,
            value: displayValue,
          );
        })
        .whereType<MovieRelatedDetailField>()
        .toList(growable: false);

    return MovieRelatedDetailModel(
      name: _firstValue(json, 'name') ?? item.name,
      type: item.type,
      fields: fields,
    );
  }

  Future<_RelatedItemsResult> _getItems(
    List<String> urls, {
    required MovieRelatedType type,
    required Map<String, String> subtitleFields,
    required Map<String, String> detailFields,
  }) async {
    final results = await Future.wait(
      urls.map(
        (url) => _getItem(
          url,
          type: type,
          subtitleFields: subtitleFields,
          detailFields: detailFields,
        ),
      ),
    );
    final items = results.whereType<MovieRelatedItemModel>().toList(
      growable: false,
    );
    return _RelatedItemsResult(
      items: items,
      failedCount: urls.length - items.length,
    );
  }

  Future<MovieRelatedItemModel?> _getItem(
    String url, {
    required MovieRelatedType type,
    required Map<String, String> subtitleFields,
    required Map<String, String> detailFields,
  }) async {
    try {
      final json = await _client.getUri<Map<String, Object?>>(Uri.parse(url));
      return MovieRelatedItemModel(
        url: url,
        type: type,
        name: _firstValue(json, 'name') ?? 'Tidak diketahui',
        subtitle: _formatFields(json, subtitleFields),
        details: _formatFields(json, detailFields),
      );
    } on Exception {
      return null;
    }
  }

  String? _firstValue(Map<String, Object?> json, String key) {
    final value = json[key]?.toString().trim();
    if (value == null ||
        value.isEmpty ||
        value == 'unknown' ||
        value == 'n/a') {
      return null;
    }
    return value;
  }

  String _formatFields(Map<String, Object?> json, Map<String, String> fields) =>
      fields.entries
          .map((field) {
            final value = _firstValue(json, field.key);
            if (value == null) return null;
            final displayValue = field.key == 'height' ? '$value cm' : value;
            return '${field.value}: $displayValue';
          })
          .whereType<String>()
          .join(' · ');

  Map<String, String> _detailFieldsFor(MovieRelatedType type) => switch (type) {
    MovieRelatedType.character => const {
      'height': 'Tinggi',
      'mass': 'Berat',
      'hair_color': 'Warna rambut',
      'skin_color': 'Warna kulit',
      'eye_color': 'Warna mata',
      'birth_year': 'Tahun lahir',
      'gender': 'Jenis kelamin',
    },
    MovieRelatedType.species => const {
      'classification': 'Klasifikasi',
      'designation': 'Jenis',
      'average_height': 'Tinggi rata-rata',
      'average_lifespan': 'Usia rata-rata',
      'eye_colors': 'Warna mata',
      'hair_colors': 'Warna rambut',
      'skin_colors': 'Warna kulit',
      'language': 'Bahasa',
    },
    MovieRelatedType.planet => const {
      'rotation_period': 'Periode rotasi',
      'orbital_period': 'Periode orbit',
      'diameter': 'Diameter',
      'climate': 'Iklim',
      'gravity': 'Gravitasi',
      'terrain': 'Medan',
      'surface_water': 'Air permukaan',
      'population': 'Populasi',
    },
    MovieRelatedType.vehicle => const {
      'model': 'Model',
      'manufacturer': 'Produsen',
      'cost_in_credits': 'Harga (kredit)',
      'length': 'Panjang',
      'max_atmosphering_speed': 'Kecepatan maksimum',
      'crew': 'Kru',
      'passengers': 'Penumpang',
      'cargo_capacity': 'Kapasitas kargo',
      'consumables': 'Daya tahan suplai',
      'vehicle_class': 'Kelas kendaraan',
    },
    MovieRelatedType.starship => const {
      'model': 'Model',
      'manufacturer': 'Produsen',
      'cost_in_credits': 'Harga (kredit)',
      'length': 'Panjang',
      'max_atmosphering_speed': 'Kecepatan maksimum',
      'crew': 'Kru',
      'passengers': 'Penumpang',
      'cargo_capacity': 'Kapasitas kargo',
      'consumables': 'Daya tahan suplai',
      'hyperdrive_rating': 'Tingkat mesin hiperangkasa',
      'MGLT': 'Kecepatan MGLT',
      'starship_class': 'Kelas kapal antarbintang',
    },
  };
}

class _RelatedItemsResult {
  const _RelatedItemsResult({required this.items, required this.failedCount});

  final List<MovieRelatedItemModel> items;
  final int failedCount;
}
