import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// Provider que proporciona una instancia única del servicio de autenticación
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider que escucha los cambios en el estado de autenticación
/// Retorna el usuario actual si está autenticado, o null si no lo está
/// Maneja errores internos de Firebase Auth para evitar crashes
final authStateProvider = StreamProvider<User?>((ref) async* {
  final authService = ref.watch(authServiceProvider);
  
  // Emite el usuario actual primero (si existe)
  try {
    final currentUser = authService.currentUser;
    yield currentUser;
  } catch (e) {
    debugPrint('Error al obtener usuario actual: $e');
    yield null;
  }
  
  // Luego escucha cambios
  await for (final user in authService.authStateChanges) {
    try {
      yield user;
    } catch (e) {
      // Captura errores internos de Firebase Auth como el cast de PigeonUserDetails
      debugPrint('Error al procesar usuario en stream: $e');
      yield null;
    }
  }
});


