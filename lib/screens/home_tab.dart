import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'list_detail_screen.dart';
import '../models/game.dart';
import '../providers/game_status_provider.dart';
import '../widgets/game_detail_modal.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // 🧺 Contenedor superior justo bajo la AppBar (todavía está vacío pero me sirve de guía)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF137FEC), // 🔵 Azul que uso en casi todo
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        // 🎮 Bloque de botones en el centro (quiero que se sienta como acceso rápido)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: _HomeActionButton(
                  icon: Icons.library_books,
                  label: 'Mi Colección',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ListDetailScreen(
                          listId: 'my_collection',
                          fallbackName: 'Mi colección',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HomeActionButton(
                  icon: Icons.favorite_outline,
                  label: 'Favoritos',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ListDetailScreen(
                          listId: 'favorites',
                          fallbackName: 'Mis juegos favoritos',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HomeActionButton(
                  icon: Icons.checklist,
                  label: 'Wishlist',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ListDetailScreen(
                          listId: 'wishlist',
                          fallbackName: 'Wishlist',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // 📦 Contenedor inferior: Juegos que está jugando actualmente
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF137FEC), // 🔵 Azul para mantener consistencia
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _PlayingNowSection(),
            ),
          ),
        ),
      ],
    );
  }
}

/// 🕹️ Widget para los botones de acción de Home (los uso para practicar InkWell y Material)
class _HomeActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[850], // ⚙️ Gris oscuro para que el azul resalte
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xFF137FEC).withOpacity(0.3), // 💧 Color del ripple cuando lo tocan
        highlightColor: const Color(0xFF137FEC).withOpacity(0.1), // 🌟 Color cuando se mantiene presionado
        child: Container(
          height: 100, // 📏 Altura fija para que todos se vean iguales
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: const Color(0xFF137FEC), // 🔵 Azul protagonista
                size: 32,
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.2, // 📐 Altura de línea para mantener el texto ordenado
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🎮 Sección que muestra los juegos que el usuario está jugando actualmente
class _PlayingNowSection extends ConsumerWidget {
  const _PlayingNowSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playingNowAsync = ref.watch(playingNowGamesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 📌 Título de la sección
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            'Jugando actualmente',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // 🎮 Lista horizontal de juegos (justo debajo del título)
        SizedBox(
          height: 80, // Altura fija para la sección de juegos
          child: playingNowAsync.when(
            data: (games) {
              if (games.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No estás jugando a ningún juego actualmente',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemCount: games.length,
                itemBuilder: (context, index) {
                  final game = games[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: _PlayingNowChip(
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
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF137FEC),
              ),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Error al cargar juegos',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        // 📦 Espacio para más contenido en el futuro
        Expanded(
          child: Container(
            // Este espacio quedará disponible para más contenido
          ),
        ),
      ],
    );
  }
}

/// 🏷️ Chip que muestra un juego que está siendo jugado actualmente
class _PlayingNowChip extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;

  const _PlayingNowChip({
    required this.game,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: BoxConstraints(
          minWidth: 120,
          maxWidth: 200,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🖼️ Imagen del juego (20% más grande) con borde discontinuo
            SizedBox(
              width: 62, // 48 * 1.2 ≈ 58
              height: 62, // 48 * 1.2 ≈ 58
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: const Color(0xFF137FEC),
                  strokeWidth: 2.0, // Borde un poco más grueso
                  borderRadius: 6,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0), // Más margen entre imagen y borde
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: game.backgroundImage != null
                        ? CachedNetworkImage(
                            imageUrl: game.backgroundImage!,
                            width: 54, // 62 - 8 (padding) = 54
                            height: 54, // 62 - 8 (padding) = 54
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 54,
                              height: 54,
                              color: Colors.grey[800],
                              child: Icon(
                                Icons.videogame_asset,
                                size: 26,
                                color: Colors.grey[600],
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 54,
                              height: 54,
                              color: Colors.grey[800],
                              child: Icon(
                                Icons.videogame_asset,
                                size: 26,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : Container(
                            width: 54,
                            height: 54,
                            color: Colors.grey[800],
                            child: Icon(
                              Icons.videogame_asset,
                              size: 26,
                              color: Colors.grey[600],
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 📝 Nombre del juego (muy estrecho, varias líneas si es necesario)
            Expanded(
              child: Text(
                game.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  letterSpacing: -0.8, // Mucho más estrecho para que corte más rápido
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🎨 Pintor personalizado para dibujar bordes discontinuos (dashed)
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    // Dibujar línea discontinua
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    final pathMetrics = path.computeMetrics();

    for (final pathMetric in pathMetrics) {
      var distance = 0.0;
      while (distance < pathMetric.length) {
        final extractPath = pathMetric.extractPath(
          distance,
          distance + dashWidth,
        );
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}
