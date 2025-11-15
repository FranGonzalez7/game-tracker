import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game.dart';
import '../services/igdb_service.dart';

/// 🕹️ Provider del `IgdbService` (así lo puedo pedir desde cualquier parte)
final gameServiceProvider = Provider<IgdbService>((ref) {
  return IgdbService();
});

/// 🧪 Modelo sencillito para guardar los filtros de búsqueda
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

/// 🎛️ Provider donde guardo los filtros que el usuario va tocando
final searchFiltersProvider = StateProvider<SearchFilters>((ref) {
  return const SearchFilters();
});

/// 🪜 Provider que trae la lista de plataformas desde la API (tarda un poquito)
/// 📝 Por ahora devuelve una lista vacía ya que las plataformas se extraen de los resultados de búsqueda
final platformsProvider = FutureProvider<List<String>>((ref) async {
  // Las plataformas se obtienen dinámicamente de los resultados de búsqueda
  // usando el availablePlatformsProvider
  return [];
});

/// 🧮 Provider que calcula las plataformas disponibles en los resultados actuales
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

/// 🔍 Provider con los resultados sin filtrar (tal como vienen de la API)
final unfilteredGameSearchProvider = StateNotifierProvider<UnfilteredGameSearchNotifier, AsyncValue<List<Game>>>((ref) {
  return UnfilteredGameSearchNotifier(ref.watch(gameServiceProvider));
});

/// 🧠 `StateNotifier` para manejar el estado de la búsqueda sin filtros
class UnfilteredGameSearchNotifier extends StateNotifier<AsyncValue<List<Game>>> {
  final IgdbService _gameService;

  UnfilteredGameSearchNotifier(this._gameService) : super(const AsyncValue.data([]));

  /// 🔎 Busca juegos según el texto que escribe la persona
  Future<void> searchGames(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    
    try {
      final games = await _gameService.searchGames(trimmedQuery);
      // ✂️ Luego filtro para quedarme con lo que se siente más relevante
      final filteredGames = _filterRelevantResults(games, trimmedQuery);
      state = AsyncValue.data(filteredGames);
    } catch (e, stackTrace) {
      print('GameSearchNotifier error: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 🧹 Filtra los resultados para quedarme solo con los juegos relevantes
  /// 🚫 Evita que entren coincidencias raras que no tienen mucho que ver con la búsqueda
  List<Game> _filterRelevantResults(List<Game> games, String searchQuery) {
    if (games.isEmpty) return games;
    
    final normalizedQuery = searchQuery.toLowerCase().trim();
    final queryWords = normalizedQuery.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    
    // 🤏 Si la consulta es muy cortita (menos de 3 letras), prefiero no filtrar tanto
    if (normalizedQuery.length < 3) {
      return games;
    }
    
    return games.where((game) {
      final gameName = game.name.toLowerCase();
      
      // ✅ Si el término completo está en el nombre, lo acepto sin pensarlo
      if (gameName.contains(normalizedQuery)) {
        return true;
      }
      
      // 🧩 Si tiene varias palabras, reviso que todas aparezcan por algún lado
      if (queryWords.length > 1) {
        final allWordsMatch = queryWords.every((word) => gameName.contains(word));
        if (allWordsMatch) {
          return true;
        }
      }
      
      // 🧐 Para palabras sueltas reviso la similitud más estricta
      // 🟢 Solo acepto si se parece al menos un 85% (para no meter la pata)
      if (queryWords.length == 1 && normalizedQuery.length >= 4) {
        return _hasHighSimilarity(normalizedQuery, gameName);
      }
      
      return false;
    }).toList();
  }

  /// 🧠 Verifica si hay mucha similitud entre la búsqueda y el nombre del juego
  /// 📏 Necesito mínimo 85% para decir que sí coincide
  /// 🚫 Así evito confundir "pimon" con "pikmin" (me pasó más de una vez)
  bool _hasHighSimilarity(String query, String gameName) {
    // ✂️ Divido el nombre del juego en palabras más pequeñitas
    final gameWords = gameName.split(RegExp(r'[^a-z0-9]+')).where((w) => w.isNotEmpty).toList();
    
    // 🔎 Reviso si alguna palabra del juego se parece un montón al texto buscado
    for (final word in gameWords) {
      if (word.length < query.length * 0.7) continue; // 🙅‍♂️ Palabra demasiado corta, la salto
      
      // 🧮 Calculo una similitud con una distancia de Levenshtein simplificada
      final similarity = _calculateSimilarity(query, word);
      if (similarity >= 0.85) {
        return true;
      }
    }
    
    return false;
  }

  /// 📐 Calcula qué tan parecidos son dos textos con un algoritmo simplificado
  /// 🔢 Devuelve un número entre 0.0 y 1.0 (1.0 significa idéntico)
  double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    
    // 🤝 Si uno contiene al otro completo, ya digo que son muy parecidos
    if (s1.contains(s2) || s2.contains(s1)) {
      final shorter = s1.length < s2.length ? s1 : s2;
      final longer = s1.length < s2.length ? s2 : s1;
      return shorter.length / longer.length;
    }
    
    // 🔤 Recorro letra por letra para ver cuántas coinciden en orden
    int commonChars = 0;
    int s1Index = 0;
    int s2Index = 0;
    
    while (s1Index < s1.length && s2Index < s2.length) {
      if (s1[s1Index] == s2[s2Index]) {
        commonChars++;
        s1Index++;
        s2Index++;
      } else {
        // ⏩ Avanzo en las cadenas hasta encontrar la próxima coincidencia
        s2Index++;
      }
    }
    
    // 📊 Con eso calculo la similitud usando las letras comunes y sus longitudes
    final maxLength = s1.length > s2.length ? s1.length : s2.length;
    final similarity = (commonChars * 2.0) / (s1.length + s2.length);
    
    // ⚖️ Si una palabra es mucho más larga que la otra, le bajo un poquito la nota
    final lengthDiff = (s1.length - s2.length).abs() / maxLength;
    return similarity * (1.0 - lengthDiff * 0.3);
  }

  /// 🧼 Limpia los resultados de búsqueda (vuelvo a la lista vacía)
  void clearSearch() {
    state = const AsyncValue.data([]);
  }
}

/// 🔎 Provider que combina los resultados con los filtros aplicados
final gameSearchProvider = Provider<AsyncValue<List<Game>>>((ref) {
  final unfilteredResults = ref.watch(unfilteredGameSearchProvider);
  final filters = ref.watch(searchFiltersProvider);

  return unfilteredResults.when(
    data: (games) {
      if (filters.isEmpty) {
        return AsyncValue.data(games);
      }

      var filtered = games;

      // 📅 Filtro por año cuando la persona selecciona uno
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

      // 🎮 Filtro por plataformas específicas si eligieron alguna
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

/// 🆕 Provider que obtiene los últimos lanzamientos (últimos 6 meses) para mostrar como sugerencias
final latestReleasesProvider = FutureProvider<List<Game>>((ref) async {
  final gameService = ref.watch(gameServiceProvider);
  return await gameService.getLatestReleases();
});

