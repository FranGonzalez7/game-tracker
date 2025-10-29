import 'package:flutter/material.dart';

import 'search_tab.dart';
import 'my_games_tab.dart';

/// Main screen with tabs for Search and My Games
/// Uses Material 3 design with a clean, modern interface
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Game Tracker',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.search),
                text: 'Search',
              ),
              Tab(
                icon: Icon(Icons.videogame_asset),
                text: 'My Games',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SearchTab(),
            MyGamesTab(),
          ],
        ),
      ),
    );
  }
}

