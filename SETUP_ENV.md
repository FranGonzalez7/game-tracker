# Configuración de Variables de Entorno

## 1. Variables para la app Flutter

La app Flutter obtiene la URL del backend proxy desde un archivo `.env` en la raíz del proyecto (al mismo nivel que `pubspec.yaml`).

1. Copia `env.example` como `.env`:
   ```
   cp env.example .env
   ```
2. Edita el archivo y ajusta la URL base de tu backend:
   ```
   BACKEND_BASE_URL=https://mi-servidor.com
   ```
   > En desarrollo puedes usar:
   > - `http://10.0.2.2:3000` si pruebas en un emulador Android (redirige al host).
   > - `http://localhost:3000` en navegador o escritorio.
   > - La IP local de tu PC (`http://192.168.x.x:3000`) si usas un dispositivo físico.

3. Verifica que `.env` está listado en `.gitignore` (ya lo está por defecto).

## 2. Variables para el backend Node (server/)

El backend necesita las credenciales de Twitch para solicitar tokens y hacer peticiones a IGDB.

1. Dentro de la carpeta `server/`, copia `env.example` como `.env`:
   ```
   cd server
   cp env.example .env
   ```
2. Completa las variables:
   ```
   TWITCH_CLIENT_ID=tu_client_id_de_twitch
   TWITCH_CLIENT_SECRET=tu_client_secret_de_twitch
   # PORT=3000
   ```
3. Asegúrate de que el archivo `.env` tampoco se suba al repo (`server/.gitignore` ya lo evita).

## 3. Resumen rápido

- `.env` (en la raíz): define `BACKEND_BASE_URL`.
- `server/.env`: guarda `TWITCH_CLIENT_ID`, `TWITCH_CLIENT_SECRET` y opcionalmente `PORT`.
- Nunca compartas ni subas el Client Secret al repositorio.

