import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game.dart';
import '../services/game_service.dart';

/// Provider for the GameService
final gameServiceProvider = Provider<GameService>((ref) {
  return GameService();
});

/// Provider for game search results
final gameSearchProvider = StateNotifierProvider<GameSearchNotifier, AsyncValue<List<Game>>>((ref) {
  return GameSearchNotifier(ref.watch(gameServiceProvider));
});

/// StateNotifier for managing game search state
class GameSearchNotifier extends StateNotifier<AsyncValue<List<Game>>> {
  final GameService _gameService;

  GameSearchNotifier(this._gameService) : super(const AsyncValue.data([]));

  /// Searches for games by query
  Future<void> searchGames(String query) async {
    // Trim and check if query is effectively empty
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    
    try {
      final games = await _gameService.searchGames(trimmedQuery);
      state = AsyncValue.data(games);
    } catch (e, stackTrace) {
      // Log error for debugging
      print('GameSearchNotifier error: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Clears the search results
  void clearSearch() {
    state = const AsyncValue.data([]);
  }
}

