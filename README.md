# 🎮 Game Tracker

> Una app Flutter hecha con alma de Gamer para llevar un registro de los videojuegos que vas jugando, terminando o añadiendo a tus listas personalizadas. 

## ✨ Qué puedes hacer
- 🔍 Buscar juegos gracias a un backend propio que consume la API de IGDB.
- 💖 Guardar favoritos en la wishlist y organizar listas personalizadas.
- 📅 Registrar fechas de inicio y finalización de tus partidas.
- ⭐ Añadir notas y valoraciones propias para no olvidar qué sentiste.
- 🔐 Iniciar sesión con Firebase (registro e inicio de sesión con correo/contraseña).
- 🌙 Cambiar entre modo claro y oscuro cuando quieras.

## 🚀 Puesta en marcha rápida

1. **Prepara tu entorno**  
   - Instala [Flutter](https://docs.flutter.dev/get-started/install) (canal estable).  
   - Ten a mano Android Studio o Xcode según tu plataforma.

2. **Configura Firebase (una sola vez)**  
   - Crea un proyecto en la [Consola de Firebase](https://console.firebase.google.com/).  
   - Añade tus apps (Android/iOS/web) y descarga los archivos de configuración:  
     - Android: coloca `google-services.json` en `android/app/`.  
     - iOS: coloca `GoogleService-Info.plist` en `ios/Runner/`.  
   - Activa el método de autenticación *Email/Password* (Authentication ➜ Sign-in method).

3. **Levanta el backend proxy de IGDB**  
   - Ve a `server/`, copia `env.example` como `.env` y completa `TWITCH_CLIENT_ID` + `TWITCH_CLIENT_SECRET`.  
   - Instala dependencias `npm install` y arranca con `npm run dev` (por defecto en `http://localhost:3000`).

4. **Configura la app Flutter**  
   - Copia `env.example` como `.env` en la raíz y define `BACKEND_BASE_URL` apuntando al backend.  
     - Emulador Android: `http://10.0.2.2:3000`  
     - Web/desktop: `http://localhost:3000`  
     - Dispositivo físico: `http://<IP_de_tu_PC>:3000`

5. **Instala dependencias y ejecuta**  
   ```bash
   flutter pub get
   flutter run
   ```

> 💡 Si algo falla en el arranque, revisa la consola: la app avisa cuando falta la configuración de Firebase o la API key.

- `lib/models/` → Modelos como `Game` y `SavedGame` (datos puros).
- `lib/services/` → Servicios para IGDB (vía backend), Firebase, Firestore y Hive.
- `lib/providers/` → Providers de Riverpod para manejar estado y lógica.
- `lib/screens/` y `lib/widgets/` → UI modular organizada por pantallas y componentes reutilizables.
- `assets/` → Imágenes e iconos usados en la interfaz.

## 🔐 Autenticación 
- Alta y login con correo y contraseña usando Firebase Authentication.  
- Sesiones persistentes automáticamente.  
- Gestión de perfil (nombre, alias, bio y foto) desde la propia app.  
- Cierre de sesión disponible en la pestaña de configuración.

## 🧪 Consejos para pruebas rápidas
- Usa `flutter run -d chrome` para probar en web sin emulador.  
- En Android/iOS, asegúrate de tener un dispositivo/emulador con servicios de Google configurados.  
- Crea un usuario de prueba y explora la wishlist, las listas y el registro de partidas.

## 🤝 Contribuciones y feedback
Este proyecto sigue evolucionando. Si tienes sugerencias, abre un issue o envía un PR. ¡Toda idea es bienvenida mientras seguimos aprendiendo!
