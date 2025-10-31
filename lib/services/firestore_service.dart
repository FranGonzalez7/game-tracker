import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game.dart';

/// Servicio para interactuar con Firestore
/// Maneja las operaciones de Wishlist y listas personalizadas
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtiene el ID del usuario actual
  String? get currentUserId => _auth.currentUser?.uid;

  /// Verifica si hay un usuario autenticado
  bool get isAuthenticated => _auth.currentUser != null;

  // ==================== WISHLIST ====================

  /// Obtiene la referencia a la colección de wishlist del usuario
  CollectionReference _getWishlistCollection() {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    return _firestore.collection('users').doc(userId).collection('wishlist');
  }

  /// Añade un juego a la wishlist del usuario
  Future<void> addToWishlist(Game game) async {
    if (!isAuthenticated) {
      throw Exception('Usuario no autenticado');
    }

    final wishlistRef = _getWishlistCollection();
    
    await wishlistRef.doc(game.id.toString()).set({
      'gameId': game.id,
      'name': game.name,
      'backgroundImage': game.backgroundImage,
      'rating': game.rating,
      'released': game.released,
      'platforms': game.platforms,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Elimina un juego de la wishlist
  Future<void> removeFromWishlist(int gameId) async {
    if (!isAuthenticated) {
      throw Exception('Usuario no autenticado');
    }

    final wishlistRef = _getWishlistCollection();
    await wishlistRef.doc(gameId.toString()).delete();
  }

  /// Obtiene todos los juegos de la wishlist del usuario
  /// Retorna un Stream que emite cambios en tiempo real
  Stream<List<Game>> getWishlistStream() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }

    final wishlistRef = _getWishlistCollection();
    
    return wishlistRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Game(
          id: data['gameId'] as int,
          name: data['name'] as String,
          backgroundImage: data['backgroundImage'] as String?,
          rating: (data['rating'] as num?)?.toDouble(),
          released: data['released'] as String?,
          platforms: data['platforms'] != null
              ? List<String>.from(data['platforms'] as List)
              : null,
        );
      }).toList();
    });
  }

  /// Verifica si un juego está en la wishlist
  Future<bool> isInWishlist(int gameId) async {
    if (!isAuthenticated) {
      return false;
    }

    final wishlistRef = _getWishlistCollection();
    final doc = await wishlistRef.doc(gameId.toString()).get();
    return doc.exists;
  }

  /// Obtiene todos los juegos de la wishlist (una sola vez, sin stream)
  Future<List<Game>> getWishlist() async {
    if (!isAuthenticated) {
      return [];
    }

    final wishlistRef = _getWishlistCollection();
    final snapshot = await wishlistRef.get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Game(
        id: data['gameId'] as int,
        name: data['name'] as String,
        backgroundImage: data['backgroundImage'] as String?,
        rating: (data['rating'] as num?)?.toDouble(),
        released: data['released'] as String?,
        platforms: data['platforms'] != null
            ? List<String>.from(data['platforms'] as List)
            : null,
      );
    }).toList();
  }
}

