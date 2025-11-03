import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'wishlist_provider.dart';

/// Stream de listas personalizadas del usuario
final userListsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final firestoreService = ref.watch(firestoreServiceProvider);

  if (!firestoreService.isAuthenticated) {
    yield <Map<String, dynamic>>[];
    return;
  }

  try {
    // Asegurar listas por defecto antes de escuchar
    try {
      await firestoreService.ensureDefaultLists();
    } catch (_) {}

    await for (final lists in firestoreService.getUserListsStream()) {
      yield lists;
    }
  } catch (error) {
    if (error.toString().contains('permission-denied')) {
      yield <Map<String, dynamic>>[];
      return;
    }
    rethrow;
  }
});


