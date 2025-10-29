import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saved_game.dart';
import '../models/game.dart';
import '../services/storage_service.dart';

/// Provider for the StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Provider for saved games list
final savedGamesProvider = StateNotifierProvider<SavedGamesNotifier, List<SavedGame>>((ref) {
  return SavedGamesNotifier(ref.watch(storageServiceProvider));
});

/// StateNotifier for managing saved games state
class SavedGamesNotifier extends StateNotifier<List<SavedGame>> {
  final StorageService _storageService;

  SavedGamesNotifier(this._storageService) : super([]) {
    // Load games asynchronously to ensure storage is ready
    _initialize();
  }

  /// Initialize and load games
  Future<void> _initialize() async {
    try {
      // Small delay to ensure Hive is fully initialized
      await Future.delayed(const Duration(milliseconds: 100));
      _loadGames();
    } catch (e) {
      print('Error initializing SavedGamesNotifier: $e');
      state = [];
    }
  }

  /// Loads all saved games from storage
  void _loadGames() {
    try {
      final games = _storageService.getAllGames();
      state = List.from(games); // Create a new list to trigger update
      print('Loaded ${games.length} games from storage');
    } catch (e) {
      print('Error loading games: $e');
      state = [];
    }
  }

  /// Adds a new game to the saved list
  Future<void> addGame(Game game) async {
    try {
      if (_storageService.isGameSaved(game.id)) {
        print('Game ${game.id} already saved');
        return; // Game already saved
      }
      
      print('Converting Game to SavedGame: ${game.name}');
      final savedGame = SavedGame.fromGame(game);
      print('Saving game: ${savedGame.name} (ID: ${savedGame.id})');
      
      await _storageService.saveGame(savedGame);
      print('Game saved to storage, reloading...');
      
      // Force a reload by creating a new list
      final currentGames = _storageService.getAllGames();
      state = List.from(currentGames);
      print('Games reloaded. Total: ${state.length}');
    } catch (e, stackTrace) {
      print('Error adding game: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Updates an existing saved game
  Future<void> updateGame(SavedGame game) async {
    await _storageService.updateGame(game);
    _loadGames();
  }

  /// Deletes a game from the saved list
  Future<void> deleteGame(int gameId) async {
    await _storageService.deleteGame(gameId);
    _loadGames();
  }

  /// Checks if a game is already saved
  bool isGameSaved(int gameId) {
    return _storageService.isGameSaved(gameId);
  }
}

