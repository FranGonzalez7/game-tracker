/// 🎮 Modelo que representa un juego obtenido desde nuestro backend proxy de IGDB
class Game {
  final int id;
  final String name;
  final String? backgroundImage;
  final double? rating;
  final String? released;
  final List<String>? platforms;
  final List<String>? genres;
  final String? summary;

  Game({
    required this.id,
    required this.name,
    this.backgroundImage,
    this.rating,
    this.released,
    this.platforms,
    this.genres,
    this.summary,
  });

  /// 🧪 Crea una instancia de `Game` a partir del JSON que devuelve el backend
  factory Game.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null || json['name'] == null) {
      throw ArgumentError('Game JSON must have id and name fields');
    }

    String? coverUrl;
    if (json['background_image'] != null) {
      coverUrl = json['background_image'] as String?;
    } else if (json['cover_url'] != null) {
      coverUrl = json['cover_url'] as String?;
    } else if (json['coverUrl'] != null) {
      coverUrl = json['coverUrl'] as String?;
    } else if (json['cover'] is Map && (json['cover'] as Map)['url'] != null) {
      coverUrl = (json['cover'] as Map)['url'] as String?;
    }

    double? ratingValue;
    if (json['rating'] != null) {
      ratingValue = (json['rating'] as num).toDouble();
    } else if (json['total_rating'] != null) {
      ratingValue = (json['total_rating'] as num).toDouble();
    }

    String? releasedDate;
    final releasedRaw = json['released'] ?? json['release_date'] ?? json['first_release_date'];
    if (releasedRaw is String) {
      releasedDate = releasedRaw;
    } else if (releasedRaw is int) {
      // IGDB envía timestamps en segundos; los convierto a yyyy-MM-dd
      final date = DateTime.fromMillisecondsSinceEpoch(releasedRaw * 1000, isUtc: true);
      releasedDate = date.toIso8601String().split('T').first;
    }

    List<String>? platformsList;
    final platformsRaw = json['platforms'];
    if (platformsRaw is List) {
      platformsList = platformsRaw
          .map((platform) {
            if (platform is String) return platform;
            if (platform is Map && platform['name'] is String) return platform['name'] as String;
            return null;
          })
          .whereType<String>()
          .toList();
      if (platformsList.isEmpty) platformsList = null;
    }

    List<String>? genresList;
    final genresRaw = json['genres'];
    if (genresRaw is List) {
      genresList = genresRaw
          .map((genre) {
            if (genre is String) return genre;
            if (genre is Map && genre['name'] is String) return genre['name'] as String;
            return null;
          })
          .whereType<String>()
          .toList();
      if (genresList.isEmpty) genresList = null;
    }

    return Game(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? 'Unknown Game',
      backgroundImage: coverUrl,
      rating: ratingValue,
      released: releasedDate,
      platforms: platformsList,
      genres: genresList,
      summary: json['summary'] as String?,
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
      'genres': genres,
      'summary': summary,
    };
  }
}

