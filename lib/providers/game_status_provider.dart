import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game.dart';
import 'wishlist_provider.dart';

/// 🔄 Provider que expone el estado "Jugando ahora" para un juego
final playingNowStatusProvider = StreamProvider.family<bool, int>((ref, gameId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.playingNowStatusStream(gameId);
});

/// 🕹️ Helper para alternar el estado "Jugando ahora"
final playingNowControllerProvider = Provider<PlayingNowController>((ref) {
  return PlayingNowController(ref);
});

class PlayingNowController {
  final Ref _ref;

  PlayingNowController(this._ref);

  Future<void> toggle(Game game, bool nextValue) async {
    final firestoreService = _ref.read(firestoreServiceProvider);
    await firestoreService.setPlayingNowStatus(game, nextValue);
  }
}

