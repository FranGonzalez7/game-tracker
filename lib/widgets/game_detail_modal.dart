import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/game.dart';
import '../providers/wishlist_provider.dart';

/// Modal widget that displays detailed information about a game
/// Appears centered on the screen as a dialog
/// Allows swiping left/right to navigate between games
class GameDetailModal extends ConsumerStatefulWidget {
  final List<Game> games;
  final int initialIndex;
  final bool isInWishlist;

  const GameDetailModal({
    super.key,
    required this.games,
    required this.initialIndex,
    this.isInWishlist = false,
  });

  @override
  ConsumerState<GameDetailModal> createState() => _GameDetailModalState();

  /// Shows the game detail modal centered on the screen
  /// Allows swiping between games if a list is provided
  /// Returns true if user wants to add to wishlist, false if remove, null otherwise
  static Future<bool?> show(BuildContext context, Game game, {List<Game>? allGames, int? initialIndex, bool isInWishlist = false}) async {
    final games = allGames ?? [game];
    final index = initialIndex ?? 0;
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true, // Permite cerrar tocando fuera del modal
      builder: (context) => GameDetailModal(
        games: games,
        initialIndex: index,
        isInWishlist: isInWishlist,
      ),
    );
    
    return result;
  }
}

class _GameDetailModalState extends ConsumerState<GameDetailModal> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleWishlistAction(Game game) async {
    if (widget.isInWishlist) {
      // Remove from wishlist
      try {
        await ref.read(wishlistNotifierProvider.notifier).removeFromWishlist(game.id);
        if (mounted) {
          Navigator.of(context).pop(false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al quitar de la wishlist: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Add to wishlist - return true to signal the caller
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.83,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF8B00FF), // Violeta potente
            width: 3,
          ),
        ),
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.games.length,
          itemBuilder: (context, index) {
            final game = widget.games[index];
            return _GameDetailContent(
              game: game,
              isInWishlist: widget.isInWishlist,
              onWishlistAction: () => _handleWishlistAction(game),
            );
          },
        ),
      ),
    );
  }
}

/// Widget that displays the content for a single game
class _GameDetailContent extends StatelessWidget {
  final Game game;
  final bool isInWishlist;
  final VoidCallback onWishlistAction;

  const _GameDetailContent({
    required this.game,
    required this.isInWishlist,
    required this.onWishlistAction,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: game.backgroundImage != null
                ? CachedNetworkImage(
                    imageUrl: game.backgroundImage!,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: double.infinity,
                      height: 250,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: double.infinity,
                      height: 250,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.videogame_asset,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Icon(
                      Icons.videogame_asset,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
          ),

          // Game Info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  game.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ) ?? const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // Rating
                if (game.rating != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        game.rating!.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ) ?? const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Release Date
                if (game.released != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        game.released!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ) ?? TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Platforms
                if (game.platforms != null && game.platforms!.isNotEmpty) ...[
                  Text(
                    'Plataformas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ) ?? const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: game.platforms!.map((platform) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B00FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF8B00FF).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          platform,
                          style: TextStyle(
                            color: const Color(0xFF8B00FF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Wishlist Button and Close Button
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onWishlistAction,
                        icon: Icon(isInWishlist ? Icons.delete_outline : Icons.card_giftcard),
                        label: Text(isInWishlist ? 'Quitar de la Wishlist' : 'Añadir a Wishlist'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: isInWishlist 
                              ? Theme.of(context).colorScheme.error 
                              : const Color(0xFFE52521), // Rojo para wishlist
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: const Color(0xFF8B00FF),
                    ),
                    child: const Text(
                      'Cerrar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

