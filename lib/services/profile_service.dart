import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🪞 Servicio para manejar el perfil del usuario
/// 📸 Incluye foto y datos personales (aún aprendo a sincronizarlos bien)
class ProfileService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🆔 Obtiene el ID del usuario actual
  String? get currentUserId => _auth.currentUser?.uid;

  /// 🔍 Verifica si hay un usuario autenticado
  bool get isAuthenticated => _auth.currentUser != null;

  /// 📄 Obtiene la referencia al documento de perfil del usuario
  DocumentReference _getUserProfileRef() {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    return _firestore.collection('users').doc(userId);
  }

  /// 📂 Obtiene la referencia base del directorio de fotos del usuario
  Reference _getProfilePhotosDirRef() {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    return _storage.ref().child('profiles/$userId');
  }

  /// ☁️ Sube una foto de perfil a Firebase Storage con nombre versionado
  /// 🧹 También borra la foto anterior si existía (para no dejar archivos sueltos)
  Future<String> uploadProfilePhoto(File photoFile) async {
    if (!isAuthenticated) {
      throw Exception('Usuario no autenticado');
    }

    try {
      // 🗂️ Construyo una ruta nueva con timestamp
      final photosDirRef = _getProfilePhotosDirRef();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = 'avatar_$timestamp.jpg';
      final newPhotoRef = photosDirRef.child(newPath);

      // 🧾 Metadatos básicos
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=3600',
      );

      // ⬆️ Subo el archivo
      await newPhotoRef.putFile(photoFile, metadata);
      final downloadUrl = await newPhotoRef.getDownloadURL();

      // 🧹 Intento borrar la imagen anterior si todavía está en Storage
      try {
        final snap = await _getUserProfileRef().get();
        if (snap.exists) {
          final data = snap.data() as Map<String, dynamic>?;
          final previousPath = data?['photoPath'] as String?;
          if (previousPath != null && previousPath.isNotEmpty) {
            await photosDirRef.child(previousPath).delete();
          } else {
            // 🕰️ Compatibilidad con la versión anterior (archivo suelto en la raíz)
            final legacyRef = _storage.ref().child('profiles/${currentUserId}.jpg');
            await legacyRef.delete();
          }
        }
      } catch (_) {
        // Ignorar fallos al borrar; no es crítico
      }

      // 💾 Guardo la URL y la ruta en Firestore
      await _getUserProfileRef().set({
        'photoUrl': downloadUrl,
        'photoPath': newPath,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 🔄 Actualizo la URL en Firebase Auth para mantener todo alineado
      await _auth.currentUser?.updatePhotoURL(downloadUrl);
      await _auth.currentUser?.reload();

      return downloadUrl;
    } catch (e) {
      throw Exception('Error al subir foto de perfil: $e');
    }
  }

  /// 📝 Actualiza los datos del perfil del usuario
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? alias,
    String? bio,
  }) async {
    if (!isAuthenticated) {
      throw Exception('Usuario no autenticado');
    }

    try {
      final data = <String, dynamic>{};
      if (firstName != null) data['firstName'] = firstName;
      if (lastName != null) data['lastName'] = lastName;
      final fullName = [
        if (firstName != null && firstName.trim().isNotEmpty) firstName.trim(),
        if (lastName != null && lastName.trim().isNotEmpty) lastName.trim(),
      ].join(' ').trim();
      if (fullName.isNotEmpty) {
        data['displayName'] = fullName;
      }
      if (alias != null) data['alias'] = alias;
      if (bio != null) data['bio'] = bio;
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _getUserProfileRef().set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error al actualizar perfil: $e');
    }
  }

  /// 🔍 Obtiene el perfil del usuario
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isAuthenticated) {
      return null;
    }

    try {
      final doc = await _getUserProfileRef().get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener perfil: $e');
    }
  }

  /// 🌊 Obtiene un stream del perfil del usuario
  Stream<Map<String, dynamic>?> getUserProfileStream() {
    if (!isAuthenticated) {
      return Stream.value(null);
    }

    return _getUserProfileRef().snapshots().map((doc) {
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    });
  }
}

