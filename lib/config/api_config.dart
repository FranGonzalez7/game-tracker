import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 🌱 Archivo de configuración para los endpoints del backend propio
///
/// 📌 Recuerda: la URL base se carga desde el archivo `.env`
/// ✍️ Copia `.env.example` a `.env` y añade `BACKEND_BASE_URL=https://tu-servidor.com`
class ApiConfig {
  /// 🌍 Lee la URL base del backend proxy (por ejemplo: https://mi-servidor.com)
  static String get backendBaseUrl {
    final baseUrl = dotenv.env['BACKEND_BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception(
        'BACKEND_BASE_URL not found in .env file. '
        'Please create a .env file with your backend base URL. '
        'See .env.example for reference.',
      );
    }
    return baseUrl;
  }

  /// 🧭 Construye un `Uri` a partir del path del backend y parámetros opcionales
  static Uri buildUri(String path, [Map<String, String>? queryParameters]) {
    final normalizedBase = backendBaseUrl.endsWith('/')
        ? backendBaseUrl.substring(0, backendBaseUrl.length - 1)
        : backendBaseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$normalizedBase$normalizedPath');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: queryParameters);
  }
}

