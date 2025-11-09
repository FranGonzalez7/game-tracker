import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game.dart';
import '../providers/lists_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/game_detail_modal.dart';
import '../providers/wishlist_provider.dart';
import '../widgets/game_search_card.dart';

enum _ListMenuAction { clear }

/// 🗂️ Pantalla genérica para mostrar el contenido de cualquier lista
/// 📋 Reutiliza la misma experiencia que teníamos en la wishlist
class ListDetailScreen extends ConsumerWidget {
  final String listId;
  final String fallbackName;

  const ListDetailScreen({
    super.key,
    required this.listId,
    required this.fallbackName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(listGamesStreamProvider(listId));
    final viewSettings = ref.watch(listViewSettingsProvider);
    final listsAsync = ref.watch(userListsStreamProvider);

    final listInfo = listsAsync.maybeWhen(
      data: (lists) => lists.firstWhere(
        (list) => list['id'] == listId,
        orElse: () => <String, dynamic>{'name': fallbackName},
      ),
      orElse: () => <String, dynamic>{'name': fallbackName},
    );

    final listName = (listInfo['name'] as String?)?.isNotEmpty == true
        ? listInfo['name'] as String
        : fallbackName;

    void increaseCardSize() {
      if (viewSettings.gridColumns > 1) {
        ref.read(listViewSettingsProvider.notifier).setGridColumns(viewSettings.gridColumns - 1);
      }
    }

    void decreaseCardSize() {
      if (viewSettings.gridColumns < 5) {
        ref.read(listViewSettingsProvider.notifier).setGridColumns(viewSettings.gridColumns + 1);
      }
    }

    void toggleView() {
      ref.read(listViewSettingsProvider.notifier).setListView(!viewSettings.isListView);
    }

    IconData _emptyIcon() {
      if (listId == 'favorites') return Icons.favorite_border;
      if (listId == 'my_collection') return Icons.inventory_2_outlined;
      if (listId == 'wishlist') return Icons.bookmark_border;
      if (listId.startsWith('played_year_')) return Icons.calendar_month;
      return Icons.list_alt_outlined;
    }

    String _emptyTitle() {
      if (listId == 'wishlist') return 'Tu wishlist está vacía';
      if (listId == 'favorites') return 'Aún no tienes favoritos guardados';
      return 'Todavía no hay juegos en $listName';
    }

    String _emptySubtitle() {
      if (listId == 'wishlist') {
        return 'Añade juegos desde la búsqueda';
      }
      return 'Añade juegos desde la búsqueda o desde los detalles de un juego';
    }

    Widget _buildGames(List<Game> games) {
      if (games.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _emptyIcon(),
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                _emptyTitle(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ) ?? TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _emptySubtitle(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ) ?? TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!viewSettings.isListView)
                  Row(
                    children: [
                      IconButton(
                        onPressed: decreaseCardSize,
                        icon: const Icon(Icons.remove),
                        iconSize: 20,
                        tooltip: 'Reducir tamaño',
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                          minimumSize: const Size(36, 36),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      IconButton(
                        onPressed: increaseCardSize,
                        icon: const Icon(Icons.add),
                        iconSize: 20,
                        tooltip: 'Aumentar tamaño',
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                          minimumSize: const Size(36, 36),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox.shrink(),
                IconButton(
                  onPressed: toggleView,
                  icon: Icon(viewSettings.isListView ? Icons.grid_view : Icons.list),
                  iconSize: 20,
                  tooltip: viewSettings.isListView ? 'Vista de cuadrícula' : 'Vista de lista',
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                    minimumSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.90, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              child: viewSettings.isListView
                  ? ListView.builder(
                      key: ValueKey('list_view_$listId'),
                      padding: const EdgeInsets.all(12),
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        final game = games[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GameWishlistListCard(
                            game: game,
                            onTap: () {
                              GameDetailModal.show(
                                context,
                                game,
                                allGames: games,
                                initialIndex: index,
                              );
                            },
                          ),
                        );
                      },
                    )
                  : GridView.builder(
                      key: ValueKey('grid_view_${listId}_${viewSettings.gridColumns}'),
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: viewSettings.gridColumns,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        final game = games[index];
                        return GameWishlistCard(
                          game: game,
                          onTap: () {
                            GameDetailModal.show(
                              context,
                              game,
                              allGames: games,
                              initialIndex: index,
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          listName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          PopupMenuButton<_ListMenuAction>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Opciones de lista',
            itemBuilder: (context) => const [
              PopupMenuItem<_ListMenuAction>(
                value: _ListMenuAction.clear,
                child: Text('Vaciar lista'),
              ),
            ],
            onSelected: (action) async {
              if (action == _ListMenuAction.clear) {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Vaciar lista'),
                    content: const Text('¿Seguro que quieres eliminar todos los juegos de esta lista?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Vaciar'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    final firestoreService = ref.read(firestoreServiceProvider);
                    await firestoreService.clearList(listId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lista "$listName" vaciada'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al vaciar lista: $e'),
                          duration: const Duration(seconds: 3),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              }
            },
          ),
        ],
      ),
      body: gamesAsync.when(
        data: _buildGames,
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
                  'Error al cargar la lista',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}


