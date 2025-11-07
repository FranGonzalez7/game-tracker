import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game.dart';

/// 🔥 Servicio para hablar con Firestore
/// 📚 Maneja la wishlist y las listas personalizadas (todavía repaso las buenas prácticas)
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🆔 Obtiene el ID del usuario actual
  String? get currentUserId => _auth.currentUser?.uid;

  /// 🔍 Verifica si hay un usuario autenticado
  bool get isAuthenticated => _auth.currentUser != null;

  // 🌟==================== WISHLIST ====================🌟

  /// 📂 Obtiene la referencia a la colección de wishlist del usuario
  CollectionReference _getWishlistCollection() {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    return _firestore.collection('users').doc(userId).collection('wishlist');
  }

  /// ➕ Añade un juego a la wishlist del usuario
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

  /// 🗑️ Elimina un juego de la wishlist
  Future<void> removeFromWishlist(int gameId) async {
    if (!isAuthenticated) {
      throw Exception('Usuario no autenticado');
    }

    final wishlistRef = _getWishlistCollection();
    await wishlistRef.doc(gameId.toString()).delete();
  }

  /// 🌊 Obtiene todos los juegos de la wishlist del usuario
  /// 📡 Retorna un Stream con cambios en tiempo real
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

  /// ❓ Verifica si un juego está en la wishlist
  Future<bool> isInWishlist(int gameId) async {
    if (!isAuthenticated) {
      return false;
    }

    final wishlistRef = _getWishlistCollection();
    final doc = await wishlistRef.doc(gameId.toString()).get();
    return doc.exists;
  }

  /// 📦 Obtiene todos los juegos de la wishlist (solo una vez, sin stream)
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

  // 🗃️==================== LISTAS PERSONALIZADAS ====================🗃️

  /// 📂 Referencia a la colección de listas personalizadas del usuario
  CollectionReference _getListsCollection() {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    return _firestore.collection('users').doc(userId).collection('lists');
  }

  /// 🆕 Crea una nueva lista con nombre
  Future<DocumentReference> createList(String name) async {
    if (!isAuthenticated) {
      throw Exception('Usuario no autenticado');
    }
    final listsRef = _getListsCollection();
    final now = FieldValue.serverTimestamp();
    return await listsRef.add({
      'name': name,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  /// 🛠️ Asegura que existan las listas predeterminadas del usuario
  Future<void> ensureDefaultLists() async {
    if (!isAuthenticated) {
      throw Exception('Usuario no autenticado');
    }

    final listsRef = _getListsCollection();
    final now = FieldValue.serverTimestamp();
    final currentYear = DateTime.now().year;

    final favoritesId = 'favorites';
    final playedYearId = 'played_year_$currentYear';

    // 🔁 Creo/actualizo con IDs fijos para evitar duplicados
    await listsRef.doc(favoritesId).set({
      'name': 'Mis juegos favoritos',
      'isDefault': true,
      'key': favoritesId,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    await listsRef.doc(playedYearId).set({
      'name': 'Jugados en $currentYear',
      'isDefault': true,
      'key': playedYearId,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  /// 🌊 Stream de listas del usuario
  Stream<List<Map<String, dynamic>>> getUserListsStream() {
    if (!isAuthenticated) {
      return Stream.value(<Map<String, dynamic>>[]);
    }
    final listsRef = _getListsCollection().orderBy('createdAt', descending: true);
    return listsRef.snapshots().map((snapshot) => snapshot.docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          return {
            'id': d.id,
            'name': data['name'] as String? ?? 'Sin nombre',
        'isDefault': data['isDefault'] as bool? ?? false,
            'createdAt': data['createdAt'],
            'updatedAt': data['updatedAt'],
          };
        }).toList());
  }

  /// 📂 Obtiene la referencia a la colección de juegos de una lista
  CollectionReference _getListGamesCollection(String listId) {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listId)
        .collection('games');
  }

  /// ➕ Añade un juego a una lista personalizada
  Future<void> addGameToList(String listId, Game game) async {
    if (!isAuthenticated) {
      throw Exception('Usuario no autenticado');
    }

    final gamesRef = _getListGamesCollection(listId);
    
    await gamesRef.doc(game.id.toString()).set({
      'gameId': game.id,
      'name': game.name,
      'backgroundImage': game.backgroundImage,
      'rating': game.rating,
      'released': game.released,
      'platforms': game.platforms,
      'addedAt': FieldValue.serverTimestamp(),
    });

    // ⏰ Actualizo el `updatedAt` de la lista para reflejar el cambio
    final listRef = _getListsCollection().doc(listId);
    await listRef.update({'updatedAt': FieldValue.serverTimestamp()});
  }

  /// 📡 Obtiene los juegos de una lista (stream)
  Stream<List<Game>> getListGamesStream(String listId) {
    if (!isAuthenticated) {
      return Stream.value([]);
    }

    final gamesRef = _getListGamesCollection(listId);
    
    return gamesRef.snapshots().map((snapshot) {
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

  /// ❓ Verifica si un juego está en una lista
  Future<bool> isGameInList(String listId, int gameId) async {
    if (!isAuthenticated) {
      return false;
    }

    final gamesRef = _getListGamesCollection(listId);
    final doc = await gamesRef.doc(gameId.toString()).get();
    return doc.exists;
  }
}


