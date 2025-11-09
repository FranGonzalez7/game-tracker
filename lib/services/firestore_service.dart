import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/game.dart';

/// 🔥 Servicio para hablar con Firestore
/// 📚 Maneja la wishlist y las listas personalizadas (todavía repaso las buenas prácticas)
class FirestoreService {
  FirestoreService();

  static const String _favoritesListId = 'favorites';
  static const String _wishlistListId = 'wishlist';
  static const String _myCollectionListId = 'my_collection';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🆔 Obtiene el ID del usuario actual
  String? get currentUserId => _auth.currentUser?.uid;

  /// 🔍 Verifica si hay un usuario autenticado
  bool get isAuthenticated => _auth.currentUser != null;

  // 🌟==================== WISHLIST ====================🌟

  /// ➕ Añade un juego a la wishlist del usuario
  Future<void> addToWishlist(Game game) async {
    if (!isAuthenticated) {
      throw Exception('Usuario no autenticado');
    }

    await ensureDefaultLists();
    await addGameToList(_wishlistListId, game);
  }

  /// 🗑️ Elimina un juego de la wishlist
  Future<void> removeFromWishlist(int gameId) async {
    if (!isAuthenticated) {
      throw Exception('Usuario no autenticado');
    }

    await ensureDefaultLists();
    await removeGameFromList(_wishlistListId, gameId);
  }

  /// 🌊 Obtiene todos los juegos de la wishlist del usuario
  /// 📡 Retorna un Stream con cambios en tiempo real
  Stream<List<Game>> getWishlistStream() async* {
    if (!isAuthenticated) {
      yield <Game>[];
      return;
    }

    try {
      await ensureDefaultLists();
    } catch (_) {
      // Ignoro errores aquí para que el stream no reviente si la preparación falla.
    }

    yield* getListGamesStream(_wishlistListId);
  }

  /// ❓ Verifica si un juego está en la wishlist
  Future<bool> isInWishlist(int gameId) async {
    if (!isAuthenticated) {
      return false;
    }

    await ensureDefaultLists();
    return isGameInList(_wishlistListId, gameId);
  }

  /// 📦 Obtiene todos los juegos de la wishlist (solo una vez, sin stream)
  Future<List<Game>> getWishlist() async {
    if (!isAuthenticated) {
      return [];
    }

    await ensureDefaultLists();
    return getListGames(_wishlistListId);
  }

  // 🗃️==================== LISTAS PERSONALIZADAS ====================🗃️

  /// 📂 Referencia a la colección de listas personalizadas del usuario
  CollectionReference<Map<String, dynamic>> _getListsCollection() {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('lists')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data() ?? <String, dynamic>{},
          toFirestore: (data, _) => data,
        );
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
    final currentYear = DateTime.now().year;
    final playedYearId = 'played_year_$currentYear';

    await _ensureDefaultList(
      listsRef: listsRef,
      listId: _favoritesListId,
      name: 'Mis juegos favoritos',
    );

    await _ensureDefaultList(
      listsRef: listsRef,
      listId: _myCollectionListId,
      name: 'Mi colección',
    );

    await _ensureDefaultList(
      listsRef: listsRef,
      listId: _wishlistListId,
      name: 'Wishlist',
    );

    await _ensureDefaultList(
      listsRef: listsRef,
      listId: playedYearId,
      name: 'Jugados en $currentYear',
    );

    try {
      await _migrateLegacyWishlistIfNeeded();
    } catch (error) {
      debugPrint('Error al migrar wishlist legacy: $error');
    }
  }

  /// 🌊 Stream de listas del usuario
  Stream<List<Map<String, dynamic>>> getUserListsStream() {
    if (!isAuthenticated) {
      return Stream.value(<Map<String, dynamic>>[]);
    }
    final listsRef = _getListsCollection().orderBy('createdAt', descending: true);
    return listsRef.snapshots().map((snapshot) => snapshot.docs.map((d) {
          final data = d.data();
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
  CollectionReference<Map<String, dynamic>> _getListGamesCollection(String listId) {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listId)
        .collection('games')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data() ?? <String, dynamic>{},
          toFirestore: (data, _) => data,
        );
  }

  DocumentReference<Map<String, dynamic>> _getListDocument(String listId) {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listId)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data() ?? <String, dynamic>{},
          toFirestore: (data, _) => data,
        );
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

  /// 🗑️ Elimina un juego de una lista personalizada
  Future<void> removeGameFromList(String listId, int gameId) async {
    if (!isAuthenticated) {
      throw Exception('Usuario no autenticado');
    }

    final gamesRef = _getListGamesCollection(listId);
    await gamesRef.doc(gameId.toString()).delete();

    final listRef = _getListDocument(listId);
    await listRef.update({'updatedAt': FieldValue.serverTimestamp()});
  }

  /// 🧹 Elimina todos los juegos de una lista personalizada
  Future<void> clearList(String listId) async {
    if (!isAuthenticated) {
      throw Exception('Usuario no autenticado');
    }

    final gamesRef = _getListGamesCollection(listId);
    final snapshot = await gamesRef.get();

    if (snapshot.docs.isEmpty) {
      final listRef = _getListDocument(listId);
      await listRef.update({'updatedAt': FieldValue.serverTimestamp()});
      return;
    }

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    final listRef = _getListDocument(listId);
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
        final data = doc.data();
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

  /// 📦 Obtiene los juegos de una lista (solo una vez, sin stream)
  Future<List<Game>> getListGames(String listId) async {
    if (!isAuthenticated) {
      return [];
    }

    final gamesRef = _getListGamesCollection(listId);
    final snapshot = await gamesRef.get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
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

  /// ❓ Verifica si un juego está en una lista
  Future<bool> isGameInList(String listId, int gameId) async {
    if (!isAuthenticated) {
      return false;
    }

    final gamesRef = _getListGamesCollection(listId);
    final doc = await gamesRef.doc(gameId.toString()).get();
    return doc.exists;
  }

  Future<void> _ensureDefaultList({
    required CollectionReference<Map<String, dynamic>> listsRef,
    required String listId,
    required String name,
  }) async {
    final docRef = listsRef.doc(listId);
    final snapshot = await docRef.get();
    final data = snapshot.data();

    final payload = <String, dynamic>{
      'name': name,
      'isDefault': true,
      'key': listId,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (data == null || !data.containsKey('createdAt')) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }

    await docRef.set(payload, SetOptions(merge: true));
  }

  Future<void> _migrateLegacyWishlistIfNeeded() async {
    final userId = currentUserId;
    if (userId == null) {
      return;
    }

    final newWishlistGamesRef = _getListGamesCollection(_wishlistListId);
    final hasNewData = await newWishlistGamesRef.limit(1).get();
    if (hasNewData.docs.isNotEmpty) {
      return;
    }

    final legacyWishlistRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data() ?? <String, dynamic>{},
          toFirestore: (data, _) => data,
        );
    final legacySnapshot = await legacyWishlistRef.get();

    if (legacySnapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final doc in legacySnapshot.docs) {
      final data = doc.data();
      batch.set(newWishlistGamesRef.doc(doc.id), data);
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}


