# AMELI Code - Instalador de opencode CLI para Windows
# Este script verifica si opencode CLI esta instalado y si no, lo instala
# usando npm (recomendado), chocolatey o scoop.

$host.UI.RawUI.WindowTitle = "AMELI Code - Instalando opencode CLI"

Write-Host "Verificando opencode CLI..." -ForegroundColor Yellow

# Check if already installed
$opencodePath = Get-Command "opencode" -ErrorAction SilentlyContinue
if ($opencodePath) {
    Write-Host "[OK] opencode CLI ya esta instalado: $($opencodePath.Source)" -ForegroundColor Green
    exit 0
}

Write-Host "[INFO] opencode CLI no encontrado. Intentando instalar..." -ForegroundColor Yellow

# Method 1: npm (most common among developers)
$npmPath = Get-Command "npm" -ErrorAction SilentlyContinue
if ($npmPath) {
    Write-Host "[INFO] Instalando via npm..." -ForegroundColor Yellow
    $process = Start-Process -FilePath "npm" -ArgumentList "install", "-g", "opencode-ai@latest" -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -eq 0) {
        Write-Host "[OK] opencode CLI instalado correctamente via npm" -ForegroundColor Green
        exit 0
    }
    Write-Host "[WARN] Fallo instalacion via npm" -ForegroundColor Yellow
}

# Method 2: chocolatey
$chocoPath = Get-Command "choco" -ErrorAction SilentlyContinue
if ($chocoPath) {
    Write-Host "[INFO] Instalando via chocolatey..." -ForegroundColor Yellow
    $process = Start-Process -FilePath "choco" -ArgumentList "install", "opencode", "-y" -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -eq 0) {
        Write-Host "[OK] opencode CLI instalado correctamente via chocolatey" -ForegroundColor Green
        exit 0
    }
    Write-Host "[WARN] Fallo instalacion via chocolatey" -ForegroundColor Yellow
}

# Method 3: scoop
$scoopPath = Get-Command "scoop" -ErrorAction SilentlyContinue
if ($scoopPath) {
    Write-Host "[INFO] Instalando via scoop..." -ForegroundColor Yellow
    $process = Start-Process -FilePath "scoop" -ArgumentList "install", "opencode" -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -eq 0) {
        Write-Host "[OK] opencode CLI instalado correctamente via scoop" -ForegroundColor Green
        exit 0
    }
    Write-Host "[WARN] Fallo instalacion via scoop" -ForegroundColor Yellow
}

Write-Host "[ERROR] No se pudo instalar opencode CLI automaticamente." -ForegroundColor Red
Write-Host ""
Write-Host "Instalalo manualmente desde: https://opencode.ai" -ForegroundColor Cyan
Write-Host "O ejecuta: npm install -g opencode-ai" -ForegroundColor Cyan
exit 1
