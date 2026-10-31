class CinemaCoordinate {
  const CinemaCoordinate(this.longitude, this.latitude);

  final double longitude;
  final double latitude;
}

class CinemaRouteModel {
  const CinemaRouteModel({
    required this.coordinates,
    required this.eta,
    required this.distanceMeters,
  });

  final List<CinemaCoordinate> coordinates;
  final Duration eta;
  final double distanceMeters;
}
