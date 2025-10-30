import 'package:flutter/material.dart';

import 'search_tab.dart';
import 'home_tab.dart';
import 'wishlist_tab.dart';
import 'lists_tab.dart';
import 'settings_tab.dart';

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
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomAppBar(
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
                ),
                isSelected: _currentIndex == 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

