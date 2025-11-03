import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'wishlist_provider.dart';
import 'auth_provider.dart';
import '../models/game.dart';

/// Stream de listas personalizadas del usuario
/// Reacciona a cambios en el estado de autenticación
final userListsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  // Escuchar cambios en el estado de autenticación
  final authState = ref.watch(authStateProvider);
  
  // Esperar a que el estado de autenticación esté cargado
  await authState.when(
    data: (_) {},
    loading: () async {},
    error: (_, __) {},
  );
  
  // Determinar si el usuario está autenticado
  final isAuthenticated = authState.value != null;
  
  // Si el usuario no está autenticado, retornar lista vacía
  if (!isAuthenticated) {
    yield <Map<String, dynamic>>[];
    return;
  }
  
  final firestoreService = ref.watch(firestoreServiceProvider);

  try {
    // Asegurar listas por defecto antes de escuchar
    try {
      await firestoreService.ensureDefaultLists();
    } catch (e) {
      // Ignorar errores al crear listas por defecto, puede que ya existan
      debugPrint('Error al asegurar listas por defecto: $e');
    }

    // Escuchar el stream de listas con manejo de errores
    try {
      await for (final lists in firestoreService.getUserListsStream()) {
        yield lists;
      }
    } catch (error) {
      debugPrint('Error al obtener stream de listas: $error');
      // Capturar errores de permisos y retornar lista vacía
      if (error.toString().contains('permission-denied') || 
          error.toString().contains('The caller does not have permission')) {
        yield <Map<String, dynamic>>[];
        return;
      }
      // Para otros errores, re-lanzar el error
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

/// Stream de juegos de una lista específica
/// Reacciona a cambios en el estado de autenticación
final listGamesStreamProvider = StreamProvider.family<List<Game>, String>((ref, listId) async* {
  // Escuchar cambios en el estado de autenticación
  final authState = ref.watch(authStateProvider);
  
  // Determinar si el usuario está autenticado
  final isAuthenticated = authState.value != null;
  
  // Si el usuario no está autenticado, retornar lista vacía
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
    // Capturar errores de permisos y retornar lista vacía
    if (error.toString().contains('permission-denied') ||
        error.toString().contains('The caller does not have permission')) {
      yield <Game>[];
      return;
    }
    // Para otros errores, re-lanzar el error
    rethrow;
  }
});

/// Clase para identificar un juego en una lista
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

/// Provider que verifica si un juego está en una lista específica
final isGameInListProvider = FutureProvider.family<bool, GameListKey>((ref, key) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  if (!firestoreService.isAuthenticated) {
    return false;
  }
  
  return firestoreService.isGameInList(key.listId, key.gameId);
});


