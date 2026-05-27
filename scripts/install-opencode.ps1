# AMELI Code - Instalador de opencode CLI para Windows
# Verifica si opencode CLI esta instalado y si no, lo instala
# via npm o descarga directa desde GitHub.

$host.UI.RawUI.WindowTitle = "AMELI Code - Instalando opencode CLI"

Write-Host "Verificando opencode CLI..." -ForegroundColor Yellow

$opencodePath = Get-Command "opencode" -ErrorAction SilentlyContinue
if ($opencodePath) {
    Write-Host "[OK] opencode CLI ya esta instalado: $($opencodePath.Source)" -ForegroundColor Green
    exit 0
}

Write-Host "[INFO] opencode CLI no encontrado. Intentando instalar..." -ForegroundColor Yellow

$npmPath = Get-Command "npm" -ErrorAction SilentlyContinue
if ($npmPath) {
    Write-Host "[INFO] Instalando via npm..." -ForegroundColor Yellow
    npm install -g opencode-ai@latest
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] opencode CLI instalado via npm" -ForegroundColor Green
        exit 0
    }
    Write-Host "[WARN] Fallo instalacion via npm" -ForegroundColor Yellow
}

Write-Host "[INFO] npm no disponible. Descargando opencode CLI desde GitHub..." -ForegroundColor Yellow

$zipPath = "$env:TEMP\opencode-windows-x64.zip"
$destDir = "$env:LOCALAPPDATA\opencode"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri "https://github.com/anomalyco/opencode/releases/latest/download/opencode-windows-x64.zip" -OutFile $zipPath -UseBasicParsing

    Remove-Item -Path $destDir -Recurse -Force -ErrorAction SilentlyContinue
    Expand-Archive -Path $zipPath -DestinationPath $destDir -Force
    Remove-Item $zipPath -Force

    $binPath = "$destDir\opencode-windows-x64"
    $exe = Get-ChildItem -Path $binPath -Filter "*.exe" | Select-Object -First 1
    if ($exe) {
        $opencodeExe = "$binPath\opencode.exe"
        Move-Item $exe.FullName $opencodeExe -Force

        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        if ($currentPath -notlike "*$binPath*") {
            [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$binPath", "User")
            Write-Host "[OK] opencode agregado al PATH de usuario" -ForegroundColor Green
        }

        Write-Host "[OK] opencode CLI instalado en: $opencodeExe" -ForegroundColor Green
        Write-Host ""
        Write-Host "IMPORTANTE: Necesitas cerrar y reabrir la terminal para usar 'opencode'." -ForegroundColor Cyan
        exit 0
    }
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "[ERROR] No se pudo instalar opencode CLI." -ForegroundColor Red
Write-Host "Instalalo manualmente desde: https://opencode.ai" -ForegroundColor Cyan
exit 1
