import cors from 'cors';
import dotenv from 'dotenv';
import express from 'express';
import fetch from 'node-fetch';

dotenv.config();

const app = express();
const PORT = process.env.PORT ?? 3000;
const TWITCH_CLIENT_ID = process.env.TWITCH_CLIENT_ID;
const TWITCH_CLIENT_SECRET = process.env.TWITCH_CLIENT_SECRET;

if (!TWITCH_CLIENT_ID || !TWITCH_CLIENT_SECRET) {
  throw new Error(
    'Las variables TWITCH_CLIENT_ID y TWITCH_CLIENT_SECRET son obligatorias. ' +
      'Crea un archivo .env en la carpeta server con ambas credenciales.',
  );
}

app.use(cors());
app.use(express.json());

let cachedToken = null;
let tokenExpiresAt = 0;

async function getAccessToken() {
  const now = Date.now();
  if (cachedToken && tokenExpiresAt > now) {
    return cachedToken;
  }

  const params = new URLSearchParams({
    client_id: TWITCH_CLIENT_ID,
    client_secret: TWITCH_CLIENT_SECRET,
    grant_type: 'client_credentials',
  });

  const response = await fetch(`https://id.twitch.tv/oauth2/token?${params.toString()}`, {
    method: 'POST',
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Error obteniendo token de Twitch: ${response.status} ${errorText}`);
  }

  const data = await response.json();
  cachedToken = data.access_token;
  tokenExpiresAt = now + (data.expires_in - 60) * 1000; // renuevo un minuto antes de que expire
  return cachedToken;
}

function buildCoverUrl(imageId) {
  return imageId ? `https://images.igdb.com/igdb/image/upload/t_cover_big/${imageId}.jpg` : null;
}

app.get('/api/games', async (req, res) => {
  try {
    const search = req.query.search?.toString().trim();
    if (!search) {
      return res.status(400).json({ error: 'El parámetro search es obligatorio' });
    }

    const accessToken = await getAccessToken();

    const query = `
      search "${search.replace(/"/g, '\\"')}";
      fields
        id,
        name,
        summary,
        first_release_date,
        total_rating,
        total_rating_count,
        cover.image_id,
        genres.name,
        platforms.name;
      limit 50;
    `;

    const igdbResponse = await fetch('https://api.igdb.com/v4/games', {
      method: 'POST',
      headers: {
        'Client-ID': TWITCH_CLIENT_ID,
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'text/plain',
      },
      body: query,
    });

    if (!igdbResponse.ok) {
      const errorText = await igdbResponse.text();
      return res
        .status(igdbResponse.status)
        .json({ error: `Error al consultar IGDB: ${igdbResponse.status} ${errorText}` });
    }

    const data = await igdbResponse.json();
    
    // 📊 Ordeno por popularidad usando total_rating_count (más calificaciones = más popular)
    // También considero el rating para desempatar
    const sortedData = [...data].sort((a, b) => {
      const countA = a.total_rating_count ?? 0;
      const countB = b.total_rating_count ?? 0;
      const ratingA = a.total_rating ?? 0;
      const ratingB = b.total_rating ?? 0;
      
      // Primero ordeno por número de calificaciones (popularidad)
      if (countB !== countA) {
        return countB - countA;
      }
      // Si tienen el mismo número de calificaciones, ordeno por rating
      return ratingB - ratingA;
    });
    
    const mapped = sortedData.slice(0, 20).map((game) => {
      const releaseDate = typeof game.first_release_date === 'number'
        ? new Date(game.first_release_date * 1000).toISOString().split('T')[0]
        : null;

      const rating =
        typeof game.total_rating === 'number'
          ? doubleToFixed(Math.min(5, Math.max(0, game.total_rating / 20)))
          : null;

      return {
        id: game.id,
        name: game.name,
        summary: game.summary ?? null,
        released: releaseDate,
        rating,
        background_image: buildCoverUrl(game.cover?.image_id),
        platforms: (game.platforms ?? [])
          .map((platform) => platform?.name)
          .filter(Boolean),
        genres: (game.genres ?? [])
          .map((genre) => genre?.name)
          .filter(Boolean),
      };
    });

    res.json(mapped);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message ?? 'Error interno del servidor' });
  }
});

function doubleToFixed(value) {
  return Math.round(value * 10) / 10;
}

app.get('/api/latest-releases', async (req, res) => {
  try {
    const accessToken = await getAccessToken();

    // 📅 Calculo la fecha de hace 6 meses (en segundos Unix)
    const now = new Date();
    const sixMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 6, now.getDate());
    const sixMonthsAgoTimestamp = Math.floor(sixMonthsAgo.getTime() / 1000);

    const query = `
      fields
        id,
        name,
        summary,
        first_release_date,
        total_rating,
        total_rating_count,
        cover.image_id,
        genres.name,
        platforms.name;
      where first_release_date >= ${sixMonthsAgoTimestamp} & first_release_date <= ${Math.floor(now.getTime() / 1000)} & total_rating_count > 5;
      sort total_rating_count desc;
      limit 50;
    `;

    const igdbResponse = await fetch('https://api.igdb.com/v4/games', {
      method: 'POST',
      headers: {
        'Client-ID': TWITCH_CLIENT_ID,
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'text/plain',
      },
      body: query,
    });

    if (!igdbResponse.ok) {
      const errorText = await igdbResponse.text();
      return res
        .status(igdbResponse.status)
        .json({ error: `Error al consultar IGDB: ${igdbResponse.status} ${errorText}` });
    }

    const data = await igdbResponse.json();

    // 📊 Ordeno por popularidad usando total_rating_count (más calificaciones = más popular)
    // También considero el rating para desempatar
    // Filtro por popularidad mínima (al menos 5 calificaciones) y ordeno
    const sortedData = [...data]
      .filter((game) => (game.total_rating_count ?? 0) >= 5) // Filtro mínimo de popularidad
      .sort((a, b) => {
        const countA = a.total_rating_count ?? 0;
        const countB = b.total_rating_count ?? 0;
        const ratingA = a.total_rating ?? 0;
        const ratingB = b.total_rating ?? 0;
        
        // Primero ordeno por número de calificaciones (popularidad)
        if (countB !== countA) {
          return countB - countA;
        }
        // Si tienen el mismo número de calificaciones, ordeno por rating
        return ratingB - ratingA;
      })
      .slice(0, 20); // Me quedo con los 20 más populares
    
    const mapped = sortedData.map((game) => {
      const releaseDate = typeof game.first_release_date === 'number'
        ? new Date(game.first_release_date * 1000).toISOString().split('T')[0]
        : null;

      const rating =
        typeof game.total_rating === 'number'
          ? doubleToFixed(Math.min(5, Math.max(0, game.total_rating / 20)))
          : null;

      return {
        id: game.id,
        name: game.name,
        summary: game.summary ?? null,
        released: releaseDate,
        rating,
        background_image: buildCoverUrl(game.cover?.image_id),
        platforms: (game.platforms ?? [])
          .map((platform) => platform?.name)
          .filter(Boolean),
        genres: (game.genres ?? [])
          .map((genre) => genre?.name)
          .filter(Boolean),
      };
    });

    res.json(mapped);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message ?? 'Error interno del servidor' });
  }
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(PORT, () => {
  console.log(`IGDB proxy escuchando en http://localhost:${PORT}`);
});


