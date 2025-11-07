/// 🎮 Modelo que representa un juego obtenido desde la API de RAWG.io
class Game {
  final int id;
  final String name;
  final String? backgroundImage;
  final double? rating;
  final String? released;
  final List<String>? platforms;

  Game({
    required this.id,
    required this.name,
    this.backgroundImage,
    this.rating,
    this.released,
    this.platforms,
  });

  /// 🧪 Crea una instancia de `Game` a partir del JSON que devuelve la API
  factory Game.fromJson(Map<String, dynamic> json) {
    // ✅ Me aseguro de que los campos obligatorios existan y sean válidos
    if (json['id'] == null || json['name'] == null) {
      throw ArgumentError('Game JSON must have id and name fields');
    }

    // 🛟 Intento parsear las plataformas con cuidado
    List<String>? platformsList;
    if (json['platforms'] != null && json['platforms'] is List) {
      try {
        platformsList = (json['platforms'] as List)
            .where((p) => p is Map && p['platform'] != null && p['platform']['name'] != null)
            .map((p) => p['platform']['name'] as String)
            .toList();
        if (platformsList.isEmpty) {
          platformsList = null;
        }
      } catch (e) {
        platformsList = null;
      }
    }

    return Game(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? 'Unknown Game',
      backgroundImage: json['background_image'] as String?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      released: json['released'] as String?,
      platforms: platformsList,
    );
  }

  /// 🔁 Convierte el `Game` a JSON para guardarlo con facilidad
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'background_image': backgroundImage,
      'rating': rating,
      'released': released,
      'platforms': platforms,
    };
  }
}

