import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/saved_games_provider.dart';
import '../models/saved_game.dart';
import '../widgets/game_list_card.dart';
import 'game_detail_screen.dart';

/// Tab screen displaying all saved games
/// Shows game cards with title, cover, dates, and rating
class MyGamesTab extends ConsumerWidget {
  const MyGamesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedGames = ref.watch(savedGamesProvider);

    if (savedGames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videogame_asset_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No games saved yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search and add games to track them',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: savedGames.length,
      itemBuilder: (context, index) {
        final game = savedGames[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GameListCard(
            game: game,
            onTap: () async {
              final updatedGame = await Navigator.push<SavedGame>(
                context,
                MaterialPageRoute(
                  builder: (context) => GameDetailScreen(game: game),
                ),
              );

              if (updatedGame != null && context.mounted) {
                ref.read(savedGamesProvider.notifier).updateGame(updatedGame);
              }
            },
            onDelete: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Game'),
                  content: Text('Are you sure you want to delete ${game.name}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(savedGamesProvider.notifier).deleteGame(game.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${game.name} deleted'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

