import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/game.dart';
import '../providers/wishlist_provider.dart';
import 'add_to_list_modal.dart';

/// 🪄 Modal que muestra la info detallada de un juego (todavía lo voy puliendo)
/// 🪟 Aparece centrado como un diálogo
/// 👈👉 Permite deslizar a la izquierda/derecha para navegar entre juegos
class GameDetailModal extends ConsumerStatefulWidget {
  final List<Game> games;
  final int initialIndex;

  const GameDetailModal({
    super.key,
    required this.games,
    required this.initialIndex,
  });

  @override
  ConsumerState<GameDetailModal> createState() => _GameDetailModalState();

  /// 👀 Muestra el modal de detalle centrado en la pantalla
  /// 🔁 Permite deslizar entre juegos si le paso una lista completa
  static Future<void> show(BuildContext context, Game game, {List<Game>? allGames, int? initialIndex}) async {
    final games = allGames ?? [game];
    final index = initialIndex ?? 0;
    
    await showDialog(
      context: context,
      barrierDismissible: true, // 🙌 Se puede cerrar tocando fuera del modal
      builder: (context) => GameDetailModal(
        games: games,
        initialIndex: index,
      ),
    );
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
            color: const Color(0xFF137FEC), // 🔵 Azul que uso como color principal
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
            );
          },
        ),
      ),
    );
  }
}

/// 📦 Widget que muestra el contenido detallado para un juego individual
class _GameDetailContent extends ConsumerWidget {
  final Game game;

  const _GameDetailContent({
    required this.game,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInWishlistAsync = ref.watch(wishlistCheckerProvider(game.id));

    final bottomPadding = MediaQuery.of(context).viewPadding.bottom + 10;

    return Column(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SizedBox(
            width: double.infinity,
            height: 250,
            child: game.backgroundImage != null
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
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                  )
                : Container(
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
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      const SizedBox(width: 16),
                      isInWishlistAsync.when(
                        data: (isInWishlist) {
                          return GestureDetector(
                            onTap: () async {
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
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: isInWishlist
                                  ? BoxDecoration(
                                      color: const Color(0xFF4CAF50),
                                      borderRadius: BorderRadius.circular(12),
                                    )
                                  : BoxDecoration(
                                      gradient: RadialGradient(
                                        colors: [
                                          const Color(0xFF137FEC).withOpacity(0.85),
                                          const Color(0x00000000),
                                        ],
                                        radius: 0.8,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                              child: const Icon(
                                Icons.card_giftcard_outlined,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
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
                          color: const Color(0xFF137FEC).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF137FEC).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          platform,
                          style: TextStyle(
                            color: const Color(0xFF137FEC),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    AddToListModal.show(context, game);
                  },
                  icon: const Icon(Icons.playlist_add),
                  label: const Text(
                    'Añadir a Listas',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(
                      color: Color(0xFF137FEC),
                      width: 2,
                    ),
                    foregroundColor: const Color(0xFF137FEC),
                  ),
                ),
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
                    backgroundColor: const Color(0xFF137FEC),
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
    );
  }
}

