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
    debugPrint('Firebase inicializado correctamente');
  } catch (e, stackTrace) {
    // Si Firebase no está configurado, mostrar error detallado
    debugPrint('Error al inicializar Firebase: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continuar ejecutando pero mostrar error en la UI
  }
  
  // Initialize storage service
  try {
    final storageService = StorageService();
    await storageService.init();
  } catch (e) {
    debugPrint('Error al inicializar StorageService: $e');
  }
  
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

    // Paleta de colores basada en la captura de Stitch
    // backgroundColor: #101922 (fondo principal)
    // fondo de tarjetas (modo lista): #17212F
    // fondo barra búsqueda: #233648
    // accentButton: #137FEC (azul)
    
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF137FEC), // Azul
      brightness: Brightness.light,
    );

    // ColorScheme personalizado para modo oscuro basado en la captura
    final darkColorScheme = ColorScheme(
      brightness: Brightness.dark,
      // Color primario (azul)
      primary: const Color(0xFF137FEC),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF137FEC).withOpacity(0.2),
      onPrimaryContainer: const Color(0xFF137FEC),
      
      // Color secundario (variación del azul)
      secondary: const Color(0xFF137FEC).withOpacity(0.8),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFF137FEC).withOpacity(0.15),
      onSecondaryContainer: const Color(0xFF137FEC),
      
      // Color terciario
      tertiary: const Color(0xFF4CAF50), // Verde para estados de éxito
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFF4CAF50).withOpacity(0.2),
      onTertiaryContainer: const Color(0xFF4CAF50),
      
      // Colores de error
      error: Colors.red,
      onError: Colors.white,
      errorContainer: Colors.red.withOpacity(0.2),
      onErrorContainer: Colors.red,
      
      // Fondo principal (#101922)
      surface: const Color(0xFF101922),
      onSurface: Colors.white,
      
      // Superficie elevada - fondo de tarjetas (#17212F)
      surfaceContainerHighest: const Color(0xFF17212F),
      surfaceContainerHigh: const Color(0xFF17212F),
      surfaceContainer: const Color(0xFF17212F),
      surfaceContainerLow: const Color(0xFF141D2A),
      surfaceContainerLowest: const Color(0xFF101922),
      onSurfaceVariant: Colors.white.withOpacity(0.7), // Gris claro para texto secundario
      
      // Fondo
      background: const Color(0xFF101922),
      onBackground: Colors.white,
      
      // Outline
      outline: Colors.white.withOpacity(0.2),
      outlineVariant: Colors.white.withOpacity(0.1),
      
      // Shadow y scrim
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Colors.white,
      onInverseSurface: const Color(0xFF101922),
      inversePrimary: const Color(0xFF137FEC),
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
        scaffoldBackgroundColor: darkColorScheme.background,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: darkColorScheme.surfaceContainerHighest,
          surfaceTintColor: Colors.transparent,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: darkColorScheme.onBackground,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: darkColorScheme.primary,
            foregroundColor: darkColorScheme.onPrimary,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(
              color: darkColorScheme.primary,
              width: 2,
            ),
            foregroundColor: darkColorScheme.primary,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF233648), // fondo barra búsqueda
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
              color: darkColorScheme.primary,
            ),
          ),
          hintStyle: TextStyle(
            color: darkColorScheme.onSurfaceVariant,
          ),
          labelStyle: TextStyle(
            color: darkColorScheme.onSurfaceVariant,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.transparent,
          selectedColor: darkColorScheme.primary,
          disabledColor: Colors.transparent,
          labelStyle: TextStyle(
            color: darkColorScheme.onBackground,
          ),
          secondaryLabelStyle: TextStyle(
            color: darkColorScheme.onPrimary,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide.none,
          ),
        ),
        listTileTheme: ListTileThemeData(
          textColor: darkColorScheme.onBackground,
          iconColor: darkColorScheme.primary,
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

