# Configuración de Variables de Entorno

## Pasos para configurar la API Key de RAWG

### 1. Instalar dependencias

Ejecuta el siguiente comando para instalar `flutter_dotenv`:

```bash
flutter pub get
```

### 2. Crear archivo .env

Crea un archivo `.env` en la raíz del proyecto (al mismo nivel que `pubspec.yaml`) con el siguiente contenido:

```
RAWG_API_KEY=tu_api_key_aquí
```

**IMPORTANTE**: Reemplaza `tu_api_key_aquí` con tu API key real de RAWG.

### 3. Verificar que .env está en .gitignore

El archivo `.env` ya está añadido al `.gitignore`, por lo que no se subirá al repositorio.

### 4. Probar la aplicación

Ejecuta la aplicación y verifica que funciona correctamente cargando la API key desde el archivo `.env`.

---

## Limpieza del Historial de Git

**ADVERTENCIA**: Estos pasos modificarán el historial de Git. Asegúrate de hacer un backup antes de continuar.

### Opción 1: Usando git filter-repo (Recomendado)

1. Instala `git-filter-repo`:
   ```bash
   # Windows (con pip)
   pip install git-filter-repo
   
   # macOS
   brew install git-filter-repo
   
   # Linux
   sudo apt install git-filter-repo
   ```

2. Elimina la API key del historial:
   ```bash
   git filter-repo --path lib/config/api_config.dart --invert-paths
   git filter-repo --replace-text <(echo "0b98eaa93e43454193320ea18051ea79==>RAWG_API_KEY_REMOVED")
   ```

3. Fuerza la actualización en GitHub:
   ```bash
   git push origin --force --all
   git push origin --force --tags
   ```

### Opción 2: Usando BFG Repo-Cleaner

1. Descarga BFG Repo-Cleaner desde: https://rtyley.github.io/bfg-repo-cleaner/

2. Crea un archivo `replacements.txt` con:
   ```
   0b98eaa93e43454193320ea18051ea79==>RAWG_API_KEY_REMOVED
   ```

3. Ejecuta BFG:
   ```bash
   java -jar bfg.jar --replace-text replacements.txt
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   ```

4. Fuerza la actualización:
   ```bash
   git push origin --force --all
   ```

### Opción 3: Recrear el repositorio (Más simple pero pierdes historial)

Si no necesitas mantener el historial completo:

1. Crea un nuevo repositorio en GitHub
2. Elimina el `.git` local:
   ```bash
   rm -rf .git
   ```
3. Inicializa un nuevo repositorio:
   ```bash
   git init
   git add .
   git commit -m "Initial commit with secure API key configuration"
   git remote add origin <url-del-nuevo-repo>
   git push -u origin main
   ```

### Importante: Revocar la API Key antigua

**CRÍTICO**: Después de limpiar el historial, revoca la API key expuesta y crea una nueva:

1. Ve a https://rawg.io/apidocs
2. Accede a tu cuenta
3. Revoca la API key expuesta (`0b98eaa93e43454193320ea18051ea79`)
4. Genera una nueva API key
5. Actualiza el archivo `.env` con la nueva clave

---

## Verificación

Después de completar los pasos:

1. Verifica que `.env` no está en el repositorio:
   ```bash
   git status
   git ls-files | grep .env
   ```
   (No debería aparecer nada)

2. Verifica que la API key no está en el código:
   ```bash
   git grep "0b98eaa93e43454193320ea18051ea79"
   ```
   (No debería encontrar nada)

3. Verifica que la app funciona:
   ```bash
   flutter run
   ```


