import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/lists_provider.dart';
import '../providers/wishlist_provider.dart';
import 'list_detail_screen.dart';

class ListsTab extends ConsumerWidget {
  const ListsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<List<Map<String, dynamic>>>>(
      userListsStreamProvider,
      (previous, next) {
        next.whenData(
          (lists) => ref
              .read(listsOrderOverrideProvider.notifier)
              .syncWithFirestore(lists),
        );
      },
    );

    final listsAsync = ref.watch(userListsWithReorderProvider);

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

        return ReorderableListView(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 80), // 📏 Padding extra abajo para el FAB
          // 🎨 Decorador personalizado para el elemento mientras se arrastra (más suave y elegante)
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                // 🎯 Uso una curva más suave para transiciones más naturales
                final animValue = Curves.easeOutCubic.transform(animation.value);
                return Material(
                  elevation: 6 + (animValue * 6), // ✨ Elevación más alta mientras se arrastra
                  borderRadius: BorderRadius.circular(12),
                  shadowColor: const Color(0xFF137FEC).withOpacity(0.4),
                  color: Colors.transparent,
                  child: Transform.scale(
                    scale: 1.02 + (animValue * 0.03), // 📏 Escala más sutil
                    child: Opacity(
                      opacity: 0.95 + (animValue * 0.05), // 🌫️ Opacidad más sutil
                      child: child,
                    ),
                  ),
                );
              },
              child: child,
            );
          },
          onReorder: (oldIndex, newIndex) async {
            // 📋 ReorderableListView ya ajusta el índice correctamente
            // Si newIndex > oldIndex, significa que se mueve hacia abajo
            // y el índice ya está ajustado por Flutter (el elemento ya fue removido)
            // Si newIndex <= oldIndex, se mueve hacia arriba y el índice es correcto
            
            // ⚡ ACTUALIZACIÓN OPTIMISTA: Aplico el cambio inmediatamente en el estado local
            // (el método reorderOptimistic ya maneja el ajuste correctamente)
            ref.read(listsOrderOverrideProvider.notifier).reorderOptimistic(oldIndex, newIndex);
            
            // 📋 Obtengo el estado optimista actualizado para guardar en Firestore
            // Esto asegura que usamos exactamente el mismo orden que se muestra visualmente
            final optimisticState = ref.read(listsOrderOverrideProvider);
            if (optimisticState == null) return; // No debería pasar, pero por seguridad
            
            // 💾 Extraigo los IDs en el nuevo orden del estado optimista
            final listIds = optimisticState.map((list) => list['id'] as String).toList();
            
            // 🔥 Guardo el nuevo orden en Firestore en segundo plano
            // (el estado local ya tiene el orden correcto, así que no hay rebote)
            try {
              final firestoreService = ref.read(firestoreServiceProvider);
              await firestoreService.updateListsOrder(listIds);
              // Cuando Firestore se actualice, el stream se sincronizará automáticamente
            } catch (e) {
              // ⚠️ Si falla, revierto el cambio optimista
              ref.read(listsOrderOverrideProvider.notifier).clear();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al actualizar el orden: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          children: [
            for (int index = 0; index < lists.length; index++)
              _ReorderableListCard(
                key: ValueKey(lists[index]['id'] as String),
                list: lists[index],
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error al cargar listas: $e'),
      ),
    );
  }
}

/// 🎴 Widget de tarjeta reordenable para cada lista
class _ReorderableListCard extends ConsumerWidget {
  final Map<String, dynamic> list;

  const _ReorderableListCard({
    required super.key,
    required this.list,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listId = list['id'] as String;
    final name = list['name'] as String? ?? 'Sin nombre';
    IconData leadingIcon = Icons.list_alt_outlined;
    if (listId == 'favorites') {
      leadingIcon = Icons.favorite_border;
    } else if (listId == 'my_collection') {
      leadingIcon = Icons.inventory_2_outlined;
    } else if (listId == 'wishlist') {
      leadingIcon = Icons.bookmark_border;
    } else if (listId.startsWith('played_year_')) {
      leadingIcon = Icons.calendar_month;
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), // ⏱️ Animación suave para cambios
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 4), // 📏 Espaciado entre tarjetas
      child: Card(
        key: key, // 🔑 Key necesaria para ReorderableListView
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF137FEC), width: 2),
        ),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ListDetailScreen(
                  listId: listId,
                  fallbackName: name,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ListHeader(
                name: name,
                leadingIcon: leadingIcon,
                listId: listId,
              ),
              // 🖼️ Galería mini de los juegos que tiene la lista (se oculta si está colapsado)
              Consumer(
                builder: (context, ref, _) {
                  final isCollapsed = ref.watch(listsCollapsedProvider);
                  if (isCollapsed) {
                    return const SizedBox.shrink();
                  }
                  return _ListGamesPreview(listId: listId);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🪧 Widget que arma el encabezado de cada lista (título + cuántos juegos cuento)
class _ListHeader extends ConsumerWidget {
  final String name;
  final IconData leadingIcon;
  final String listId;

  const _ListHeader({
    required this.name,
    required this.leadingIcon,
    required this.listId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(listGamesStreamProvider(listId));

    return gamesAsync.when(
      data: (games) {
        final gameCount = games.length;
        final subtitle = gameCount == 1 ? '1 juego' : '$gameCount juegos';
        
        return ListTile(
          title: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          leading: Icon(leadingIcon, color: const Color(0xFF137FEC)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.drag_handle,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
          mouseCursor: SystemMouseCursors.basic,
        );
      },
      loading: () => ListTile(
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: Icon(leadingIcon, color: const Color(0xFF137FEC)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.drag_handle,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              size: 20,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        mouseCursor: SystemMouseCursors.basic,
      ),
      error: (_, __) => ListTile(
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: Icon(leadingIcon, color: const Color(0xFF137FEC)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.drag_handle,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              size: 20,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        mouseCursor: SystemMouseCursors.basic,
      ),
    );
  }
}

/// 🎞️ Widget que enseña una vista previa rápida de los juegos dentro de la lista
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

        return Transform.translate(
          offset: const Offset(0, -8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 2),
            child: SizedBox(
              height: 64,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: games.length,
                itemBuilder: (context, index) {
                  final game = games[index];
                  final isLast = index == games.length - 1;
                  
                  return Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : 4),
                    child: _GamePreviewImage(
                      imageUrl: game.backgroundImage,
                      isOverlay: false,
                      remainingCount: 0,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// 🖼️ Widget que pinta una imagen pequeña del juego (es mi manera de practicar diseños)
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
        width: 64,
        height: 64,
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
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              )
            else
              Icon(
                Icons.videogame_asset,
                size: 20,
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
