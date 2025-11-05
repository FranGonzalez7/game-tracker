# Script simplificado para limpiar la API key del historial
# Usa BFG Repo-Cleaner o git filter-branch

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "LIMPIEZA DEL HISTORIAL DE GIT" -ForegroundColor Yellow  
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Este script va a reemplazar la API key en TODO el historial de Git" -ForegroundColor Cyan
Write-Host ""

$apiKey = "0b98eaa93e43454193320ea18051ea79"
$replacement = "YOUR_API_KEY_HERE"

# Verificar si git filter-repo está disponible
$hasFilterRepo = Get-Command git-filter-repo -ErrorAction SilentlyContinue

if ($hasFilterRepo) {
    Write-Host "Usando git-filter-repo (método recomendado)..." -ForegroundColor Green
    Write-Host ""
    
    # Crear archivo de reemplazo
    $replaceFile = "$env:TEMP\replacements.txt"
    "$apiKey==>$replacement" | Out-File -FilePath $replaceFile -Encoding UTF8 -NoNewline
    
    git filter-repo --replace-text $replaceFile --force
    
    Remove-Item $replaceFile -ErrorAction SilentlyContinue
    
} else {
    Write-Host "git-filter-repo no está instalado." -ForegroundColor Yellow
    Write-Host "Usando método alternativo con git filter-branch..." -ForegroundColor Yellow
    Write-Host ""
    
    # Método con git filter-branch
    $env:FILTER_BRANCH_SQUELCH_WARNING = "1"
    
    Write-Host "Reemplazando API key en el historial (esto puede tardar)..." -ForegroundColor Green
    
    # Crear un script de reemplazo
    $replaceScript = @"
import sys
import os

file_path = 'lib/config/api_config.dart'
if os.path.exists(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if '$apiKey' in content:
        content = content.replace('$apiKey', '$replacement')
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
"@
    
    # Guardar script temporal
    $scriptFile = "$env:TEMP\replace_api_key.py"
    $replaceScript | Out-File -FilePath $scriptFile -Encoding UTF8
    
    # Verificar si Python está disponible
    $hasPython = Get-Command python -ErrorAction SilentlyContinue
    
    if ($hasPython) {
        git filter-branch -f --tree-filter "python $scriptFile" --prune-empty --tag-name-filter cat -- --all
        Remove-Item $scriptFile -ErrorAction SilentlyContinue
    } else {
        Write-Host ""
        Write-Host "Python no está disponible. Usando método PowerShell..." -ForegroundColor Yellow
        
        # Método con PowerShell directamente
        git filter-branch -f --tree-filter @"
if [ -f lib/config/api_config.dart ]; then
    sed -i 's/$apiKey/$replacement/g' lib/config/api_config.dart 2>/dev/null || powershell -Command "(Get-Content lib/config/api_config.dart) -replace '$apiKey', '$replacement' | Set-Content lib/config/api_config.dart"
fi
"@ --prune-empty --tag-name-filter cat -- --all
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "LIMPIEZA COMPLETADA" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANTE: Ahora necesitas hacer force push a GitHub:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  git push origin --force --all" -ForegroundColor Cyan
Write-Host "  git push origin --force --tags" -ForegroundColor Cyan
Write-Host ""
Write-Host "ADVERTENCIA: Esto reescribirá el historial en GitHub." -ForegroundColor Red
Write-Host "Asegúrate de que todos los colaboradores estén informados." -ForegroundColor Red
Write-Host ""

