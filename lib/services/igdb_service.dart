import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/game.dart';

/// 🌉 Servicio que habla con el backend propio para consultar la API de IGDB
/// 👉 El backend expone endpoints seguros que esconden las credenciales de Twitch
class IgdbService {
  IgdbService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// 🔎 Busca juegos utilizando el endpoint proxy `/api/games`
  Future<List<Game>> searchGames(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return [];
    }

    final uri = ApiConfig.buildUri('/api/games', {'search': trimmedQuery});
    final response = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'IGDB proxy error ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected response format from IGDB proxy');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Game.fromJson)
        .toList();
  }

  /// 👋 Cierra el cliente HTTP en caso de que quieras liberar recursos manualmente
  void dispose() {
    _client.close();
  }
}


