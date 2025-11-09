# Instrucciones de Configuración

## Pasos para ejecutar el proyecto

1. **Crear una aplicación de Twitch**
   - Ve a [https://dev.twitch.tv/console/apps](https://dev.twitch.tv/console/apps) y crea una nueva aplicación.
   - Copia el `Client ID` y genera un `Client Secret`.
   - No compartas estas credenciales públicamente.

2. **Configurar el backend Node**
   - Entra a la carpeta `server/`.
   - Copia `env.example` como `.env` y completa `TWITCH_CLIENT_ID`, `TWITCH_CLIENT_SECRET` y opcionalmente `PORT`.
   - Instala dependencias y levanta el servidor:
     ```bash
     cd server
     npm install
     npm run dev
     ```
   - Por defecto estará disponible en `http://localhost:3000`.

3. **Configurar variables para Flutter**
   - En la raíz del proyecto copia `env.example` como `.env`.
   - Ajusta `BACKEND_BASE_URL` apuntando al servidor que acabas de levantar (ej. `http://localhost:3000`).

4. **Instalar dependencias Flutter**
   ```bash
   flutter pub get
   ```

5. **Generar código de Hive (opcional)**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
   Nota: El archivo `saved_game.g.dart` ya está incluido, pero puedes regenerarlo si es necesario.

6. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## Notas

- El backend actúa como proxy y cachea el token de Twitch en memoria.
- La app nunca debe llamar a IGDB directamente ni contener el Client Secret.
- Los juegos guardados se almacenan localmente usando Hive.
- Compatible con Android e iOS.

