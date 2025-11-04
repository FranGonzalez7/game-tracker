import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
          child: Center(
            child: Text('Home'),
          ),
        ),
        // Botones cerca del BottomAppBar
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0, left: 16.0, right: 16.0),
          child: Row(
            children: [
              Expanded(
                child: _HomeActionButton(
                  icon: Icons.library_books,
                  label: 'Mi Colección',
                  onTap: () {
                    // TODO: Implementar funcionalidad
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HomeActionButton(
                  icon: Icons.favorite_outline,
                  label: 'Favoritos',
                  onTap: () {
                    // TODO: Implementar funcionalidad
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HomeActionButton(
                  icon: Icons.checklist,
                  label: 'Wishlist',
                  onTap: () {
                    // TODO: Implementar funcionalidad
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget para los botones de acción en Home
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
      color: Colors.grey[850], // Gris oscuro
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xFF137FEC).withOpacity(0.3), // Color del ripple
        highlightColor: const Color(0xFF137FEC).withOpacity(0.1), // Color cuando se mantiene presionado
        child: Container(
          height: 100, // Altura fija para todos los botones
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: const Color(0xFF137FEC), // Azul
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
                    height: 1.2, // Altura de línea para asegurar espacio consistente
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


