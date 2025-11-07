import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/game.dart';

/// 🌐 Servicio para hablar con la API de RAWG.io (todavía sigo entendiendo su docs)
/// 🕹️ Aquí descargo datos de juegos y hago las búsquedas que pide la app
class GameService {
  /// 🔎 Busca juegos por nombre
  /// 📦 Devuelve una lista de `Game` que coinciden con la búsqueda
  Future<List<Game>> searchGames(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      // 🔤 Codifico la búsqueda para que los espacios y caracteres raros no rompan la URL
      final encodedQuery = Uri.encodeQueryComponent(query.trim());
      final url = '${ApiConfig.getUrl('/games')}&search=$encodedQuery&page_size=20';
      final uri = Uri.parse(url);
      
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // 🧪 Reviso que venga la clave `results` y que realmente sea una lista
        if (data.containsKey('results') && data['results'] != null) {
          final results = data['results'] as List;
          
          // 🧱 Armo la lista de juegos, saltando los que no pueda parsear (todavía no sé logging pro)
          final games = <Game>[];
          for (var item in results) {
            try {
              if (item is Map<String, dynamic>) {
                games.add(Game.fromJson(item));
              }
            } catch (e) {
              // 🙅‍♂️ Si un juego falla al parsear, simplemente lo ignoro
              print('Error parsing game: $e');
            }
          }
          
          return games;
        } else {
          // 🤷‍♀️ La API dijo que todo bien pero no vienen resultados
          return [];
        }
      } else {
        // 🚨 Guardo un log básico y lanzo la excepción para que la UI se entere
        print('API Error: Status ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to search games: Status ${response.statusCode}');
      }
    } catch (e) {
      // 📝 Anoto el error y lo relanzo (prefiero eso a inventarme datos)
      print('Search error: $e');
      rethrow;
    }
  }

  /// 🎯 Obtiene un juego específico por su ID
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

  /// 🗂️ Descarga la lista de plataformas disponibles desde RAWG
  /// 📋 Devuelve solo los nombres de las plataformas
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

