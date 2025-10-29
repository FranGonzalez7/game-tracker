# Script de verificacion de Flutter
Write-Host "=== Verificacion de Flutter ===" -ForegroundColor Cyan

# Buscar Flutter en ubicaciones comunes
$rutasComunes = @(
    "$env:USERPROFILE\AppData\Local\flutter",
    "C:\src\flutter",
    "C:\flutter",
    "$env:LOCALAPPDATA\flutter"
)

Write-Host ""
Write-Host "Buscando Flutter en ubicaciones comunes..." -ForegroundColor Yellow
$flutterEncontrado = $false

foreach ($ruta in $rutasComunes) {
    $flutterPath = Join-Path $ruta "bin\flutter.bat"
    if (Test-Path $flutterPath) {
        Write-Host "Flutter encontrado en: $ruta" -ForegroundColor Green
        $flutterEncontrado = $true
        Write-Host ""
        Write-Host "Probando ejecutar Flutter..." -ForegroundColor Yellow
        & $flutterPath --version
        break
    }
}

if ($flutterEncontrado -eq $false) {
    Write-Host ""
    Write-Host "Flutter NO encontrado en ubicaciones comunes" -ForegroundColor Red
    Write-Host ""
    Write-Host "Opciones:" -ForegroundColor Yellow
    Write-Host "1. Descarga Flutter desde: https://docs.flutter.dev/get-started/install/windows"
    Write-Host "2. Extrae Flutter en C:\src\flutter"
    Write-Host "3. Anade la carpeta \bin al PATH del sistema"
    Write-Host "4. Reinicia el terminal"
}

# Verificar proyecto
Write-Host ""
Write-Host "=== Verificacion del Proyecto ===" -ForegroundColor Cyan
$proyectoPath = Get-Location

if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "No se encontro pubspec.yaml" -ForegroundColor Red
    exit
}

Write-Host "Proyecto encontrado en: $proyectoPath" -ForegroundColor Green

# Verificar carpetas
$carpetasFaltantes = @()

if (Test-Path "android") {
    Write-Host "Carpeta android existe" -ForegroundColor Green
} else {
    Write-Host "Carpeta android NO existe" -ForegroundColor Red
    $carpetasFaltantes += "android"
}

if (Test-Path "ios") {
    Write-Host "Carpeta ios existe" -ForegroundColor Green
} else {
    Write-Host "Carpeta ios NO existe" -ForegroundColor Red
    $carpetasFaltantes += "ios"
}

if (Test-Path "lib") {
    Write-Host "Carpeta lib existe" -ForegroundColor Green
} else {
    Write-Host "Carpeta lib NO existe" -ForegroundColor Red
    $carpetasFaltantes += "lib"
}

if ($carpetasFaltantes.Count -gt 0) {
    Write-Host ""
    Write-Host "Faltan carpetas del proyecto Flutter" -ForegroundColor Yellow
    if ($flutterEncontrado) {
        Write-Host "Ejecuta: flutter create ." -ForegroundColor Cyan
    } else {
        Write-Host "Primero resuelve el problema de Flutter" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "=== Fin de la verificacion ===" -ForegroundColor Cyan

