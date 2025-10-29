/// Configuration file for API keys and endpoints
/// 
/// IMPORTANT: Add your RAWG.io API key here
/// You can get a free API key at: https://rawg.io/apidocs
class ApiConfig {
  // TODO: Replace with your actual RAWG.io API key
  static const String rawgApiKey = '0b98eaa93e43454193320ea18051ea79';
  static const String baseUrl = 'https://api.rawg.io/api';
  
  /// Returns the full API URL with key
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint?key=$rawgApiKey';
  }
}

