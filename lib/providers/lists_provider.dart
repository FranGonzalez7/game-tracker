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

/// 🎯 Estado local para el orden de las listas (actualización optimista)
final listsOrderOverrideProvider =
    StateNotifierProvider<_ListsOrderNotifier, List<Map<String, dynamic>>?>(
  (ref) => _ListsOrderNotifier(),
);

class _ListsOrderNotifier extends StateNotifier<List<Map<String, dynamic>>?> {
  _ListsOrderNotifier() : super(null);
  
  // 🕐 Timestamp de la última actualización optimista para evitar rebotes
  DateTime? _lastOptimisticUpdate;
  // 📋 Orden esperado después de un reordenamiento optimista
  List<String>? _expectedOrder;

  /// 📥 Sincroniza el estado con Firestore cuando no hay cambios pendientes.
  void syncWithFirestore(List<Map<String, dynamic>> lists) {
    if (state == null) {
      state = lists;
      return;
    }

    final localIds = state!.map((l) => l['id'] as String).toList();
    final firestoreIds = lists.map((l) => l['id'] as String).toList();
    
    // ⏱️ Si hubo una actualización optimista reciente (últimos 3 segundos),
    // y el orden de Firestore NO coincide con el esperado, lo ignoro para evitar rebotes
    if (_lastOptimisticUpdate != null && _expectedOrder != null) {
      final timeSinceUpdate = DateTime.now().difference(_lastOptimisticUpdate!);
      if (timeSinceUpdate.inSeconds < 3) {
        // Si el orden de Firestore NO es el esperado (todavía tiene el orden antiguo),
        // lo ignoro completamente durante la ventana de protección
        if (firestoreIds.length == _expectedOrder!.length) {
          bool matchesExpected = true;
          for (int i = 0; i < firestoreIds.length; i++) {
            if (firestoreIds[i] != _expectedOrder![i]) {
              matchesExpected = false;
              break;
            }
          }
          // Si NO coincide con el esperado, es el orden antiguo - lo ignoro
          if (!matchesExpected) {
            return; // Ignoro esta actualización de Firestore (orden antiguo)
          }
        }
        
        // Si el orden de Firestore coincide con el esperado, verifico si coincide con el local
        if (localIds.length == firestoreIds.length) {
          bool orderMatches = true;
          for (int i = 0; i < localIds.length; i++) {
            if (localIds[i] != firestoreIds[i]) {
              orderMatches = false;
              break;
            }
          }
          if (orderMatches) {
            // El orden coincide, mantengo el estado local y limpio la protección
            _lastOptimisticUpdate = null;
            _expectedOrder = null;
            return;
          }
        }
      } else {
        // Pasaron más de 3 segundos, limpio la protección
        _lastOptimisticUpdate = null;
        _expectedOrder = null;
      }
    }

    // 🔄 Si Firestore tiene menos elementos, puede ser que se borró una lista
    // Verifico si todas las listas locales están en Firestore (solo se borró una)
    final localSet = localIds.toSet();
    final firestoreSet = firestoreIds.toSet();
    
    if (firestoreIds.length < localIds.length) {
      // Si todas las listas de Firestore están en el estado local,
      // significa que solo se borró una lista, así que actualizo manteniendo el orden local
      if (firestoreSet.every((id) => localSet.contains(id))) {
        // Filtro el estado local para mantener solo las listas que están en Firestore
        final filtered = state!.where((list) {
          final id = list['id'] as String;
          return firestoreSet.contains(id);
        }).toList();
        
        // Verifico si el orden de las listas restantes coincide
        final filteredIds = filtered.map((l) => l['id'] as String).toList();
        bool orderMatches = filteredIds.length == firestoreIds.length;
        if (orderMatches) {
          for (int i = 0; i < filteredIds.length; i++) {
            if (filteredIds[i] != firestoreIds[i]) {
              orderMatches = false;
              break;
            }
          }
        }
        
        // Si el orden coincide, uso el estado local filtrado (mantiene el orden optimista)
        // Si no coincide, uso los datos de Firestore
        state = orderMatches ? filtered : lists;
        return;
      } else {
        // Si hay listas en Firestore que no están en el estado local, uso Firestore
        state = lists;
        return;
      }
    }

    // 🔄 Si tienen la misma cantidad, verifico si el orden coincide
    if (localIds.length == firestoreIds.length) {
      bool orderMatches = true;
      for (int i = 0; i < localIds.length; i++) {
        if (localIds[i] != firestoreIds[i]) {
          orderMatches = false;
          break;
        }
      }
      // Si el orden coincide EXACTAMENTE, mantengo el estado local
      // para evitar rebotes innecesarios. Solo actualizo si hay diferencias.
      if (orderMatches) {
        // No actualizo el estado si el orden ya coincide - esto previene rebotes
        return;
      }
    }
    
    // 🔄 Si Firestore tiene más elementos, puede ser que se añadió una lista nueva
    // En ese caso, verifico si todas las listas locales están en Firestore
    if (firestoreIds.length > localIds.length) {
      if (localSet.every((id) => firestoreSet.contains(id))) {
        // Todas las listas locales están en Firestore, mantengo el orden local
        // y añado las nuevas listas al final
        final newLists = lists.where((list) {
          final id = list['id'] as String;
          return !localSet.contains(id);
        }).toList();
        
        // Añado las nuevas listas al final del estado local, manteniendo el orden
        final updated = List<Map<String, dynamic>>.from(state!);
        updated.addAll(newLists);
        state = updated;
        return;
      } else {
        // Hay listas nuevas o cambios complejos, uso Firestore
        state = lists;
      }
    }
  }

  /// 🔄 Aplica un reordenamiento optimista (inmediato).
  /// 📍 Según la documentación oficial de Flutter:
  /// Cuando oldIndex < newIndex, debemos ajustar newIndex -= 1 antes de insertar
  void reorderOptimistic(int oldIndex, int newIndex) {
    final current = state;
    if (current == null) return;

    final reordered = List<Map<String, dynamic>>.from(current);
    final moved = reordered.removeAt(oldIndex);
    
    // 🔄 Calcular el índice de inserción DESPUÉS de remover
    // Según la documentación oficial, cuando oldIndex < newIndex, newIndex se refiere
    // a la posición en la lista ORIGINAL. Después de remover, debemos ajustar.
    int insertIndex = newIndex;
    if (oldIndex < newIndex) {
      insertIndex = newIndex - 1;
    }
    
    // Asegurarnos de que el índice esté dentro del rango válido después de remover
    // Si insertIndex es igual a reordered.length, significa que queremos insertar al final
    // Pero si es mayor, lo ajustamos al último índice válido
    if (insertIndex > reordered.length) {
      insertIndex = reordered.length;
    } else if (insertIndex < 0) {
      insertIndex = 0;
    }
    
    reordered.insert(insertIndex, moved);
    
    state = reordered;
    // ⏱️ Marco el timestamp y el orden esperado de la actualización optimista
    _lastOptimisticUpdate = DateTime.now();
    _expectedOrder = reordered.map((l) => l['id'] as String).toList();
  }

  /// 🗑️ Remueve una lista específica del estado local optimista
  void removeList(String listId) {
    if (state == null) return;
    
    final updated = state!.where((list) => list['id'] as String != listId).toList();
    state = updated.isEmpty ? null : updated;
  }

  /// 🔄 Limpia el override (vuelve a usar solo Firestore).
  /// ⚠️ Solo usar cuando realmente necesitemos resetear todo el estado
  void clear() {
    state = null;
  }
}

/// 🎯 Provider final que combina el stream con el estado local optimista
final userListsWithReorderProvider =
    Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final baseAsync = ref.watch(userListsStreamProvider);
  final override = ref.watch(listsOrderOverrideProvider);

  return baseAsync.when(
    data: (lists) {
      // 🔄 Si hay un estado local optimista, verifico si el orden coincide
      if (override != null) {
        final localIds = override.map((l) => l['id'] as String).toList();
        final firestoreIds = lists.map((l) => l['id'] as String).toList();
        
        // Si tienen el mismo orden y la misma cantidad, mantengo el estado local
        // Esto previene rebotes porque no hay cambio de estado
        if (localIds.length == firestoreIds.length) {
          bool orderMatches = true;
          for (int i = 0; i < localIds.length; i++) {
            if (localIds[i] != firestoreIds[i]) {
              orderMatches = false;
              break;
            }
          }
          if (orderMatches) {
            // El orden coincide exactamente, mantengo el estado local
            // NO sincronizo para evitar cualquier rebote
            return AsyncValue.data(override);
          }
        }
        
        // Si hay diferencias, sincronizo de forma inteligente
        // (pero con protección temporal para evitar rebotes)
        Future.microtask(() {
          ref.read(listsOrderOverrideProvider.notifier).syncWithFirestore(lists);
        });
        final updatedOverride = ref.read(listsOrderOverrideProvider);
        return AsyncValue.data(updatedOverride ?? lists);
      }
      
      // No hay estado local, inicializo con Firestore
      Future.microtask(() {
        ref.read(listsOrderOverrideProvider.notifier).syncWithFirestore(lists);
      });
      return AsyncValue.data(lists);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});


