import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'search_tab.dart';
import 'home_tab.dart';
import 'wishlist_tab.dart';
import 'lists_tab.dart';
import 'settings_tab.dart';
import '../widgets/profile_modal.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';

/// 🧭 Pantalla principal con pestañas para Buscar y Mis Juegos
/// 🧱 Está hecha con Material 3 y trato de mantenerla limpia (sigo practicando diseño)
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 2; // 🏠 Arranco en Home por defecto porque es mi pestaña favorita

  static const _titles = ['Wishlist', 'Search', 'Home', 'Lists', 'Settings'];

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const WishlistTab();
      case 1:
        return const SearchTab();
      case 2:
        return const HomeTab();
      case 3:
        return const ListsTab();
      case 4:
        return const SettingsTab();
      default:
        return const HomeTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          authState.when(
            data: (user) {
              if (user == null) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () {
                  ProfileModal.show(context, ref);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF137FEC),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: user.photoURL != null
                        ? CachedNetworkImage(
                            imageUrl: user.photoURL!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          )
                        : Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 3,
            color: const Color(0xFF0A4A7A), // 🌌 Azul oscurito para remarcar el borde
          ),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: _currentIndex == 3
          ? FloatingActionButton.extended(
              onPressed: () async {
                final name = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    final controller = TextEditingController();
                    return AlertDialog(
                      title: const Text('Nueva Lista'),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la lista',
                          hintText: 'Ej. JRPGs pendientes',
                        ),
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => Navigator.of(context).pop(controller.text.trim()),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                          child: const Text('Crear'),
                        ),
                      ],
                    );
                  },
                );

                if (name != null && name.isNotEmpty) {
                  try {
                    // 🔁 Uso el mismo provider de Firestore que ya teníamos para no duplicar lógica
                    final firestoreService = ref.read(firestoreServiceProvider);
                    await firestoreService.createList(name);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lista "$name" creada')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al crear lista: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
              icon: const Icon(Icons.playlist_add),
              label: const Text('Nueva Lista'),
              backgroundColor: const Color(0xFF137FEC),
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Color(0xFF0A4A7A), // 🌌 Azul oscurito, igual que arriba
              width: 3,
            ),
          ),
        ),
        child: BottomAppBar(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavIcon(
                  icon: Icons.sports_esports,
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                  tooltip: 'Wishlist',
                ),
                _BottomNavIcon(
                  icon: Icons.search,
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                  tooltip: 'Search',
                ),
                _BottomNavIcon(
                  icon: Icons.home_outlined,
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                  tooltip: 'Home',
                ),
                _BottomNavIcon(
                  icon: Icons.receipt_long_outlined,
                  isSelected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                  tooltip: 'Lists',
                  imagePath: 'assets/coleccion.png',
                ),
                _BottomNavIcon(
                  icon: Icons.settings_outlined,
                  isSelected: _currentIndex == 4,
                  onTap: () => setState(() => _currentIndex = 4),
                  tooltip: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🧷 Widget personalizado para los iconos de la barra inferior
/// 🌟 Sin círculo, icono blanco por defecto y celeste brillante cuando está seleccionado
class _BottomNavIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;
  final String? imagePath;

  const _BottomNavIcon({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.tooltip,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Tooltip(
        message: tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: imagePath != null
              ? Image.asset(
                  imagePath!,
                  width: isSelected ? 34 : 26,
                  height: isSelected ? 34 : 26,
                  color: isSelected 
                      ? const Color(0xFF5FD0FF) // ✨ Celeste potente cuando está seleccionado
                      : Colors.white.withOpacity(0.7), // 🤍 Blanco semi-transparente cuando no está seleccionado
                  colorBlendMode: BlendMode.srcIn,
                )
              : Icon(
                  icon,
                  size: isSelected ? 34 : 26,
                  color: isSelected 
                      ? const Color(0xFF5FD0FF) // ✨ Celeste potente cuando está seleccionado
                      : Colors.white.withOpacity(0.7), // 🤍 Blanco semi-transparente cuando no está seleccionado
                ),
        ),
      ),
    );
  }
}

