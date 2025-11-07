import 'package:firebase_auth/firebase_auth.dart';

/// 🔐 Servicio de autenticación con Firebase
/// 👩‍💻 Maneja registro, inicio y cierre de sesión (aún aprendo a manejar todos los errores)
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 👀 Obtiene el usuario actualmente autenticado
  User? get currentUser => _auth.currentUser;

  /// 📡 Stream que emite cambios en el estado de autenticación
  /// 👂 Útil para saber cuando alguien inicia o cierra sesión
  /// 🛠️ Uso `userChanges()` en vez de `authStateChanges()` para no toparme con errores raros
  Stream<User?> get authStateChanges => _auth.userChanges();

  /// 🆕 Registra un usuario con correo y contraseña
  /// 🎯 Devuelve el `User` creado si todo sale bien
  /// ⚠️ Lanza una excepción con mensaje amigable si algo falla
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
      // 📝 Convierto los errores de Firebase a mensajes más amigables
      throw _handleAuthException(e);
    }
  }

  /// 🔑 Inicia sesión con correo y contraseña
  /// 🎯 Devuelve el `User` si el login funciona
  /// ⚠️ Lanza una excepción si hay un problema
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
      // 📝 De nuevo, convierto el error para que la persona lo entienda fácil
      throw _handleAuthException(e);
    }
  }

  /// 🚪 Cierra la sesión del usuario actual
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// 💡 Convierte las excepciones de Firebase Auth a mensajes claros en español
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


