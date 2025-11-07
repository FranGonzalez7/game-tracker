import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 🌱 Archivo de configuración para las claves y endpoints de la API
/// 
/// 📌 Recuerda: la API key se carga desde el archivo `.env`
/// ✍️ Copia `.env.example` a `.env` y añade tu clave de RAWG.io
/// 👉 La clave gratis se consigue aquí: https://rawg.io/apidocs
class ApiConfig {
  static const String baseUrl = 'https://api.rawg.io/api';
  
  /// 🤓 Consigue la API key de RAWG desde las variables de entorno
  /// 😬 Lanza una excepción si no la encontramos (para que no se nos pase)
  static String get rawgApiKey {
    final apiKey = dotenv.env['RAWG_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'RAWG_API_KEY not found in .env file. '
        'Please create a .env file with your API key. '
        'See .env.example for reference.'
      );
    }
    return apiKey;
  }
  
  /// 🧩 Devuelve la URL completa de la API incluyendo la key
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint?key=$rawgApiKey';
  }
}

