# Instrucciones de Configuración

## Pasos para ejecutar el proyecto

1. **Obtener una API Key de RAWG.io**
   - Visita https://rawg.io/apidocs
   - Haz clic en "Get API Key" o "Sign Up"
   - Completa el formulario de registro
   - **Nota importante**: Cuando te pida una URL, puedes usar cualquiera de estas opciones:
     - `http://localhost` (para desarrollo)
     - `https://github.com/tu-usuario/game_tracker` (si tienes el proyecto en GitHub)
     - `https://example.com` (URL temporal para desarrollo)
   - Una vez registrado, ve a tu panel de usuario y copia tu API key

2. **Configurar la API Key**
   - Abre el archivo `lib/config/api_config.dart`
   - Reemplaza `YOUR_API_KEY_HERE` con tu API key real:
   ```dart
   static const String rawgApiKey = 'tu_api_key_aqui';
   ```

3. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

4. **Generar código de Hive (opcional)**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
   Nota: El archivo `saved_game.g.dart` ya está incluido, pero puedes regenerarlo si es necesario.

5. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## Notas

- La aplicación funciona sin conexión a internet usando datos dummy si la API falla
- Los juegos guardados se almacenan localmente usando Hive
- No se requiere autenticación ni backend
- Compatible con Android e iOS

