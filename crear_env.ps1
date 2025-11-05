# Script para crear el archivo .env en Windows PowerShell
# Ejecuta este script para crear automáticamente el archivo .env

Write-Host "Creando archivo .env..." -ForegroundColor Green

# Lee la API key actual del código (para referencia)
$apiKey = "0b98eaa93e43454193320ea18051ea79"

# Crea el contenido del archivo .env
$envContent = "RAWG_API_KEY=$apiKey"

# Escribe el archivo .env
$envContent | Out-File -FilePath ".env" -Encoding utf8 -NoNewline

Write-Host "Archivo .env creado exitosamente!" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANTE: Por seguridad, se recomienda:" -ForegroundColor Yellow
Write-Host "1. Revocar la API key actual en https://rawg.io/apidocs" -ForegroundColor Yellow
Write-Host "2. Generar una nueva API key" -ForegroundColor Yellow
Write-Host "3. Actualizar el archivo .env con la nueva clave" -ForegroundColor Yellow
Write-Host ""
Write-Host "El archivo .env ya está en .gitignore y no se subirá al repositorio." -ForegroundColor Cyan

