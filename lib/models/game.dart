/// Model class representing a game from the RAWG.io API
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

  /// Creates a Game instance from JSON data
  factory Game.fromJson(Map<String, dynamic> json) {
    // Ensure required fields are present and valid
    if (json['id'] == null || json['name'] == null) {
      throw ArgumentError('Game JSON must have id and name fields');
    }

    // Safely parse platforms
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

  /// Converts Game to JSON for storage
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

