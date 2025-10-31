import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/storage_service.dart';
import 'screens/main_screen.dart';
import 'screens/auth_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';

/// Main entry point of the Game Tracker app
/// Initializes Firebase, Hive storage and sets up Material 3 theme
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with platform-specific options
  // These options are generated automatically by FlutterFire CLI
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Si Firebase no está configurado, se mostrará un error
    // Nota: Ejecuta 'flutterfire configure' para generar firebase_options.dart
    debugPrint('Error al inicializar Firebase: $e');
  }
  
  // Initialize storage service
  final storageService = StorageService();
  await storageService.init();
  
  runApp(
    const ProviderScope(
      child: GameTrackerApp(),
    ),
  );
}

/// Root widget of the application
/// Configures Material 3 theme and sets up the main screen
class GameTrackerApp extends ConsumerWidget {
  const GameTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.purple,
      brightness: Brightness.light,
    );

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.purple,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Game Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              width: 2,
              color: lightColorScheme.primary,
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              width: 2,
              color: darkColorScheme.primary,
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

/// Widget wrapper que determina qué pantalla mostrar según el estado de autenticación
/// Muestra la pantalla de autenticación si el usuario no está logueado,
/// o la pantalla principal si está autenticado
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        // Si hay un usuario autenticado, mostrar la pantalla principal
        if (user != null) {
          return const MainScreen();
        }
        // Si no hay usuario, mostrar la pantalla de autenticación
        return const AuthScreen();
      },
      loading: () {
        // Mostrar un indicador de carga mientras se verifica el estado de autenticación
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
      error: (error, stack) {
        // Si hay un error, mostrar la pantalla de autenticación
        // y loguear el error para debugging
        debugPrint('Error en AuthWrapper: $error');
        return const AuthScreen();
      },
    );
  }
}

