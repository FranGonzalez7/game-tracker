# Solución de Problemas - Game Tracker

## Problema: La app no arranca

### Posibles causas y soluciones:

## 1. Flutter no está en el PATH (Error más común)

Si cuando intentas ejecutar `flutter` te sale "no se reconoce como comando", Flutter no está configurado correctamente.

### Solución A: Añadir Flutter al PATH manualmente

1. **Busca dónde está instalado Flutter:**
   - Ubicación común en Windows: `C:\src\flutter` o `C:\flutter`
   - O donde lo hayas descargado/instalado

2. **Añade Flutter al PATH:**
   - Presiona `Win + X` y selecciona "Sistema"
   - Clic en "Configuración avanzada del sistema"
   - Clic en "Variables de entorno"
   - En "Variables del sistema", busca "Path" y haz clic en "Editar"
   - Clic en "Nuevo" y añade la ruta a Flutter, por ejemplo: `C:\src\flutter\bin`
   - Clic en "Aceptar" en todas las ventanas
   - **Reinicia el terminal/PowerShell** para que los cambios surtan efecto

3. **Verifica la instalación:**
   ```powershell
   flutter --version
   flutter doctor
   ```

### Solución B: Usar Flutter desde VS Code o Android Studio

Si tienes Flutter instalado pero no está en el PATH:
- Abre el proyecto en **VS Code** con la extensión de Flutter instalada
- O abre el proyecto en **Android Studio**
- Estos IDEs pueden encontrar Flutter automáticamente

## 2. Proyecto Flutter incompleto

Si faltan las carpetas `android/` o `ios/`, necesitas inicializar el proyecto:

### Desde el directorio del proyecto:

```powershell
cd C:\development\game_tracker2
flutter create .
```

**Importante:** Esto regenerará algunos archivos, pero tus archivos en `lib/` estarán seguros.

## 3. Dependencias no instaladas

Después de configurar Flutter, instala las dependencias:

```powershell
cd C:\development\game_tracker2
flutter pub get
```

## 4. Verificar que todo está bien

Ejecuta estos comandos en orden:

```powershell
# 1. Verificar Flutter
flutter doctor

# 2. Instalar dependencias
flutter pub get

# 3. Ejecutar la app
flutter run
```

## 5. Si aún no funciona - Recrear el proyecto completo

Si nada funciona, puedes recrear el proyecto:

```powershell
# Desde el directorio padre
cd C:\development

# Renombra el proyecto actual (backup)
Rename-Item game_tracker2 game_tracker2_backup

# Crea nuevo proyecto Flutter
flutter create game_tracker2

# Copia tus archivos
Copy-Item game_tracker2_backup\lib\* game_tracker2\lib\ -Recurse
Copy-Item game_tracker2_backup\pubspec.yaml game_tracker2\pubspec.yaml

# Instala dependencias
cd game_tracker2
flutter pub get
```

## Pasos rápidos de verificación:

1. ✅ ¿Flutter está instalado? → `where flutter` (debe mostrar una ruta)
2. ✅ ¿Flutter está actualizado? → `flutter --version` (debe ser 3.22+)
3. ✅ ¿Hay carpetas android/ e ios/? → Si no, ejecuta `flutter create .`
4. ✅ ¿Están instaladas las dependencias? → `flutter pub get`
5. ✅ ¿Hay un dispositivo/emulador conectado? → `flutter devices`

## Si el problema persiste

Comparte el mensaje de error completo que aparece cuando intentas ejecutar:
- `flutter doctor -v`
- `flutter pub get`
- `flutter run`


