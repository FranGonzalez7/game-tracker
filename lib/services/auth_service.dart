import 'package:firebase_auth/firebase_auth.dart';

/// Servicio de autenticación con Firebase
/// Maneja el registro, inicio de sesión y cierre de sesión de usuarios
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtiene el usuario actualmente autenticado
  User? get currentUser => _auth.currentUser;

  /// Stream que emite cambios en el estado de autenticación
  /// Útil para escuchar cuando un usuario inicia o cierra sesión
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Registra un nuevo usuario con correo y contraseña
  /// Retorna el User creado si el registro es exitoso
  /// Lanza una excepción si hay un error
  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Convertir errores de Firebase a mensajes más amigables
      throw _handleAuthException(e);
    }
  }

  /// Inicia sesión con correo y contraseña
  /// Retorna el User si el inicio de sesión es exitoso
  /// Lanza una excepción si hay un error
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Convertir errores de Firebase a mensajes más amigables
      throw _handleAuthException(e);
    }
  }

  /// Cierra la sesión del usuario actual
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Convierte excepciones de Firebase Auth a mensajes de error legibles en español
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña es demasiado débil';
      case 'email-already-in-use':
        return 'Este correo electrónico ya está registrado';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'user-not-found':
        return 'No existe una cuenta con este correo electrónico';
      case 'wrong-password':
        return 'La contraseña es incorrecta';
      case 'too-many-requests':
        return 'Demasiados intentos. Por favor, inténtalo más tarde';
      case 'operation-not-allowed':
        return 'Esta operación no está permitida';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet';
      default:
        return 'Error de autenticación: ${e.message ?? "Error desconocido"}';
    }
  }
}


