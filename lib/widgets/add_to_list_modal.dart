import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game.dart';
import '../providers/lists_provider.dart';
import '../providers/wishlist_provider.dart';

/// Modal para seleccionar una lista y añadir un juego
class AddToListModal extends ConsumerWidget {
  final Game game;

  const AddToListModal({
    super.key,
    required this.game,
  });

  /// Muestra el modal de selección de listas
  static Future<void> show(BuildContext context, Game game) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddToListModal(game: game),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(userListsStreamProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Añadir a Lista',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ) ?? const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Nombre del juego
            Text(
              game.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ) ?? TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            // Lista de listas disponibles
            Expanded(
              child: listsAsync.when(
                data: (lists) {
                  if (lists.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.list_alt_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tienes listas creadas',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ) ?? TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: lists.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final list = lists[index];
                      final listId = list['id'] as String;
                      final listName = list['name'] as String? ?? 'Sin nombre';
                      
                      IconData leadingIcon = Icons.list_alt_outlined;
                      if (listName == 'Mis juegos favoritos') {
                        leadingIcon = Icons.favorite_border;
                      } else if (listName.startsWith('Jugados en ')) {
                        leadingIcon = Icons.calendar_month;
                      }

                      return _ListTileButton(
                        listId: listId,
                        listName: listName,
                        leadingIcon: leadingIcon,
                        game: game,
                        onAdded: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${game.name} añadido a $listName'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        onUpdated: () {
                          // Invalidar el provider para refrescar el estado
                          ref.invalidate(isGameInListProvider(GameListKey(listId: listId, gameId: game.id)));
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar listas',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ) ?? TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ) ?? TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListTileButton extends ConsumerStatefulWidget {
  final String listId;
  final String listName;
  final IconData leadingIcon;
  final Game game;
  final VoidCallback onAdded;
  final VoidCallback onUpdated;

  const _ListTileButton({
    required this.listId,
    required this.listName,
    required this.leadingIcon,
    required this.game,
    required this.onAdded,
    required this.onUpdated,
  });

  @override
  ConsumerState<_ListTileButton> createState() => _ListTileButtonState();
}

class _ListTileButtonState extends ConsumerState<_ListTileButton> {
  bool _isLoading = false;

  Future<void> _addToList() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.addGameToList(widget.listId, widget.game);
      
      if (mounted) {
        widget.onAdded();
        widget.onUpdated(); // Invalidar el provider para refrescar el estado
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al añadir a la lista: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInListAsync = ref.watch(isGameInListProvider(GameListKey(
      listId: widget.listId,
      gameId: widget.game.id,
    )));

    return isInListAsync.when(
      data: (isInList) {
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isInList
                  ? const Color(0xFF4CAF50).withOpacity(0.5)
                  : const Color(0xFF137FEC).withOpacity(0.3),
              width: isInList ? 2 : 1,
            ),
          ),
          color: isInList
              ? const Color(0xFF4CAF50).withOpacity(0.1)
              : null,
          child: ListTile(
            leading: Icon(
              widget.leadingIcon,
              color: isInList ? const Color(0xFF4CAF50) : const Color(0xFF137FEC),
            ),
            title: Text(
              widget.listName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isInList ? const Color(0xFF4CAF50) : null,
                  ) ?? TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isInList ? const Color(0xFF4CAF50) : null,
                  ),
            ),
            trailing: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : isInList
                    ? const Icon(
                        Icons.check_circle,
                        color: Color(0xFF4CAF50),
                      )
                    : const Icon(
                        Icons.add_circle_outline,
                        color: const Color(0xFF137FEC),
                      ),
            onTap: isInList ? null : _addToList,
          ),
        );
      },
      loading: () => Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: const Color(0xFF137FEC).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ListTile(
          leading: Icon(widget.leadingIcon, color: const Color(0xFF137FEC)),
          title: Text(
            widget.listName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ) ?? const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
          ),
          trailing: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: const Color(0xFF137FEC).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ListTile(
          leading: Icon(widget.leadingIcon, color: const Color(0xFF137FEC)),
          title: Text(
            widget.listName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ) ?? const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
          ),
          trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF137FEC)),
          onTap: _addToList,
        ),
      ),
    );
  }
}

