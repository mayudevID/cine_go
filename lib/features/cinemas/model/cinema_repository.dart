import 'cinema_model.dart';
import 'cinema_route_model.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/constants/mapbox_config.dart';

class CinemaRepository {
  CinemaRepository(this._dioClient);

  final DioClient _dioClient;

  static const _cinemas = [
    // 1. CGV Grand Indonesia - Jakarta Pusat
    CinemaModel(
      id: 'cgv-grand-indonesia',
      name: 'CGV Grand Indonesia',
      address:
          'Grand Indonesia, West Mall Lt. 8, Jl. M.H. Thamrin No. 1, Jakarta Pusat',
      latitude: -6.1953048,
      longitude: 106.8198451,
    ),

    // 2. CGV Central Park - Jakarta Barat
    CinemaModel(
      id: 'cgv-central-park',
      name: 'CGV Central Park',
      address:
          'Central Park Mall Lt. 8, Jl. Letjen S. Parman Kav. 28, Jakarta Barat',
      latitude: -6.1774489,
      longitude: 106.7913872,
    ),

    // 3. Plaza Senayan XXI - Jakarta Pusat
    CinemaModel(
      id: 'xxi-plaza-senayan',
      name: 'Plaza Senayan XXI',
      address: 'Plaza Senayan Lt. 5, Jl. Asia Afrika No. 8, Jakarta Pusat',
      latitude: -6.2254885,
      longitude: 106.7991713,
    ),

    // 4. Kota Kasablanka XXI - Jakarta Selatan
    CinemaModel(
      id: 'xxi-kota-kasablanka',
      name: 'Kota Kasablanka XXI',
      address:
          'Mall Kota Kasablanka Lt. 2, Jl. Casablanca Kav. 88, Jakarta Selatan',
      latitude: -6.2240879,
      longitude: 106.8432409,
    ),

    // 5. CGV Pacific Place - Jakarta Selatan
    CinemaModel(
      id: 'cgv-pacific-place',
      name: 'CGV Pacific Place',
      address:
          'Pacific Place Mall Lt. 6, Jl. Jend. Sudirman Kav. 52-53, Jakarta Selatan',
      latitude: -6.2245794,
      longitude: 106.8098421,
    ),

    // 6. Senayan City XXI - Jakarta Pusat
    CinemaModel(
      id: 'xxi-senayan-city',
      name: 'Senayan City XXI',
      address: 'Senayan City Lt. 5, Jl. Asia Afrika Lot 19, Jakarta Pusat',
      latitude: -6.2269804,
      longitude: 106.7974203,
    ),

    // 7. Gandaria City XXI - Jakarta Selatan
    CinemaModel(
      id: 'xxi-gandaria-city',
      name: 'Gandaria City XXI',
      address:
          'Gandaria City Mall Lt. 2, Jl. Sultan Iskandar Muda, Jakarta Selatan',
      latitude: -6.2442141,
      longitude: 106.7834916,
    ),

    // 8. Pondok Indah 2 XXI - Jakarta Selatan
    CinemaModel(
      id: 'xxi-pondok-indah-2',
      name: 'Pondok Indah 2 XXI',
      address:
          'Pondok Indah Mall 2 Lt. 3, Jl. Metro Pondok Indah, Jakarta Selatan',
      latitude: -6.2658700,
      longitude: 106.7824805,
    ),

    // 9. Metropole XXI - Jakarta Pusat
    CinemaModel(
      id: 'xxi-metropole',
      name: 'Metropole XXI',
      address:
          'Kompleks Megaria, Jl. Pegangsaan No. 21, Menteng, Jakarta Pusat',
      latitude: -6.2000641,
      longitude: 106.8437457,
    ),

    // 10. Plaza Indonesia XXI - Jakarta Pusat
    CinemaModel(
      id: 'xxi-plaza-indonesia',
      name: 'Plaza Indonesia XXI',
      address:
          'Plaza Indonesia Lt. 6, Jl. M.H. Thamrin No. 28-30, Jakarta Pusat',
      latitude: -6.1929984,
      longitude: 106.8222360,
    ),

    // 11. Epicentrum XXI - Jakarta Selatan
    CinemaModel(
      id: 'xxi-epicentrum',
      name: 'Epicentrum XXI',
      address:
          'Epicentrum Walk Ground Floor, Jl. H.R. Rasuna Said, Jakarta Selatan',
      latitude: -6.2166551,
      longitude: 106.8347158,
    ),

    // 12. Blok M XXI - Jakarta Selatan
    CinemaModel(
      id: 'xxi-blok-m',
      name: 'Blok M XXI',
      address: 'Blok M Plaza Lt. 6, Jl. Bulungan No. 76, Jakarta Selatan',
      latitude: -6.2441878,
      longitude: 106.7975326,
    ),

    // 13. Lotte Shopping Avenue XXI - Jakarta Selatan
    CinemaModel(
      id: 'xxi-lotte-shopping-avenue',
      name: 'Lotte Shopping Avenue XXI',
      address:
          'Lotte Shopping Avenue Lt. 6, Jl. Prof. Dr. Satrio Kav. 3-5, Jakarta Selatan',
      latitude: -6.2240206,
      longitude: 106.8227191,
    ),

    // 14. Kelapa Gading XXI - Jakarta Utara
    CinemaModel(
      id: 'xxi-kelapa-gading',
      name: 'Kelapa Gading XXI',
      address: 'Mall Kelapa Gading 3 Lt. 3, Jl. Boulevard Raya, Jakarta Utara',
      latitude: -6.1587948,
      longitude: 106.9070628,
    ),

    // 15. Arion XXI - Jakarta Timur
    // Koordinat referensi pusat Arion Mall
    CinemaModel(
      id: 'xxi-arion',
      name: 'Arion XXI',
      address: 'Arion Mall, Jl. Pemuda Kav. 3-4, Rawamangun, Jakarta Timur',
      latitude: -6.1938200,
      longitude: 106.8905500,
    ),
  ];

  Future<List<CinemaModel>> getCinemas() async => _cinemas;

  Future<CinemaRouteModel> getRoute({
    required double originLatitude,
    required double originLongitude,
    required CinemaModel destination,
  }) async {
    if (!MapboxConfig.isConfigured) {
      throw StateError('Token akses Mapbox belum dikonfigurasi.');
    }
    final uri = Uri.https(
      'api.mapbox.com',
      '/directions/v5/mapbox/driving/$originLongitude,$originLatitude;'
          '${destination.longitude},${destination.latitude}',
      {
        'alternatives': 'false',
        'geometries': 'geojson',
        'overview': 'full',
        'access_token': MapboxConfig.accessToken,
      },
    );
    final response = await _dioClient.getUri<Map<String, dynamic>>(uri);
    final routes = response['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      throw StateError('Rute berkendara tidak ditemukan.');
    }
    final route = routes.first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>;
    final rawCoordinates = geometry['coordinates'] as List<dynamic>;
    return CinemaRouteModel(
      coordinates: rawCoordinates
          .map((raw) {
            final coordinate = raw as List<dynamic>;
            return CinemaCoordinate(
              (coordinate[0] as num).toDouble(),
              (coordinate[1] as num).toDouble(),
            );
          })
          .toList(growable: false),
      eta: Duration(seconds: (route['duration'] as num).round()),
      distanceMeters: (route['distance'] as num).toDouble(),
    );
  }
}
