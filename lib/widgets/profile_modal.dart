import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_service.dart';
import '../providers/auth_provider.dart';

/// Provider para el servicio de perfil
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

/// Modal de perfil de usuario
class ProfileModal extends ConsumerStatefulWidget {
  const ProfileModal({super.key});

  /// Muestra el modal de perfil
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ProfileModal(),
    );
  }

  @override
  ConsumerState<ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends ConsumerState<ProfileModal> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _aliasController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _aliasController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  /// Carga los datos del perfil actual
  Future<void> _loadProfile() async {
    final authState = ref.read(authStateProvider);
    final user = authState.value;
    
    // Intentar cargar datos adicionales del perfil desde Firestore
    try {
      final profileService = ref.read(profileServiceProvider);
      final profile = await profileService.getUserProfile();
      
      if (profile != null) {
        // Cargar desde Firestore si existe
        if (profile['displayName'] != null) {
          _displayNameController.text = profile['displayName'];
        } else if (user?.displayName != null) {
          // Fallback a Firebase Auth
          _displayNameController.text = user!.displayName!;
        }
        
        if (profile['alias'] != null) {
          _aliasController.text = profile['alias'];
        } else if (user != null) {
          // Placeholder si no hay alias en Firestore
          _aliasController.text = user.uid.substring(0, 8);
        }
        
        if (profile['bio'] != null) {
          _bioController.text = profile['bio'];
        }
      } else if (user != null) {
        // Si no hay perfil en Firestore, usar datos de Firebase Auth
        _displayNameController.text = user.displayName ?? '';
        _aliasController.text = user.uid.substring(0, 8);
      }
    } catch (e) {
      // Ignorar errores al cargar perfil
      if (user != null) {
        _displayNameController.text = user.displayName ?? '';
        _aliasController.text = user.uid.substring(0, 8);
      }
    }
  }

  /// Muestra un diálogo para seleccionar la fuente de la imagen
  Future<void> _pickImage() async {
    if (!mounted) return;
    
    // Mostrar diálogo para elegir entre cámara o galería
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    // Si el usuario canceló o no seleccionó nada, salir
    if (source == null) return;

    // Procesar la imagen seleccionada
    await _processImage(source);
  }

  /// Procesa la imagen seleccionada desde la fuente especificada
  Future<void> _processImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Guarda los cambios del perfil
  Future<void> _saveProfile() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final profileService = ref.read(profileServiceProvider);
      final authState = ref.read(authStateProvider);
      final user = authState.value;

      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Subir foto si hay una nueva seleccionada
      if (_selectedImage != null) {
        await profileService.uploadProfilePhoto(_selectedImage!);
      }

      // Actualizar nombre de visualización en Firebase Auth
      if (_displayNameController.text.isNotEmpty) {
        await user.updateDisplayName(_displayNameController.text);
        await user.reload();
      }

      // Actualizar datos adicionales en Firestore
      await profileService.updateProfile(
        displayName: _displayNameController.text.isEmpty ? null : _displayNameController.text,
        alias: _aliasController.text.isEmpty ? null : _aliasController.text,
        bio: _bioController.text.isEmpty ? null : _bioController.text,
      );

      // Refrescar el estado de autenticación
      ref.invalidate(authStateProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.95,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF8B00FF),
            width: 3,
          ),
        ),
        child: authState.when(
          data: (user) {
            if (user == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B00FF).withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Mi Perfil',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF8B00FF),
                              ) ?? const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: Color(0xFF8B00FF),
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Foto de perfil
                        Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF8B00FF),
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: _selectedImage != null
                                    ? Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      )
                                    : user.photoURL != null
                                        ? CachedNetworkImage(
                                            imageUrl: user.photoURL!,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                              child: const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) => Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                            ),
                                          )
                                        : Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                          ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B00FF),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.surface,
                                    width: 3,
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: _pickImage,
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Nombre de visualización
                        TextField(
                          controller: _displayNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            hintText: 'Tu nombre',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Alias
                        TextField(
                          controller: _aliasController,
                          decoration: const InputDecoration(
                            labelText: 'Alias',
                            hintText: 'Tu alias único',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Bio
                        TextField(
                          controller: _bioController,
                          decoration: const InputDecoration(
                            labelText: 'Bio',
                            hintText: 'Cuéntanos sobre ti...',
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),

                        // Botón de guardar
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF8B00FF),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Guardar Cambios',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => const Center(
            child: Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
  }
}

