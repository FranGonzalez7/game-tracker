import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

/// Provider para el servicio de Firestore
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Provider que proporciona un Stream de la wishlist del usuario
/// Se actualiza automáticamente cuando cambian los datos en Firestore
/// Reacciona a cambios en el estado de autenticación
final wishlistStreamProvider = StreamProvider<List<Game>>((ref) async* {
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
  
  // Escuchar el stream de la wishlist con manejo de errores
  try {
    await for (final games in firestoreService.getWishlistStream()) {
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

/// Provider que verifica si un juego está en la wishlist
final wishlistCheckerProvider = FutureProvider.family<bool, int>((ref, gameId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  if (!firestoreService.isAuthenticated) {
    return false;
  }
  
  return firestoreService.isInWishlist(gameId);
});

/// StateNotifier para manejar acciones de la wishlist
class WishlistNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  WishlistNotifier(this._firestoreService, this._ref) : super(const AsyncValue.data(null));

  /// Añade un juego a la wishlist
  Future<void> addToWishlist(Game game) async {
    state = const AsyncValue.loading();
    
    try {
      await _firestoreService.addToWishlist(game);
      state = const AsyncValue.data(null);
      
      // Invalidar el stream para refrescar los datos
      _ref.invalidate(wishlistStreamProvider);
      _ref.invalidate(wishlistCheckerProvider(game.id));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Elimina un juego de la wishlist
  Future<void> removeFromWishlist(int gameId) async {
    state = const AsyncValue.loading();
    
    try {
      await _firestoreService.removeFromWishlist(gameId);
      state = const AsyncValue.data(null);
      
      // Invalidar el stream para refrescar los datos
      _ref.invalidate(wishlistStreamProvider);
      _ref.invalidate(wishlistCheckerProvider(gameId));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

/// Provider para el WishlistNotifier
final wishlistNotifierProvider = StateNotifierProvider<WishlistNotifier, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return WishlistNotifier(firestoreService, ref);
});


