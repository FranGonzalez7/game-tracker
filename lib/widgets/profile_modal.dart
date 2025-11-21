import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';

/// 🪪 Modal para editar mi perfil de usuario
class ProfileModal extends ConsumerStatefulWidget {
  const ProfileModal({super.key});

  /// 👋 Muestra el modal de perfil (lo abro cuando quiero editar mis datos)
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
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _aliasController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _setNameFallback(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return;
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (_firstNameController.text.isEmpty) {
      _firstNameController.text = parts.first;
    }
    if (parts.length > 1 && _lastNameController.text.isEmpty) {
      _lastNameController.text = parts.sublist(1).join(' ');
    }
  }

  /// 📥 Carga los datos del perfil actual (todavía me lío con tantas fuentes)
  Future<void> _loadProfile() async {
    final authState = ref.read(authStateProvider);
    final user = authState.value;
    
    // 🔎 Intento traer datos extra del perfil desde Firestore primero
    try {
      final profileService = ref.read(profileServiceProvider);
      final profile = await profileService.getUserProfile();
      
      if (profile != null) {
        // ☁️ Si existe en Firestore, uso esos datos fresquitos
        if (profile['firstName'] != null) {
          _firstNameController.text = profile['firstName'];
        }
        if (profile['lastName'] != null) {
          _lastNameController.text = profile['lastName'];
        }
        if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
          _setNameFallback(profile['displayName'] as String?);
        }
        if ((_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) &&
            user?.displayName != null) {
          _setNameFallback(user!.displayName);
        }

        if (profile['alias'] != null) {
          _aliasController.text = profile['alias'];
        } else if (user != null) {
          // 🏷️ Cuando no hay alias guardado, invento uno con el UID
          _aliasController.text = user.uid.substring(0, 8);
        }
        
        if (profile['bio'] != null) {
          _bioController.text = profile['bio'];
        }
      } else if (user != null) {
        // 🙃 Si no hay perfil en Firestore, me quedo con lo que da Firebase Auth
        _setNameFallback(user.displayName);
        _aliasController.text = user.uid.substring(0, 8);
      }
    } catch (e) {
      // 🤫 Si falla la carga, no paro todo, solo uso los datos que tenga a mano
      if (user != null) {
        _setNameFallback(user.displayName);
        _aliasController.text = user.uid.substring(0, 8);
      }
    }
  }

  /// 📸 Abre un diálogo para elegir de dónde sacar la foto
  Future<void> _pickImage() async {
    if (!mounted) return;
    
    // 📂 Saco un diálogo para que elija entre cámara o galería (¡yo siempre voy a galería!)
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

    // 🙈 Si cancela o no elige nada, pues no hago cambios
    if (source == null) return;

    // 🛠️ Si sí selecciona, proceso la imagen elegida
    await _processImage(source);
  }

  /// 🧪 Procesa la imagen seleccionada desde la fuente especificada
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

  /// 💾 Guarda los cambios del perfil (con paciencia porque sube cosas)
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

      // ☁️ Si hay foto nueva, la subo primero
      if (_selectedImage != null) {
        await profileService.uploadProfilePhoto(_selectedImage!);
      }

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final alias = _aliasController.text.trim();
      final bio = _bioController.text.trim();

      // ✏️ Luego actualizo el nombre que ve Firebase Auth
      final authDisplayName = [firstName, lastName]
          .where((value) => value.isNotEmpty)
          .join(' ')
          .trim();
      if (authDisplayName.isNotEmpty) {
        await user.updateDisplayName(authDisplayName);
        await user.reload();
      }

      // 🪄 También actualizo los datos extra en Firestore
      await profileService.updateProfile(
        firstName: firstName.isEmpty ? null : firstName,
        lastName: lastName.isEmpty ? null : lastName,
        alias: alias.isEmpty ? null : alias,
        bio: bio.isEmpty ? null : bio,
      );

      // 🔄 Finalmente refresco el estado de autenticación para que se note el cambio
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
            color: const Color(0xFF137FEC),
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
                // 🧢 Cabecera del modal (la pinto azul para que llame la atención)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF137FEC).withOpacity(0.1),
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
                                color: const Color(0xFF137FEC),
                              ) ?? const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: const Color(0xFF137FEC),
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

                // 📚 Contenido principal (aquí van todos los campos editables)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // 🤳 Foto de perfil (me hace ilusión cambiarla seguido)
                        Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF137FEC),
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
                                  color: const Color(0xFF137FEC),
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

                        // 📝 Nombre y apellidos (los manejo por separado ahora)
                        TextField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            hintText: 'Tu nombre',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Apellidos',
                            hintText: 'Tus apellidos',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 🏷️ Alias (trato de que sea único y divertido)
                        TextField(
                          controller: _aliasController,
                          decoration: const InputDecoration(
                            labelText: 'Alias',
                            hintText: 'Tu alias único',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 💬 Bio (escribo algo breve para presentarme)
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

                        // 💾 Botón de guardar (cuando está cargando se desactiva)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF137FEC),
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

