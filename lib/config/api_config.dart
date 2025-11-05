import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration file for API keys and endpoints
/// 
/// IMPORTANT: The API key is loaded from .env file
/// Copy .env.example to .env and add your RAWG.io API key
/// You can get a free API key at: https://rawg.io/apidocs
class ApiConfig {
  static const String baseUrl = 'https://api.rawg.io/api';
  
  /// Gets the RAWG API key from environment variables
  /// Throws an exception if the key is not found
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
  
  /// Returns the full API URL with key
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint?key=$rawgApiKey';
  }
}

