import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class ApiEndpoints {
  static String get baseUrl {
    final value = dotenv.env['SWAPI_BASE_URL']?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('SWAPI_BASE_URL belum diatur di berkas .env.');
    }
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw StateError('SWAPI_BASE_URL harus berupa alamat HTTPS yang valid.');
    }
    return value.endsWith('/') ? value : '$value/';
  }

  static const films = 'films/';

  static String film(int id) => 'films/$id/';
  static String person(int id) => 'people/$id/';
}
