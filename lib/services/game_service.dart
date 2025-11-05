import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/game.dart';

/// Service class for interacting with the RAWG.io API
/// Handles fetching game data and searching for games
class GameService {
  /// Searches for games by name
  /// Returns a list of Game objects matching the search query
  Future<List<Game>> searchGames(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      // Encode the search query to handle spaces and special characters
      final encodedQuery = Uri.encodeQueryComponent(query.trim());
      final url = '${ApiConfig.getUrl('/games')}&search=$encodedQuery&page_size=20';
      final uri = Uri.parse(url);
      
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Check if results key exists and is a list
        if (data.containsKey('results') && data['results'] != null) {
          final results = data['results'] as List;
          
          // Parse games, filtering out any that fail to parse
          final games = <Game>[];
          for (var item in results) {
            try {
              if (item is Map<String, dynamic>) {
                games.add(Game.fromJson(item));
              }
            } catch (e) {
              // Skip games that fail to parse
              print('Error parsing game: $e');
            }
          }
          
          return games;
        } else {
          // API returned success but no results
          return [];
        }
      } else {
        // Log the error and throw it so the UI can show it
        print('API Error: Status ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to search games: Status ${response.statusCode}');
      }
    } catch (e) {
      // Log the error and rethrow it instead of returning dummy data
      print('Search error: $e');
      rethrow;
    }
  }

  /// Gets a specific game by ID
  Future<Game?> getGameById(int id) async {
    try {
      final url = ApiConfig.getUrl('/games/$id');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Game.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Gets the list of available platforms from the RAWG API
  /// Returns a list of platform names
  Future<List<String>> getPlatforms() async {
    try {
      final url = '${ApiConfig.getUrl('/platforms')}&page_size=50';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        if (data.containsKey('results') && data['results'] != null) {
          final results = data['results'] as List;
          
          final platforms = <String>[];
          for (var item in results) {
            try {
              if (item is Map<String, dynamic> && item['name'] != null) {
                platforms.add(item['name'] as String);
              }
            } catch (e) {
              print('Error parsing platform: $e');
            }
          }
          
          return platforms..sort();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching platforms: $e');
      return [];
    }
  }
}

