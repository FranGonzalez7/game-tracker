import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saved_game.dart';
import '../models/game.dart';
import '../services/storage_service.dart';

/// 💾 Provider que entrega el `StorageService`
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// 📚 Provider con la lista de juegos guardados
final savedGamesProvider = StateNotifierProvider<SavedGamesNotifier, List<SavedGame>>((ref) {
  return SavedGamesNotifier(ref.watch(storageServiceProvider));
});

/// 🧠 StateNotifier que maneja el estado de juegos guardados
class SavedGamesNotifier extends StateNotifier<List<SavedGame>> {
  final StorageService _storageService;

  SavedGamesNotifier(this._storageService) : super([]) {
    // ⏳ Cargo los juegos de forma asíncrona para asegurar que Hive esté listo
    _initialize();
  }

  /// 🚀 Inicializa y carga los juegos
  Future<void> _initialize() async {
    try {
      // 💤 Pequeño delay para asegurar que Hive terminó de inicializar
      await Future.delayed(const Duration(milliseconds: 100));
      _loadGames();
    } catch (e) {
      print('Error initializing SavedGamesNotifier: $e');
      state = [];
    }
  }

  /// 📥 Carga todos los juegos guardados desde el almacenamiento
  void _loadGames() {
    try {
      final games = _storageService.getAllGames();
      state = List.from(games); // 🔄 Creo una lista nueva para disparar la actualización
      print('Loaded ${games.length} games from storage');
    } catch (e) {
      print('Error loading games: $e');
      state = [];
    }
  }

  /// ➕ Añade un juego nuevo a la lista guardada
  Future<void> addGame(Game game) async {
    try {
      if (_storageService.isGameSaved(game.id)) {
        print('Game ${game.id} already saved');
        return; // ✅ El juego ya estaba guardado, no repito
      }
      
      print('Converting Game to SavedGame: ${game.name}');
      final savedGame = SavedGame.fromGame(game);
      print('Saving game: ${savedGame.name} (ID: ${savedGame.id})');
      
      await _storageService.saveGame(savedGame);
      print('Game saved to storage, reloading...');
      
      // 🔄 Fuerzo recarga creando una lista nueva
      final currentGames = _storageService.getAllGames();
      state = List.from(currentGames);
      print('Games reloaded. Total: ${state.length}');
    } catch (e, stackTrace) {
      print('Error adding game: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// ✏️ Actualiza un juego guardado existente
  Future<void> updateGame(SavedGame game) async {
    await _storageService.updateGame(game);
    _loadGames();
  }

  /// 🗑️ Borra un juego de la lista guardada
  Future<void> deleteGame(int gameId) async {
    await _storageService.deleteGame(gameId);
    _loadGames();
  }

  /// ❓ Revisa si un juego ya está guardado
  bool isGameSaved(int gameId) {
    return _storageService.isGameSaved(gameId);
  }
}

