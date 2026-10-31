import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceException('Layanan lokasi sedang nonaktif.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Izin akses lokasi belum diberikan.',
      );
    }
    return Geolocator.getCurrentPosition();
  }
}

class LocationServiceException implements Exception {
  const LocationServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}
