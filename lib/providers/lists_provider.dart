import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'wishlist_provider.dart';
import 'auth_provider.dart';
import '../models/game.dart';

/// 🌊 Stream de listas personalizadas del usuario
/// 👂 Reacciona a los cambios en el estado de autenticación
final userListsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  // 👂 Escucho los cambios en el estado de autenticación
  final authState = ref.watch(authStateProvider);
  
  // ⏳ Espero a que el estado esté cargado (me da paz antes de seguir)
  await authState.when(
    data: (_) {},
    loading: () async {},
    error: (_, __) {},
  );
  
  // 🤔 Reviso si hay alguien autenticado
  final isAuthenticated = authState.value != null;
  
  // 🚫 Si no hay usuario, devuelvo una lista vacía y salgo
  if (!isAuthenticated) {
    yield <Map<String, dynamic>>[];
    return;
  }
  
  final firestoreService = ref.watch(firestoreServiceProvider);

  try {
    // 🧰 Aseguro que existan las listas por defecto antes de escuchar
    try {
      await firestoreService.ensureDefaultLists();
    } catch (e) {
      // 🤫 Si falla, lo ignoro porque puede ser que ya existan
      debugPrint('Error al asegurar listas por defecto: $e');
    }

    // 🎧 Escucho el stream de listas con algo de manejo de errores
    try {
      await for (final lists in firestoreService.getUserListsStream()) {
        yield lists;
      }
    } catch (error) {
      debugPrint('Error al obtener stream de listas: $error');
      // 🔐 Si es un error de permisos, devuelvo lista vacía para no romper nada
      if (error.toString().contains('permission-denied') || 
          error.toString().contains('The caller does not have permission')) {
        yield <Map<String, dynamic>>[];
        return;
      }
      // 🚨 Otros errores sí los relanzo para investigarlos
      rethrow;
    }
  } catch (error) {
    debugPrint('Error general en userListsStreamProvider: $error');
    if (error.toString().contains('permission-denied') ||
        error.toString().contains('The caller does not have permission')) {
      yield <Map<String, dynamic>>[];
      return;
    }
    rethrow;
  }
});

/// 🌊 Stream con los juegos de una lista específica
/// 👂 También reacciona a los cambios de autenticación
final listGamesStreamProvider = StreamProvider.family<List<Game>, String>((ref, listId) async* {
  // 👂 Escucho el estado de autenticación
  final authState = ref.watch(authStateProvider);
  
  // 🤔 Reviso si hay un usuario logueado
  final isAuthenticated = authState.value != null;
  
  // 🚫 Si no hay usuario, retorno una lista vacía y fin
  if (!isAuthenticated) {
    yield <Game>[];
    return;
  }
  
  final firestoreService = ref.watch(firestoreServiceProvider);

  try {
    await for (final games in firestoreService.getListGamesStream(listId)) {
      yield games;
    }
  } catch (error) {
    // 🔐 Si hay errores de permisos, regreso lista vacía
    if (error.toString().contains('permission-denied') ||
        error.toString().contains('The caller does not have permission')) {
      yield <Game>[];
      return;
    }
    // 🚨 Otros errores los relanzo para que Riverpod los propague
    rethrow;
  }
});

/// 🆔 Clase sencilla para identificar un juego dentro de una lista
class GameListKey {
  final String listId;
  final int gameId;

  const GameListKey({
    required this.listId,
    required this.gameId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameListKey &&
          runtimeType == other.runtimeType &&
          listId == other.listId &&
          gameId == other.gameId;

  @override
  int get hashCode => listId.hashCode ^ gameId.hashCode;
}

/// ❓ Provider que revisa si un juego está en una lista específica
final isGameInListProvider = FutureProvider.family<bool, GameListKey>((ref, key) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  if (!firestoreService.isAuthenticated) {
    return false;
  }
  
  return firestoreService.isGameInList(key.listId, key.gameId);
});

/// 📦 Provider para controlar si las listas están colapsadas (sin mostrar imágenes)
final listsCollapsedProvider = StateProvider<bool>((ref) => false);


