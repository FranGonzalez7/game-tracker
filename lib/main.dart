import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'services/storage_service.dart';
import 'screens/main_screen.dart';
import 'screens/auth_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';

/// 🎮 Punto de inicio de la app Game Tracker (todavía estoy aprendiendo Flutter)
/// 🚀 Aquí preparo Firebase, Hive y dejo listo el tema de Material 3
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 📦 Intento cargar las variables del archivo .env (a veces me olvido de crearlo)
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('Variables de entorno cargadas correctamente');
  } catch (e) {
    debugPrint('Error al cargar .env: $e');
    debugPrint('Asegúrate de que el archivo .env existe en la raíz del proyecto');
    // 😅 Aunque falle, dejo que siga por ahora, pero luego avisaré si falta la API key
  }
  
  // 🔌 Inicializo Firebase con las opciones específicas de la plataforma
  // 🤖 Estas opciones las genera el FlutterFire CLI (yo solo las uso tal cual)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase inicializado correctamente');
  } catch (e, stackTrace) {
    // 😖 Si Firebase no está bien configurado, quiero ver un error clarito
    debugPrint('Error al inicializar Firebase: $e');
    debugPrint('Stack trace: $stackTrace');
    // 🙈 Aun así dejo que corra para poder mostrar un mensajito en la UI
  }
  
  // 🗃️ También inicializo el servicio de almacenamiento (mejor dejarlo listo al inicio)
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

/// 🌟 Widget raíz de la aplicación
/// 🧰 Configura el tema Material 3 y abre la pantalla principal
class GameTrackerApp extends ConsumerWidget {
  const GameTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    // 🎨 Estoy usando la paleta que copié de la captura de Stitch (me encanta cómo queda)
    // 🩶 Fondo base: #101922 (así se ve como en la captura)
    // 🃏 Fondo de tarjetas en modo lista: #17212F
    // 🔍 Fondo de la barra de búsqueda: #233648
    // 🔵 Botón destacado: #137FEC
    
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF137FEC), // 🔵 Azul base que estoy usando en todo
      brightness: Brightness.light,
    );

    // 🌚 Esquema de colores modo oscuro armado a partir de la misma captura
    final darkColorScheme = ColorScheme(
      brightness: Brightness.dark,
      // 💙 Color primario (azul principal)
      primary: const Color(0xFF137FEC),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF137FEC).withOpacity(0.2),
      onPrimaryContainer: const Color(0xFF137FEC),
      
      // 💦 Color secundario (una variación más suave del azul)
      secondary: const Color(0xFF137FEC).withOpacity(0.8),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFF137FEC).withOpacity(0.15),
      onSecondaryContainer: const Color(0xFF137FEC),
      
      // 🌱 Color terciario
      tertiary: const Color(0xFF4CAF50), // 🍀 Verde para cuando algo sale bien
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFF4CAF50).withOpacity(0.2),
      onTertiaryContainer: const Color(0xFF4CAF50),
      
      // 🚨 Colores de error
      error: Colors.red,
      onError: Colors.white,
      errorContainer: Colors.red.withOpacity(0.2),
      onErrorContainer: Colors.red,
      
      // 🏠 Fondo principal (#101922) para mantener todo uniforme
      surface: const Color(0xFF101922),
      onSurface: Colors.white,
      
      // 🧱 Superficie elevada: fondo de las tarjetas (#17212F)
      surfaceContainerHighest: const Color(0xFF17212F),
      surfaceContainerHigh: const Color(0xFF17212F),
      surfaceContainer: const Color(0xFF17212F),
      surfaceContainerLow: const Color(0xFF141D2A),
      surfaceContainerLowest: const Color(0xFF101922),
      onSurfaceVariant: Colors.white.withOpacity(0.7), // ✏️ Gris clarito para texto secundario
      
      // 🌌 Fondo general (cuando no hay tarjetas ni nada)
      background: const Color(0xFF101922),
      onBackground: Colors.white,
      
      // ✨ Outline para bordes suaves
      outline: Colors.white.withOpacity(0.2),
      outlineVariant: Colors.white.withOpacity(0.1),
      
      // 🕶️ Shadow y scrim para dar sensación de profundidad
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
          fillColor: const Color(0xFF233648), // 🔍 Fondo de la barra de búsqueda
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

/// 🔐 Widget envoltorio que decide qué pantalla mostrar según el estado de autenticación
/// 🧭 Si no hay sesión muestro el login, si sí hay paso directo a la pantalla principal
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        // ✅ Si hay usuario autenticado, voy directo a la pantalla principal
        if (user != null) {
          return const MainScreen();
        }
        // 👋 Si no encuentro usuario, regreso a la pantalla de autenticación
        return const AuthScreen();
      },
      loading: () {
        // ⏳ Mientras espero la respuesta, muestro un indicador de carga sencillito
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
      error: (error, stack) {
        // ⚠️ Si algo falla, vuelvo al login y anoto el error para revisarlo luego
        debugPrint('Error en AuthWrapper: $error');
        return const AuthScreen();
      },
    );
  }
}

