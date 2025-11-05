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
  final List<String>? platforms;

  const SearchFilters({
    this.year,
    this.platforms,
  });

  SearchFilters copyWith({
    int? year,
    List<String>? platforms,
    bool clearPlatforms = false,
  }) {
    return SearchFilters(
      year: year ?? this.year,
      platforms: clearPlatforms ? null : (platforms ?? this.platforms),
    );
  }

  bool get isEmpty => year == null && (platforms == null || platforms!.isEmpty);
}

/// Provider for search filters
final searchFiltersProvider = StateProvider<SearchFilters>((ref) {
  return const SearchFilters();
});

/// Provider for platforms list from API
final platformsProvider = FutureProvider<List<String>>((ref) async {
  final gameService = ref.watch(gameServiceProvider);
  return await gameService.getPlatforms();
});

/// Provider for platforms available in current search results
final availablePlatformsProvider = Provider<List<String>>((ref) {
  final searchResults = ref.watch(unfilteredGameSearchProvider);
  
  return searchResults.when(
    data: (games) {
      final platformsSet = <String>{};
      for (final game in games) {
        if (game.platforms != null) {
          platformsSet.addAll(game.platforms!);
        }
      }
      return platformsSet.toList()..sort();
    },
    loading: () => [],
    error: (_, __) => [],
  );
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
      // Filtrar resultados para que sean más relevantes
      final filteredGames = _filterRelevantResults(games, trimmedQuery);
      state = AsyncValue.data(filteredGames);
    } catch (e, stackTrace) {
      print('GameSearchNotifier error: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Filtra los resultados para incluir solo juegos relevantes
  /// Elimina resultados que no tienen una coincidencia significativa con el término de búsqueda
  List<Game> _filterRelevantResults(List<Game> games, String searchQuery) {
    if (games.isEmpty) return games;
    
    final normalizedQuery = searchQuery.toLowerCase().trim();
    final queryWords = normalizedQuery.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    
    // Si la consulta es muy corta (menos de 3 caracteres), no filtrar tanto
    if (normalizedQuery.length < 3) {
      return games;
    }
    
    return games.where((game) {
      final gameName = game.name.toLowerCase();
      
      // Verificar si el término completo está contenido en el nombre (coincidencia exacta)
      if (gameName.contains(normalizedQuery)) {
        return true;
      }
      
      // Verificar si todas las palabras de la búsqueda están en el nombre
      if (queryWords.length > 1) {
        final allWordsMatch = queryWords.every((word) => gameName.contains(word));
        if (allWordsMatch) {
          return true;
        }
      }
      
      // Para búsquedas de una sola palabra, verificar similitud estricta
      // Solo aceptar si hay una coincidencia muy cercana (más del 85% de similitud)
      if (queryWords.length == 1 && normalizedQuery.length >= 4) {
        return _hasHighSimilarity(normalizedQuery, gameName);
      }
      
      return false;
    }).toList();
  }

  /// Verifica si hay una similitud alta entre el query y el nombre del juego
  /// Requiere al menos 85% de similitud para aceptar el resultado
  /// Esto evita casos como "pimon" para "pikmin"
  bool _hasHighSimilarity(String query, String gameName) {
    // Dividir el nombre del juego en palabras
    final gameWords = gameName.split(RegExp(r'[^a-z0-9]+')).where((w) => w.isNotEmpty).toList();
    
    // Verificar si alguna palabra del juego tiene alta similitud con el query
    for (final word in gameWords) {
      if (word.length < query.length * 0.7) continue; // Palabra demasiado corta
      
      // Calcular similitud usando distancia de Levenshtein simplificada
      final similarity = _calculateSimilarity(query, word);
      if (similarity >= 0.85) {
        return true;
      }
    }
    
    return false;
  }

  /// Calcula la similitud entre dos strings usando un algoritmo simplificado
  /// Retorna un valor entre 0.0 y 1.0, donde 1.0 es idéntico
  double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    
    // Si uno contiene al otro completamente, alta similitud
    if (s1.contains(s2) || s2.contains(s1)) {
      final shorter = s1.length < s2.length ? s1 : s2;
      final longer = s1.length < s2.length ? s2 : s1;
      return shorter.length / longer.length;
    }
    
    // Calcular caracteres comunes en orden
    int commonChars = 0;
    int s1Index = 0;
    int s2Index = 0;
    
    while (s1Index < s1.length && s2Index < s2.length) {
      if (s1[s1Index] == s2[s2Index]) {
        commonChars++;
        s1Index++;
        s2Index++;
      } else {
        // Avanzar en ambas cadenas para encontrar la siguiente coincidencia
        s2Index++;
      }
    }
    
    // Calcular similitud basada en caracteres comunes y longitud
    final maxLength = s1.length > s2.length ? s1.length : s2.length;
    final similarity = (commonChars * 2.0) / (s1.length + s2.length);
    
    // Penalizar si las longitudes son muy diferentes
    final lengthDiff = (s1.length - s2.length).abs() / maxLength;
    return similarity * (1.0 - lengthDiff * 0.3);
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

      // Filter by platforms
      if (filters.platforms != null && filters.platforms!.isNotEmpty) {
        filtered = filtered.where((game) {
          if (game.platforms == null || game.platforms!.isEmpty) return false;
          return game.platforms!.any((gamePlatform) => 
            filters.platforms!.any((selectedPlatform) =>
              gamePlatform.toLowerCase() == selectedPlatform.toLowerCase()
            )
          );
        }).toList();
      }

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

