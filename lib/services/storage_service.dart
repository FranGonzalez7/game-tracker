import 'package:hive_flutter/hive_flutter.dart';
import '../models/saved_game.dart';

/// 💾 Servicio para almacenamiento local usando Hive
/// 📦 Maneja guardar, cargar y administrar juegos guardados (todavía repaso Hive)
class StorageService {
  static const String _boxName = 'savedGames';

  /// 🚀 Inicializa Hive y abre la caja de juegos guardados
  Future<void> init() async {
    await Hive.initFlutter();
    
    // 🧩 Registro los adapters si aún no están listos
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SavedGameAdapter());
    }
    
    await Hive.openBox<SavedGame>(_boxName);
  }

  /// 📚 Obtiene todos los juegos guardados
  List<SavedGame> getAllGames() {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        print('Box $_boxName is not open!');
        return [];
      }
      final box = Hive.box<SavedGame>(_boxName);
      final games = box.values.toList();
      print('getAllGames: Found ${games.length} games in box');
      return games;
    } catch (e) {
      print('Error in getAllGames: $e');
      return [];
    }
  }

  /// 💾 Guarda un juego en el almacenamiento local
  Future<void> saveGame(SavedGame game) async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        print('Box $_boxName is not open, opening...');
        await Hive.openBox<SavedGame>(_boxName);
      }
      final box = Hive.box<SavedGame>(_boxName);
      await box.put(game.id, game);
      print('Successfully saved game: ${game.name} (ID: ${game.id})');
      
      // 🔍 Verifico que realmente quedó guardado
      final saved = box.get(game.id);
      if (saved != null) {
        print('Verified: Game ${saved.name} is in storage');
      } else {
        print('WARNING: Game was not found in storage after saving!');
      }
    } catch (e) {
      print('Error saving game: $e');
      rethrow;
    }
  }

  /// ✏️ Actualiza un juego que ya estaba guardado
  Future<void> updateGame(SavedGame game) async {
    await saveGame(game);
  }

  /// 🗑️ Elimina un juego del almacenamiento local
  Future<void> deleteGame(int gameId) async {
    final box = Hive.box<SavedGame>(_boxName);
    await box.delete(gameId);
  }

  /// ❓ Revisa si un juego ya está guardado
  bool isGameSaved(int gameId) {
    final box = Hive.box<SavedGame>(_boxName);
    return box.containsKey(gameId);
  }

  /// 🎯 Obtiene un juego específico por ID
  SavedGame? getGame(int gameId) {
    final box = Hive.box<SavedGame>(_boxName);
    return box.get(gameId);
  }
}

