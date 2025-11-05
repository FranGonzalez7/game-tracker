# Script para limpiar la API key del historial de Git
# Método simplificado y efectivo para Windows

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "LIMPIEZA DEL HISTORIAL DE GIT" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Este script va a:" -ForegroundColor Cyan
Write-Host "1. Reemplazar la API key en TODO el historial de Git" -ForegroundColor Cyan
Write-Host "2. Requerir un force push para actualizar GitHub" -ForegroundColor Cyan
Write-Host ""
Write-Host "ADVERTENCIA: Esto modificará el historial de Git permanentemente!" -ForegroundColor Red
Write-Host "Asegúrate de haber hecho backup antes de continuar." -ForegroundColor Red
Write-Host ""

$confirm = Read-Host "¿Deseas continuar? (s/n)"
if ($confirm -ne "s" -and $confirm -ne "S") {
    Write-Host "Operación cancelada." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "Limpiando historial..." -ForegroundColor Green

$apiKey = "0b98eaa93e43454193320ea18051ea79"
$replacement = "YOUR_API_KEY_HERE"

# Configurar variable de entorno para silenciar advertencias
$env:FILTER_BRANCH_SQUELCH_WARNING = "1"

# Crear script de reemplazo temporal
$replaceScript = @'
$file = "lib/config/api_config.dart"
if (Test-Path $file) {
    $content = Get-Content $file -Raw
    if ($content -match "0b98eaa93e43454193320ea18051ea79") {
        $content = $content -replace "0b98eaa93e43454193320ea18051ea79", "YOUR_API_KEY_HERE"
        $content | Set-Content $file -NoNewline
    }
}
'@

$scriptPath = "$env:TEMP\replace_api_key.ps1"
$replaceScript | Out-File -FilePath $scriptPath -Encoding UTF8

try {
    Write-Host "Ejecutando git filter-branch (esto puede tardar unos minutos)..." -ForegroundColor Yellow
    Write-Host ""
    
    # Usar git filter-branch con el script de PowerShell
    git filter-branch -f --tree-filter "powershell -ExecutionPolicy Bypass -File $scriptPath" --prune-empty --tag-name-filter cat -- --all
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "LIMPIEZA COMPLETADA EXITOSAMENTE" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Próximos pasos:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "1. Verificar que la API key fue reemplazada:" -ForegroundColor Cyan
        Write-Host "   git log --all --source --full-history -- lib/config/api_config.dart" -ForegroundColor White
        Write-Host ""
        Write-Host "2. Limpiar referencias temporales:" -ForegroundColor Cyan
        Write-Host "   git for-each-ref --format='delete %(refname)' refs/original | git update-ref --stdin" -ForegroundColor White
        Write-Host "   git reflog expire --expire=now --all" -ForegroundColor White
        Write-Host "   git gc --prune=now --aggressive" -ForegroundColor White
        Write-Host ""
        Write-Host "3. Hacer force push a GitHub:" -ForegroundColor Cyan
        Write-Host "   git push origin --force --all" -ForegroundColor White
        Write-Host "   git push origin --force --tags" -ForegroundColor White
        Write-Host ""
        Write-Host "4. IMPORTANTE: Revocar la API key antigua y crear una nueva" -ForegroundColor Red
    } else {
        Write-Host "Error durante la limpieza. Revisa los mensajes anteriores." -ForegroundColor Red
    }
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
} finally {
    Remove-Item $scriptPath -ErrorAction SilentlyContinue
}

Write-Host ""
