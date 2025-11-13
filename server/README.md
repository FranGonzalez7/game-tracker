# IGDB Proxy Server

Backend ligero en Node.js que actúa como intermediario entre la aplicación Flutter y la API de IGDB. Gestiona la autenticación con Twitch y expone un endpoint seguro `/api/games`.

## Configuración rápida

1. Instala dependencias:
   ```bash
   cd server
   npm install
   ```

2. Crea un archivo `.env` (puedes copiar `env.example`) con tus credenciales de Twitch:
   ```
   TWITCH_CLIENT_ID=tu_client_id_de_twitch
   TWITCH_CLIENT_SECRET=tu_client_secret_de_twitch
   # PORT=3000
   ```

3. Ejecuta el servidor:
   ```bash
   npm run dev
   ```

   Por defecto escucha en `http://localhost:3000`.

## Endpoints

- `GET /api/games?search=<texto>`: realiza la búsqueda en IGDB y devuelve un listado simplificado con nombre, portada, géneros, plataformas, etc.
- `GET /health`: endpoint de prueba para verificar que el servidor está levantado.

## Notas

- El token de acceso de Twitch se cachea en memoria hasta que expira.
- No expongas `TWITCH_CLIENT_SECRET` en el repositorio ni en el frontend.
- Puedes desplegar este servidor en servicios como Render, Railway, Fly.io o cualquier plataforma que soporte Node.js.



