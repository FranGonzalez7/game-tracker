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

/// Main screen with tabs for Search and My Games
/// Uses Material 3 design with a clean, modern interface
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 2; // Home por defecto

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
                      color: const Color(0xFF8B00FF),
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
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            color: const Color(0xFF8B00FF), // Violeta potente
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
                    // usamos el mismo provider de Firestore existente
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
              backgroundColor: const Color(0xFF8B00FF),
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Color(0xFF8B00FF), // Violeta potente
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
                IconButton.filled(
                  onPressed: () => setState(() => _currentIndex = 0),
                  icon: const Icon(Icons.card_giftcard_outlined, size: 22),
                  tooltip: 'Wishlist',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFAB47BC), // Violeta medio-claro (mismo que Settings)
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  isSelected: _currentIndex == 0,
                ),
                IconButton.filled(
                  onPressed: () => setState(() => _currentIndex = 1),
                  icon: const Icon(Icons.search, size: 22),
                  tooltip: 'Search',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFAB47BC), // Violeta medio-claro (mismo que Settings)
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  isSelected: _currentIndex == 1,
                ),
                IconButton.filled(
                  onPressed: () => setState(() => _currentIndex = 2),
                  icon: const Icon(Icons.home_outlined, size: 28),
                  tooltip: 'Home',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A), // Violeta más oscuro (mantiene home destacado)
                    foregroundColor: Colors.white,
                    fixedSize: const Size(56, 56),
                    side: const BorderSide(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  isSelected: _currentIndex == 2,
                ),
                IconButton.filled(
                  onPressed: () => setState(() => _currentIndex = 3),
                  icon: const Icon(Icons.receipt_long_outlined, size: 22),
                  tooltip: 'Lists',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFAB47BC), // Violeta medio-claro (mismo que Settings)
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  isSelected: _currentIndex == 3,
                ),
                IconButton.filled(
                  onPressed: () => setState(() => _currentIndex = 4),
                  icon: const Icon(Icons.settings_outlined, size: 22),
                  tooltip: 'Settings',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFAB47BC), // Violeta medio-claro
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  isSelected: _currentIndex == 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

