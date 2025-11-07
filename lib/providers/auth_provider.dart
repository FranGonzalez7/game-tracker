import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// 🔐 Provider que entrega una instancia única del servicio de autenticación
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// 👂 Provider que escucha cambios en el estado de autenticación
/// 🙋 Devuelve el usuario actual si está logueado, o `null` si no
/// 🛡️ Intenta capturar errores internos de Firebase para que la app no se caiga
final authStateProvider = StreamProvider<User?>((ref) async* {
  try {
    // 🧪 Verifico que Firebase esté inicializado
    try {
      Firebase.app(); // ⚙️ Si Firebase no está listo, esto lanza una excepción
    } catch (e) {
      debugPrint('Firebase no está inicializado: $e');
      yield null;
      return;
    }
    
    final authService = ref.watch(authServiceProvider);
    
    // 📤 Primero emito el usuario actual (si existe)
    try {
      final currentUser = authService.currentUser;
      yield currentUser;
    } catch (e) {
      debugPrint('Error al obtener usuario actual: $e');
      yield null;
    }
    
    // 🔄 Después me quedo escuchando los cambios siguientes
    await for (final user in authService.authStateChanges) {
      try {
        yield user;
      } catch (e) {
        // 🛠️ Capturo errores raros de Firebase (como el cast de PigeonUserDetails)
        debugPrint('Error al procesar usuario en stream: $e');
        yield null;
      }
    }
  } catch (e, stackTrace) {
    debugPrint('Error en authStateProvider: $e');
    debugPrint('Stack trace: $stackTrace');
    yield null;
  }
});
