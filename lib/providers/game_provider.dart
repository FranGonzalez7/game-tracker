import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game.dart';
import '../services/game_service.dart';

/// Provider for the GameService
final gameServiceProvider = Provider<GameService>((ref) {
  return GameService();
});

/// Model for search filters
class SearchFilters {
  final int? year;
  final String? platform;

  const SearchFilters({
    this.year,
    this.platform,
  });

  SearchFilters copyWith({
    int? year,
    String? platform,
  }) {
    return SearchFilters(
      year: year ?? this.year,
      platform: platform ?? this.platform,
    );
  }

  bool get isEmpty => year == null && platform == null;
}

/// Provider for search filters
final searchFiltersProvider = StateProvider<SearchFilters>((ref) {
  return const SearchFilters();
});

/// Provider for unfiltered game search results
final unfilteredGameSearchProvider = StateNotifierProvider<UnfilteredGameSearchNotifier, AsyncValue<List<Game>>>((ref) {
  return UnfilteredGameSearchNotifier(ref.watch(gameServiceProvider));
});

/// StateNotifier for managing unfiltered game search state
class UnfilteredGameSearchNotifier extends StateNotifier<AsyncValue<List<Game>>> {
  final GameService _gameService;

  UnfilteredGameSearchNotifier(this._gameService) : super(const AsyncValue.data([]));

  /// Searches for games by query
  Future<void> searchGames(String query) async {
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
      print('GameSearchNotifier error: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Clears the search results
  void clearSearch() {
    state = const AsyncValue.data([]);
  }
}

/// Provider for filtered game search results
final gameSearchProvider = Provider<AsyncValue<List<Game>>>((ref) {
  final unfilteredResults = ref.watch(unfilteredGameSearchProvider);
  final filters = ref.watch(searchFiltersProvider);

  return unfilteredResults.when(
    data: (games) {
      if (filters.isEmpty) {
        return AsyncValue.data(games);
      }

      var filtered = games;

      // Filter by year
      if (filters.year != null) {
        filtered = filtered.where((game) {
          if (game.released == null) return false;
          try {
            final releaseYear = int.parse(game.released!.split('-')[0]);
            return releaseYear == filters.year;
          } catch (e) {
            return false;
          }
        }).toList();
      }

      // Filter by platform
      if (filters.platform != null) {
        filtered = filtered.where((game) {
          if (game.platforms == null || game.platforms!.isEmpty) return false;
          return game.platforms!.any((p) => 
            p.toLowerCase().contains(filters.platform!.toLowerCase())
          );
        }).toList();
      }

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

