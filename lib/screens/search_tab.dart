import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../widgets/game_search_card.dart';
import '../widgets/game_detail_modal.dart';

/// 🧭 Pestaña para buscar juegos usando la API de RAWG (todavía aprendo a paginar)
/// 🔍 Muestra una barra de búsqueda y la lista de resultados que voy encontrando
class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {}); // 🔁 Reconstruyo para refrescar el icono de limpiar
    });
    
    // ⌨️ Cierro el teclado si quedó abierto tras un hot restart (me pasa seguido)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNode.hasFocus) {
        _focusNode.unfocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query != _lastQuery) {
      _lastQuery = query;
      // 🧼 Limpio los filtros cada vez que cambia la búsqueda para evitar mezclas raras
      ref.read(searchFiltersProvider.notifier).state = const SearchFilters();
      ref.read(unfilteredGameSearchProvider.notifier).searchGames(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(gameSearchProvider);

    return Column(
      children: [
        // 🔍 Barra de búsqueda principal
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 16.0),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
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
            textInputAction: TextInputAction.search,
            onChanged: _performSearch,
            onSubmitted: (q) {
              _performSearch(q);
              _focusNode.unfocus();
            },
          ),
        ),

        // 🎛️ Barra de filtros (aún está sencilla, pero voy mejorándola)
        Container(
          height: 40,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(
                  Icons.tune,
                  size: 20,
                  color: const Color(0xFF137FEC),
                ),
                const SizedBox(width: 12),
                _FilterChip(
                  label: 'Plataforma',
                  onTap: () {
                    final searchResults = ref.read(unfilteredGameSearchProvider);
                    searchResults.whenData((games) {
                      if (games.isNotEmpty) {
                        _PlatformFilterModal.show(context, ref);
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Fecha',
                  onTap: () {
                    // TODO ✍️: implementar filtro de fecha (todavía no sé cómo paginar por meses)
                  },
                ),
              ],
            ),
          ),
        ),

        // 📄 Área donde muestro los resultados de la búsqueda
        Expanded(
          child: GestureDetector(
            onTap: () => _focusNode.unfocus(),
            behavior: HitTestBehavior.translucent,
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

              // 📐 Calculo cuántas columnas caben según el ancho (mínimo 2, máximo 3)
              final screenWidth = MediaQuery.of(context).size.width;
              final crossAxisCount = screenWidth > 600 ? 3 : 2;

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.7, // Ajusta la proporción según necesites
                ),
                itemCount: games.length,
                itemBuilder: (context, index) {
                  final game = games[index];
                  
                  return GameSearchCard(
                    game: game,
                    onTap: () async {
                      _focusNode.unfocus();
                      await GameDetailModal.show(
                        context,
                        game,
                        allGames: games,
                        initialIndex: index,
                      );
                    },
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
        ),
      ],
    );
  }
}

/// Widget para los chips de filtrado
class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF137FEC),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF137FEC),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal para filtrar por plataformas
class _PlatformFilterModal extends ConsumerStatefulWidget {
  const _PlatformFilterModal();

  static void show(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _PlatformFilterModal(),
    );
  }

  @override
  ConsumerState<_PlatformFilterModal> createState() => _PlatformFilterModalState();
}

class _PlatformFilterModalState extends ConsumerState<_PlatformFilterModal> {
  late Set<String> _selectedPlatforms;

  @override
  void initState() {
    super.initState();
    final currentFilters = ref.read(searchFiltersProvider);
    _selectedPlatforms = currentFilters.platforms?.toSet() ?? {};
  }

  void _togglePlatform(String platform) {
    setState(() {
      if (_selectedPlatforms.contains(platform)) {
        _selectedPlatforms.remove(platform);
      } else {
        _selectedPlatforms.add(platform);
      }
    });
  }

  void _applyFilters() {
    // 💾 Actualizo el provider con las plataformas que quedaron marcadas
    final currentFilters = ref.read(searchFiltersProvider);
    ref.read(searchFiltersProvider.notifier).state = currentFilters.copyWith(
      platforms: _selectedPlatforms.isEmpty ? null : _selectedPlatforms.toList(),
      clearPlatforms: _selectedPlatforms.isEmpty,
    );
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _selectedPlatforms.clear();
    });
    // 🔄 También actualizo el provider para que se vea el cambio enseguida
    final currentFilters = ref.read(searchFiltersProvider);
    ref.read(searchFiltersProvider.notifier).state = currentFilters.copyWith(
      clearPlatforms: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final availablePlatforms = ref.watch(availablePlatformsProvider);
    final screenSize = MediaQuery.of(context).size;
    
    // 🧹 Limpio selecciones que ya no existen (solo la primera vez que se monta)
    if (_selectedPlatforms.isNotEmpty && availablePlatforms.isNotEmpty) {
      final toRemove = _selectedPlatforms.where((p) => !availablePlatforms.contains(p)).toList();
      if (toRemove.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedPlatforms.removeAll(toRemove);
            });
          }
        });
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: screenSize.width * 0.85,
        height: screenSize.height * 0.84, // 20% más grande (0.7 * 1.2 = 0.84)
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
      child: Column(
        children: [
          // 🎀 Encabezado del modal de filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.tune,
                  color: Color(0xFF137FEC),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Plataformas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_selectedPlatforms.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_all),
                    color: const Color(0xFF137FEC),
                    tooltip: 'Limpiar',
                    onPressed: _clearFilters,
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // 📋 Lista de plataformas disponibles
          Expanded(
            child: availablePlatforms.isEmpty
                ? const Center(
                    child: Text('No hay plataformas disponibles en los resultados'),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 4,
                      childAspectRatio: 2.8,
                    ),
                    itemCount: availablePlatforms.length,
                    itemBuilder: (context, index) {
                      final platform = availablePlatforms[index];
                      final isSelected = _selectedPlatforms.contains(platform);
                      
                      return Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) => _togglePlatform(platform),
                            activeColor: const Color(0xFF137FEC),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _togglePlatform(platform),
                              child: Text(
                                platform,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          // 🧭 Botones del pie (cancelar o aplicar)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF137FEC)),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Color(0xFF137FEC),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _applyFilters,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF137FEC),
                    ),
                    child: const Text(
                      'Aplicar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

