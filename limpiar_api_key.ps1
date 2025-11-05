# Script para limpiar la API key del historial de Git
# Usa git filter-branch para reemplazar la clave en todos los commits

Write-Host "Limpiando historial de Git..." -ForegroundColor Green

$apiKey = "0b98eaa93e43454193320ea18051ea79"
$replacement = "YOUR_API_KEY_HERE"

# Crear un script temporal para el reemplazo
$scriptPath = "$env:TEMP\git_replace.ps1"
$scriptContent = @"
`$content = Get-Content `$args[0] -Raw -ErrorAction SilentlyContinue
if (`$content -and `$content -match '$apiKey') {
    `$content = `$content -replace '$apiKey', '$replacement'
    `$content | Set-Content `$args[0] -NoNewline
}
"@
$scriptContent | Out-File -FilePath $scriptPath -Encoding UTF8

try {
    # Usar git filter-branch con el script
    $env:FILTER_BRANCH_SQUELCH_WARNING = "1"
    
    Write-Host "Ejecutando git filter-branch (esto puede tardar)..." -ForegroundColor Yellow
    
    # Método alternativo: usar sed-like replacement
    git filter-branch --force --index-filter @"
git checkout-index -f -a
powershell -Command "if (Test-Path 'lib/config/api_config.dart') { (Get-Content 'lib/config/api_config.dart') -replace '$apiKey', '$replacement' | Set-Content 'lib/config/api_config.dart' -NoNewline; git add 'lib/config/api_config.dart' }"
"@ --prune-empty --tag-name-filter cat -- --all
    
    Write-Host "Limpieza completada!" -ForegroundColor Green
    Write-Host ""
    Write-Host "IMPORTANTE: Ahora necesitas hacer force push:" -ForegroundColor Yellow
    Write-Host "  git push origin --force --all" -ForegroundColor Cyan
    Write-Host "  git push origin --force --tags" -ForegroundColor Cyan
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Usando método alternativo..." -ForegroundColor Yellow
} finally {
    Remove-Item $scriptPath -ErrorAction SilentlyContinue
}

