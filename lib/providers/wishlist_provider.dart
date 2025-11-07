import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

/// 🔥 Provider que entrega el servicio de Firestore
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// 🌊 Provider que ofrece un Stream de la wishlist del usuario
/// 🔁 Se actualiza solo cuando cambian los datos en Firestore
/// 👂 Reacciona a los cambios de autenticación
final wishlistStreamProvider = StreamProvider<List<Game>>((ref) async* {
  // 👂 Escucho cómo va el estado de autenticación
  final authState = ref.watch(authStateProvider);
  
  // 🤔 Reviso si hay alguien logueado
  final isAuthenticated = authState.value != null;
  
  // 🚫 Si no hay usuario, devuelvo lista vacía y me salgo
  if (!isAuthenticated) {
    yield <Game>[];
    return;
  }
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  // 🎧 Escucho el stream de la wishlist con un poco de manejo de errores
  try {
    await for (final games in firestoreService.getWishlistStream()) {
      yield games;
    }
  } catch (error) {
    // 🔐 Si falla por permisos, devuelvo lista vacía para no explotar
    if (error.toString().contains('permission-denied') || 
        error.toString().contains('The caller does not have permission')) {
      yield <Game>[];
      return;
    }
    // 🚨 Otros errores los relanzo para revisarlos
    rethrow;
  }
});

/// ❓ Provider que comprueba si un juego ya está en la wishlist
final wishlistCheckerProvider = FutureProvider.family<bool, int>((ref, gameId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  if (!firestoreService.isAuthenticated) {
    return false;
  }
  
  return firestoreService.isInWishlist(gameId);
});

/// 🧠 StateNotifier que maneja las acciones de la wishlist
class WishlistNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  WishlistNotifier(this._firestoreService, this._ref) : super(const AsyncValue.data(null));

  /// ➕ Añade un juego a la wishlist
  Future<void> addToWishlist(Game game) async {
    state = const AsyncValue.loading();
    
    try {
      await _firestoreService.addToWishlist(game);
      state = const AsyncValue.data(null);
      
      // 🔄 Invalido el stream para que los datos se refresquen
      _ref.invalidate(wishlistStreamProvider);
      _ref.invalidate(wishlistCheckerProvider(game.id));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// 🗑️ Elimina un juego de la wishlist
  Future<void> removeFromWishlist(int gameId) async {
    state = const AsyncValue.loading();
    
    try {
      await _firestoreService.removeFromWishlist(gameId);
      state = const AsyncValue.data(null);
      
      // 🔄 Invalido el stream para que se actualice la UI
      _ref.invalidate(wishlistStreamProvider);
      _ref.invalidate(wishlistCheckerProvider(gameId));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

/// 🎯 Provider que expone el `WishlistNotifier`
final wishlistNotifierProvider = StateNotifierProvider<WishlistNotifier, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return WishlistNotifier(firestoreService, ref);
});


