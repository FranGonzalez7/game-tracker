import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/game.dart';
import '../providers/wishlist_provider.dart';

/// Minimalist card widget for displaying game search results in a grid
/// Shows only game image and title
class GameSearchCard extends ConsumerWidget {
  final Game game;
  final VoidCallback onTap;

  const GameSearchCard({
    super.key,
    required this.game,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInWishlistAsync = ref.watch(wishlistCheckerProvider(game.id));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF8B00FF), // Violeta potente
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Game Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    game.backgroundImage != null
                        ? CachedNetworkImage(
                            imageUrl: game.backgroundImage!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.videogame_asset,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                              ),
                            ),
                          )
                        : Container(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.videogame_asset,
                              size: 40,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                            ),
                          ),
                    Positioned(
                    top: 8,
                    right: 8,
                    child: isInWishlistAsync.when(
                      data: (isInWishlist) {
                        final bg = isInWishlist ? const Color(0xFF6A1B9A) : const Color(0xFF8B00FF);
                        return Container(
                          decoration: BoxDecoration(
                            color: bg,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.card_giftcard_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () async {
                              final wishlistNotifier = ref.read(wishlistNotifierProvider.notifier);
                              try {
                                if (isInWishlist) {
                                  await wishlistNotifier.removeFromWishlist(game.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${game.name} eliminado de la wishlist'),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                } else {
                                  await wishlistNotifier.addToWishlist(game);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${game.name} añadido a la wishlist'),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al actualizar wishlist: $e'),
                                      duration: const Duration(seconds: 3),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  ],
                ),
              ),
            ),
            // Game Title
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    game.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ) ?? const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
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

/// Minimalist card widget for displaying games in wishlist
/// Shows only game image without title
class GameWishlistCard extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;

  const GameWishlistCard({
    super.key,
    required this.game,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF8B00FF), // Violeta potente
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: game.backgroundImage != null
              ? CachedNetworkImage(
                  imageUrl: game.backgroundImage!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.videogame_asset,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                )
              : Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.videogame_asset,
                    size: 40,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
        ),
      ),
    );
  }
}

/// List view card for wishlist games
/// Shows game image, title, rating, and release date in a horizontal layout
class GameWishlistListCard extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;

  const GameWishlistListCard({
    super.key,
    required this.game,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF8B00FF),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Game Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: game.backgroundImage != null
                  ? CachedNetworkImage(
                      imageUrl: game.backgroundImage!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 80,
                        height: 80,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80,
                        height: 80,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.videogame_asset,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.videogame_asset,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
            ),
            // Game Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      game.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ) ?? const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (game.rating != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            game.rating!.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ) ?? const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ],
                    if (game.released != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            game.released!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ) ?? TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Arrow indicator
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

