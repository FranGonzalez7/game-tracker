import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/lists_provider.dart';

class ListsTab extends ConsumerWidget {
  const ListsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(userListsStreamProvider);

    return listsAsync.when(
      data: (lists) {
        if (lists.isEmpty) {
          return Center(
            child: Text(
              'Aún no tienes listas. Crea la primera!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final list = lists[index];
            final listId = list['id'] as String;
            final name = list['name'] as String? ?? 'Sin nombre';
            IconData leadingIcon = Icons.list_alt_outlined;
            if (name == 'Mis juegos favoritos') {
              leadingIcon = Icons.favorite_border;
            } else if (name.startsWith('Jugados en ')) {
              leadingIcon = Icons.calendar_month;
            }
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF137FEC), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(name),
                    leading: Icon(leadingIcon, color: const Color(0xFF137FEC)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: navegar al detalle de la lista
                    },
                  ),
                  // Galería de imágenes de juegos
                  _ListGamesPreview(listId: listId),
                ],
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: lists.length,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error al cargar listas: $e'),
      ),
    );
  }
}

/// Widget que muestra una vista previa de los juegos de una lista
class _ListGamesPreview extends ConsumerWidget {
  final String listId;

  const _ListGamesPreview({required this.listId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(listGamesStreamProvider(listId));

    return gamesAsync.when(
      data: (games) {
        if (games.isEmpty) {
          return const SizedBox.shrink();
        }

        // Mostrar máximo 6 imágenes
        final gamesToShow = games.take(6).toList();
        final remainingCount = games.length > 6 ? games.length - 6 : 0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            height: 80,
            child: Row(
              children: [
                ...gamesToShow.asMap().entries.map((entry) {
                  final index = entry.key;
                  final game = entry.value;
                  final isLast = index == gamesToShow.length - 1 && remainingCount == 0;
                  
                  return Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : 8),
                    child: _GamePreviewImage(
                      imageUrl: game.backgroundImage,
                      isOverlay: index == gamesToShow.length - 1 && remainingCount > 0,
                      remainingCount: remainingCount,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Widget que muestra una imagen de juego pequeña
class _GamePreviewImage extends StatelessWidget {
  final String? imageUrl;
  final bool isOverlay;
  final int remainingCount;

  const _GamePreviewImage({
    required this.imageUrl,
    this.isOverlay = false,
    this.remainingCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF137FEC).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.videogame_asset,
                    size: 24,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              )
            else
              Icon(
                Icons.videogame_asset,
                size: 24,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
            if (isOverlay && remainingCount > 0)
              Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
