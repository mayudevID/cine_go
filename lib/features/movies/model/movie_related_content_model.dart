enum MovieRelatedType { character, species, planet, vehicle, starship }

class MovieRelatedItemModel {
  const MovieRelatedItemModel({
    required this.url,
    required this.type,
    required this.name,
    required this.subtitle,
    required this.details,
  });

  final String url;
  final MovieRelatedType type;
  final String name;
  final String subtitle;
  final String details;
}

class MovieRelatedDetailField {
  const MovieRelatedDetailField({required this.label, required this.value});

  final String label;
  final String value;
}

class MovieRelatedDetailModel {
  const MovieRelatedDetailModel({
    required this.name,
    required this.type,
    required this.fields,
  });

  final String name;
  final MovieRelatedType type;
  final List<MovieRelatedDetailField> fields;
}

class MovieRelatedContentModel {
  const MovieRelatedContentModel({
    this.characters = const [],
    this.species = const [],
    this.vehicles = const [],
    this.planets = const [],
    this.starships = const [],
    this.failedResourceCount = 0,
  });

  final List<MovieRelatedItemModel> characters;
  final List<MovieRelatedItemModel> species;
  final List<MovieRelatedItemModel> vehicles;
  final List<MovieRelatedItemModel> planets;
  final List<MovieRelatedItemModel> starships;
  final int failedResourceCount;
}
