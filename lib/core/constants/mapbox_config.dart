import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class MapboxConfig {
  static String get accessToken =>
      dotenv.env['MAPBOX_ACCESS_TOKEN']?.trim() ?? '';

  static bool get isConfigured => accessToken.isNotEmpty;
}
