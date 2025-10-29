import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../providers/saved_games_provider.dart';
import '../widgets/game_search_card.dart';

/// Tab screen for searching games from the RAWG API
/// Displays a search bar and list of search results
class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {}); // Rebuild to update suffix icon
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query != _lastQuery) {
      _lastQuery = query;
      ref.read(unfilteredGameSearchProvider.notifier).searchGames(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(gameSearchProvider);
    final savedGames = ref.watch(savedGamesProvider);

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for games...',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.primary,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _lastQuery = '';
                        ref.read(unfilteredGameSearchProvider.notifier).clearSearch();
                        ref.read(searchFiltersProvider.notifier).state = const SearchFilters();
                      },
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    )
                  : null,
            ),
            onChanged: _performSearch,
          ),
        ),

        // Filters
        _buildFilters(context),

        // Search Results
        Expanded(
          child: searchResults.when(
            data: (games) {
              if (games.isEmpty && _searchController.text.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Start searching for games',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ) ?? TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                );
              }

              if (games.isEmpty) {
                return Center(
                  child: Text(
                    'No games found',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ) ?? TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: games.length,
                itemBuilder: (context, index) {
                  final game = games[index];
                  final isSaved = savedGames.any((g) => g.id == game.id);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GameSearchCard(
                      game: game,
                      isSaved: isSaved,
                      onAdd: () async {
                        try {
                          await ref.read(savedGamesProvider.notifier).addGame(game);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${game.name} added to My Games'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error adding game: $e'),
                                duration: const Duration(seconds: 3),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading games',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ) ?? TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ) ?? TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        if (_searchController.text.isNotEmpty) {
                          _performSearch(_searchController.text);
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    final filters = ref.watch(searchFiltersProvider);
    final unfilteredResults = ref.watch(unfilteredGameSearchProvider);

    // Don't show filters section if there are no search results or still loading
    return unfilteredResults.when(
      data: (games) {
        if (games.isEmpty) {
          return const SizedBox.shrink();
        }

        // Get unique years and platforms from search results
        final availableYears = <int>{};
        final availablePlatforms = <String>{};

        for (var game in games) {
          if (game.released != null) {
            try {
              final year = int.parse(game.released!.split('-')[0]);
              availableYears.add(year);
            } catch (e) {
              // Skip invalid dates
            }
          }
          if (game.platforms != null) {
            availablePlatforms.addAll(game.platforms!);
          }
        }

        final sortedYears = availableYears.toList()..sort((a, b) => b.compareTo(a));

        // Popular platforms
        const popularPlatforms = [
          'PlayStation 5',
          'PlayStation 4',
          'Xbox Series X/S',
          'Xbox One',
          'Nintendo Switch',
          'PC',
          'iOS',
          'Android',
        ];

        // Get platforms that exist in results, prioritizing popular ones
        final sortedPlatforms = [
          ...popularPlatforms.where((p) => availablePlatforms.contains(p)),
          ...availablePlatforms.where((p) => !popularPlatforms.contains(p)).toList()..sort(),
        ];

        return _buildFiltersContent(context, filters, sortedYears, sortedPlatforms);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildFiltersContent(
    BuildContext context,
    SearchFilters filters,
    List<int> sortedYears,
    List<String> sortedPlatforms,
  ) {

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Filtros',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
              const Spacer(),
              if (!filters.isEmpty)
                TextButton.icon(
                  onPressed: () {
                    ref.read(searchFiltersProvider.notifier).state = const SearchFilters();
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Limpiar'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          if (sortedYears.isNotEmpty || sortedPlatforms.isNotEmpty) ...[
            const SizedBox(height: 12),
            
            // Year Filter
            if (sortedYears.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Text(
                    'Año:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  ...sortedYears.take(10).map((year) {
                    final isSelected = filters.year == year;
                    return FilterChip(
                      label: Text(year.toString()),
                      selected: isSelected,
                      onSelected: (selected) {
                        ref.read(searchFiltersProvider.notifier).state = filters.copyWith(
                          year: selected ? year : null,
                        );
                      },
                      avatar: isSelected
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: Theme.of(context).colorScheme.onPrimary,
                            )
                          : null,
                    );
                  }),
                ],
              ),
              if (sortedPlatforms.isNotEmpty) const SizedBox(height: 12),
            ],

            // Platform Filter
            if (sortedPlatforms.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Text(
                    'Plataforma:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  ...sortedPlatforms.take(10).map((platform) {
                    final isSelected = filters.platform == platform;
                    return FilterChip(
                      label: Text(platform),
                      selected: isSelected,
                      onSelected: (selected) {
                        ref.read(searchFiltersProvider.notifier).state = filters.copyWith(
                          platform: selected ? platform : null,
                        );
                      },
                      avatar: isSelected
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: Theme.of(context).colorScheme.onPrimary,
                            )
                          : null,
                    );
                  }),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

