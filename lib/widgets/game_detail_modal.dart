import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/game.dart';
import '../providers/wishlist_provider.dart';
import '../providers/game_status_provider.dart';
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
  late int _loopInitialPage;
  int _currentIndex = 0;
  static const int _loopBuffer = 1000;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loopInitialPage = widget.games.length > 1
        ? widget.games.length * _loopBuffer + widget.initialIndex
        : widget.initialIndex;
    _pageController = PageController(initialPage: _loopInitialPage);
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.games.length > 1 ? null : widget.games.length,
                  onPageChanged: (index) {
                    if (widget.games.length > 1) {
                      setState(() {
                        _currentIndex = index % widget.games.length;
                      });
                    }
                  },
                  itemBuilder: (context, index) {
                    final game = widget.games.length == 1
                        ? widget.games.first
                        : widget.games[index % widget.games.length];
                    return _GameDetailContent(
                      game: game,
                      showNavigationHints: widget.games.length > 1,
                    );
                  },
                ),
              ),
              _GameDetailActions(
                game: widget.games[
                    widget.games.length == 1 ? 0 : _currentIndex % widget.games.length],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 📦 Widget que muestra el contenido detallado para un juego individual
class _GameDetailContent extends ConsumerWidget {
  final Game game;
  final bool showNavigationHints;

  const _GameDetailContent({
    required this.game,
    this.showNavigationHints = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(wishlistCheckerProvider(game.id));

    return Column(
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: SizedBox(
                width: double.infinity,
                height: 250,
                child: game.backgroundImage != null
                    ? Container(
                        color: Theme.of(context).colorScheme.surface,
                        child: CachedNetworkImage(
                          imageUrl: game.backgroundImage!,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          filterQuality: FilterQuality.high,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.videogame_asset,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          ),
                        ),
                      )
                    : Container(
                        color: Theme.of(context).colorScheme.surface,
                        child: Icon(
                          Icons.videogame_asset,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
              ),
            ),
            if (showNavigationHints)
              Positioned.fill(
                child: IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      _NavigationHintArrow(isLeft: true),
                      _NavigationHintArrow(isLeft: false),
                    ],
                  ),
                ),
              ),
          ],
        ),
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
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
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 24,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surface.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 24,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surface.withOpacity(0),
                        ],
                      ),
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

class _GameDetailActions extends ConsumerWidget {
  final Game game;

  const _GameDetailActions({required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom + 10;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: _PlayingNowToggle(game: game),
          ),
          const SizedBox(height: 12),
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
    );
  }
}

class _PlayingNowToggle extends ConsumerStatefulWidget {
  final Game game;

  const _PlayingNowToggle({required this.game});

  @override
  ConsumerState<_PlayingNowToggle> createState() => _PlayingNowToggleState();
}

class _PlayingNowToggleState extends ConsumerState<_PlayingNowToggle> {
  bool _isProcessing = false;
  bool? _lastKnownStatus;

  @override
  void didUpdateWidget(covariant _PlayingNowToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id) {
      _lastKnownStatus = null;
    }
  }

  Future<void> _toggle(bool currentValue) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final controller = ref.read(playingNowControllerProvider);
      await controller.toggle(widget.game, !currentValue);
    } catch (e) {
      debugPrint('Error al actualizar Jugando ahora: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(playingNowStatusProvider(widget.game.id));
    statusAsync.whenData((value) {
      if (_lastKnownStatus != value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _lastKnownStatus = value;
            });
          }
        });
      }
    });

    final isPlaying = statusAsync.asData?.value ?? _lastKnownStatus ?? false;
    final highlightColor = isPlaying ? const Color(0xFFFFC107) : const Color(0xFF137FEC);
    final backgroundColor =
        isPlaying ? const Color(0xFFFFC107).withOpacity(0.12) : Theme.of(context).colorScheme.surface;
    final isDisabled = _isProcessing;

    return OutlinedButton(
      onPressed: isDisabled ? null : () => _toggle(isPlaying),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: highlightColor, width: 2),
        foregroundColor: highlightColor,
        backgroundColor: backgroundColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          _isProcessing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
                  color: highlightColor,
                ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Jugando ahora',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: highlightColor,
                  ) ??
                  TextStyle(
                    fontWeight: FontWeight.bold,
                    color: highlightColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationHintArrow extends StatelessWidget {
  final bool isLeft;

  const _NavigationHintArrow({required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Icon(
        isLeft ? Icons.chevron_left : Icons.chevron_right,
        color: Colors.white,
        size: 34,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

