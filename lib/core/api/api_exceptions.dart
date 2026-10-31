import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final message = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Waktu tunggu respons server habis. Coba lagi.',
      DioExceptionType.connectionError =>
        'Tidak dapat terhubung. Periksa koneksi internet Anda.',
      DioExceptionType.cancel => 'Permintaan dibatalkan.',
      _ =>
        statusCode == null
            ? 'Terjadi kesalahan saat memuat data.'
            : 'Server mengalami kendala (kode $statusCode).',
    };
    return ApiException(message, statusCode: statusCode);
  }

  @override
  String toString() => message;
}
