import 'package:hive/hive.dart';
import 'game.dart';

part 'saved_game.g.dart';

/// 💾 Modelo que representa un juego guardado con datos personales
/// 📝 Extiende el modelo `Game` con información para el seguimiento propio
@HiveType(typeId: 0)
class SavedGame {
  @HiveField(0)
  final int id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String? backgroundImage;
  
  @HiveField(3)
  final double? rating;
  
  @HiveField(4)
  final String? released;
  
  @HiveField(5)
  final List<String>? platforms;
  
  @HiveField(6)
  final DateTime? startDate;
  
  @HiveField(7)
  final DateTime? completionDate;
  
  @HiveField(8)
  final double? personalRating;
  
  @HiveField(9)
  final String? notes;

  SavedGame({
    required this.id,
    required this.name,
    this.backgroundImage,
    this.rating,
    this.released,
    this.platforms,
    this.startDate,
    this.completionDate,
    this.personalRating,
    this.notes,
  });

  /// 🧪 Crea un `SavedGame` a partir de un `Game`
  factory SavedGame.fromGame(Game game) {
    return SavedGame(
      id: game.id,
      name: game.name,
      backgroundImage: game.backgroundImage,
      rating: game.rating,
      released: game.released,
      platforms: game.platforms,
    );
  }

  /// ✏️ Crea una copia con los campos actualizados
  SavedGame copyWith({
    int? id,
    String? name,
    String? backgroundImage,
    double? rating,
    String? released,
    List<String>? platforms,
    DateTime? startDate,
    DateTime? completionDate,
    double? personalRating,
    String? notes,
  }) {
    return SavedGame(
      id: id ?? this.id,
      name: name ?? this.name,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      rating: rating ?? this.rating,
      released: released ?? this.released,
      platforms: platforms ?? this.platforms,
      startDate: startDate ?? this.startDate,
      completionDate: completionDate ?? this.completionDate,
      personalRating: personalRating ?? this.personalRating,
      notes: notes ?? this.notes,
    );
  }
}

