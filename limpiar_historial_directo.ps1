# Script directo para limpiar la API key del historial de Git
# Este script usa git filter-branch de forma más simple y directa

param(
    [switch]$Force
)

$apiKey = "0b98eaa93e43454193320ea18051ea79"

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "LIMPIEZA DEL HISTORIAL DE GIT" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Este script va a reemplazar la API key en TODO el historial" -ForegroundColor Cyan
Write-Host "API key a reemplazar: $apiKey" -ForegroundColor Cyan
Write-Host ""

if (-not $Force) {
    $confirm = Read-Host "¿Deseas continuar? (s/n)"
    if ($confirm -ne "s" -and $confirm -ne "S") {
        Write-Host "Operación cancelada." -ForegroundColor Yellow
        exit
    }
}

Write-Host ""
Write-Host "Iniciando limpieza del historial..." -ForegroundColor Green
Write-Host ""

# Configurar variable para silenciar advertencias de git filter-branch
$env:FILTER_BRANCH_SQUELCH_WARNING = "1"

# Crear script de reemplazo
$replaceScript = @'
$file = "lib/config/api_config.dart"
if (Test-Path $file) {
    $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
    if ($content -and $content -match "0b98eaa93e43454193320ea18051ea79") {
        $content = $content -replace "0b98eaa93e43454193320ea18051ea79", "YOUR_API_KEY_HERE"
        [System.IO.File]::WriteAllText((Resolve-Path $file), $content, [System.Text.Encoding]::UTF8)
    }
}
'@

$scriptPath = Join-Path $PWD "git_replace_temp.ps1"
$replaceScript | Out-File -FilePath $scriptPath -Encoding UTF8

try {
    Write-Host "Ejecutando git filter-branch..." -ForegroundColor Yellow
    Write-Host "Esto puede tardar varios minutos dependiendo del tamaño del historial..." -ForegroundColor Yellow
    Write-Host ""
    
    # Ejecutar git filter-branch
    $filterCmd = "powershell -ExecutionPolicy Bypass -File `"$scriptPath`""
    git filter-branch -f --tree-filter $filterCmd --prune-empty --tag-name-filter cat -- --all
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Limpieza completada. Limpiando referencias temporales..." -ForegroundColor Green
        
        # Limpiar referencias de backup de git filter-branch
        git for-each-ref --format='delete %(refname)' refs/original 2>$null | git update-ref --stdin 2>$null
        git reflog expire --expire=now --all 2>$null
        git gc --prune=now --aggressive 2>$null
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "LIMPIEZA COMPLETADA EXITOSAMENTE" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Verificando resultado..." -ForegroundColor Cyan
        
        # Verificar que la API key fue reemplazada
        $check = git log --all --source --full-history -p -S $apiKey 2>$null | Select-String -Pattern $apiKey
        
        if ($check) {
            Write-Host "ADVERTENCIA: La API key aún puede aparecer en algunas referencias." -ForegroundColor Yellow
            Write-Host "Puede ser necesario usar un método alternativo." -ForegroundColor Yellow
        } else {
            Write-Host "La API key ha sido eliminada del historial." -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host "PRÓXIMOS PASOS OBLIGATORIOS:" -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "1. Hacer force push a GitHub:" -ForegroundColor Cyan
        Write-Host "   git push origin --force --all" -ForegroundColor White
        Write-Host "   git push origin --force --tags" -ForegroundColor White
        Write-Host ""
        Write-Host "2. CRÍTICO - Revocar la API key antigua:" -ForegroundColor Red
        Write-Host "   - Ve a https://rawg.io/apidocs" -ForegroundColor White
        Write-Host "   - Revoca la clave: $apiKey" -ForegroundColor White
        Write-Host "   - Genera una nueva API key" -ForegroundColor White
        Write-Host "   - Actualiza el archivo .env con la nueva clave" -ForegroundColor White
        Write-Host ""
        Write-Host "3. Notificar a colaboradores:" -ForegroundColor Yellow
        Write-Host "   Todos los colaboradores deben hacer:" -ForegroundColor White
        Write-Host "   git fetch origin" -ForegroundColor White
        Write-Host "   git reset --hard origin/main" -ForegroundColor White
        Write-Host ""
        
    } else {
        Write-Host ""
        Write-Host "Error durante la ejecución. Código: $LASTEXITCODE" -ForegroundColor Red
        Write-Host "Intenta ejecutar manualmente o usa un método alternativo." -ForegroundColor Yellow
    }
    
} catch {
    Write-Host ""
    $errorMsg = $_.Exception.Message
    Write-Host "Error: $errorMsg" -ForegroundColor Red
} finally {
    if (Test-Path $scriptPath) {
        Remove-Item $scriptPath -ErrorAction SilentlyContinue
    }
}

Write-Host ""
