import 'package:hive_flutter/hive_flutter.dart';
import '../models/saved_game.dart';

/// Service class for local storage using Hive
/// Handles saving, loading, and managing saved games
class StorageService {
  static const String _boxName = 'savedGames';

  /// Initializes Hive and opens the saved games box
  Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SavedGameAdapter());
    }
    
    await Hive.openBox<SavedGame>(_boxName);
  }

  /// Gets all saved games
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

  /// Saves a game to local storage
  Future<void> saveGame(SavedGame game) async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        print('Box $_boxName is not open, opening...');
        await Hive.openBox<SavedGame>(_boxName);
      }
      final box = Hive.box<SavedGame>(_boxName);
      await box.put(game.id, game);
      print('Successfully saved game: ${game.name} (ID: ${game.id})');
      
      // Verify it was saved
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

  /// Updates an existing saved game
  Future<void> updateGame(SavedGame game) async {
    await saveGame(game);
  }

  /// Deletes a game from local storage
  Future<void> deleteGame(int gameId) async {
    final box = Hive.box<SavedGame>(_boxName);
    await box.delete(gameId);
  }

  /// Checks if a game is already saved
  bool isGameSaved(int gameId) {
    final box = Hive.box<SavedGame>(_boxName);
    return box.containsKey(gameId);
  }

  /// Gets a specific saved game by ID
  SavedGame? getGame(int gameId) {
    final box = Hive.box<SavedGame>(_boxName);
    return box.get(gameId);
  }
}

