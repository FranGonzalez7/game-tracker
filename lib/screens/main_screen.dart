import 'package:flutter/material.dart';

import 'search_tab.dart';
import 'home_tab.dart';
import 'wishlist_tab.dart';
import 'lists_tab.dart';
import 'settings_tab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

/// Main screen with tabs for Search and My Games
/// Uses Material 3 design with a clean, modern interface
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            color: const Color(0xFF8B00FF), // Violeta potente
          ),
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final mode = ref.watch(themeModeProvider);
              final isDark = mode == ThemeMode.dark;
              return IconButton(
                tooltip: isDark ? 'Cambiar a claro' : 'Cambiar a oscuro',
                onPressed: () {
                  ref.read(themeModeProvider.notifier).state = isDark ? ThemeMode.light : ThemeMode.dark;
                },
                icon: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
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
                    backgroundColor: Color(0xFFE52521),
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
                    backgroundColor: Color(0xFF00A65E),
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
                    backgroundColor: Colors.black,
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
                    backgroundColor: Color(0xFF2E6DB4),
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
                    backgroundColor: Color(0xFFF7D51D),
                    foregroundColor: Colors.black,
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

