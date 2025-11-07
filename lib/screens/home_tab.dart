import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
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
                    // TODO 🎯: implementar esta acción (aún pienso qué mostrar)
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HomeActionButton(
                  icon: Icons.favorite_outline,
                  label: 'Favoritos',
                  onTap: () {
                    // TODO ❤️: implementar favoritos desde aquí
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HomeActionButton(
                  icon: Icons.checklist,
                  label: 'Wishlist',
                  onTap: () {
                    // TODO ⭐: llevar directo a la wishlist
                  },
                ),
              ),
            ],
          ),
        ),
        // 📦 Contenedor inferior justo sobre la BottomAppBar (quizás ponga estadísticas luego)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF137FEC), // 🔵 Azul para mantener consistencia
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
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


