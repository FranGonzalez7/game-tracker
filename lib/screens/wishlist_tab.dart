import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wishlist_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/game_search_card.dart';
import '../widgets/game_detail_modal.dart';

/// Tab screen for displaying user's wishlist
/// Shows games saved to wishlist from Firestore
class WishlistTab extends ConsumerWidget {
  const WishlistTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistStreamProvider);
    final viewSettings = ref.watch(wishlistViewSettingsProvider);

    void increaseCardSize() {
      if (viewSettings.gridColumns > 1) {
        ref.read(wishlistViewSettingsProvider.notifier).setGridColumns(viewSettings.gridColumns - 1);
      }
    }

    void decreaseCardSize() {
      if (viewSettings.gridColumns < 5) {
        ref.read(wishlistViewSettingsProvider.notifier).setGridColumns(viewSettings.gridColumns + 1);
      }
    }

    void toggleView() {
      ref.read(wishlistViewSettingsProvider.notifier).setListView(!viewSettings.isListView);
    }

    return wishlistAsync.when(
      data: (games) {
        if (games.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.card_giftcard_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tu wishlist está vacía',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ) ?? TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Añade juegos desde la búsqueda',
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
            // Options toolbar
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
                  // Size controls (only show in grid view)
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
                  // List/Grid toggle button
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
            // Game list or grid
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
                        key: const ValueKey('list'),
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
                                  isInWishlist: true,
                                );
                              },
                            ),
                          );
                        },
                      )
                    : GridView.builder(
                        key: ValueKey('grid_${viewSettings.gridColumns}'),
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
                                isInWishlist: true,
                              );
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
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
                'Error al cargar la wishlist',
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
    );
  }
}


