# AMELI Code - Windows Installer (PowerShell)
# Ejecutar como: powershell -ExecutionPolicy Bypass -File install.ps1

Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "       AMELI Code Installer (Windows)  " -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

$userName = $env:USERNAME
Write-Host "[OK] Hola $userName! (detectado del sistema)" -ForegroundColor Green
Write-Host ""

$projectDir = Read-Host "Donde tenes tu proyecto de OpenCode? (dejalo vacio si usas ~/Opencode) []"
if (-not $projectDir) { $projectDir = "$HOME\Opencode" }

if (Test-Path $projectDir) {
    Write-Host "[OK] Proyecto encontrado en: $projectDir" -ForegroundColor Green
} else {
    Write-Host "[WARN] No existe: $projectDir" -ForegroundColor Yellow
    $createDir = Read-Host "Queres crearlo? (s/N)"
    if ($createDir -eq "s" -or $createDir -eq "S") {
        New-Item -ItemType Directory -Path $projectDir -Force | Out-Null
        Write-Host "[OK] Creado: $projectDir" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Continuando sin proyecto" -ForegroundColor Yellow
        $projectDir = ""
    }
}

Write-Host ""
Write-Host "Instalando dependencias..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Fallo npm install" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Dependencias instaladas" -ForegroundColor Green

Write-Host ""
Write-Host "Guardando configuracion..." -ForegroundColor Yellow
$configDir = "$env:USERPROFILE\.config\ameli-code"
New-Item -ItemType Directory -Path $configDir -Force | Out-Null
if ($projectDir) {
    $config = @{ projectDir = $projectDir; userName = $userName } | ConvertTo-Json
} else {
    $config = @{ userName = $userName } | ConvertTo-Json
}
Set-Content -Path "$configDir\config.json" -Value $config
Write-Host "[OK] Config guardada. Te llamare $userName" -ForegroundColor Green

Write-Host ""
Write-Host "Instalando skills de AMELI..." -ForegroundColor Yellow
$skillsTarget = "$env:USERPROFILE\.config\opencode\skills"
$skillsSource = "backups\opencode\skills"
if (Test-Path $skillsSource) {
    Get-ChildItem "$skillsSource\*" -Directory | ForEach-Object {
        $skillName = $_.Name
        $skillFile = Join-Path $_.FullName "SKILL.md"
        if (Test-Path $skillFile) {
            New-Item -ItemType Directory -Path "$skillsTarget\$skillName" -Force | Out-Null
            if ($skillName -eq "ameli-personal") {
                $content = Get-Content $skillFile -Raw
                $content = $content.Replace("__USER_NAME__", $userName)
                Set-Content -Path "$skillsTarget\$skillName\SKILL.md" -Value $content
            } else {
                Copy-Item $skillFile "$skillsTarget\$skillName\SKILL.md"
            }
            Write-Host "[OK] Skill $skillName instalada" -ForegroundColor Green
        }
    }
}
if (Test-Path "backups\opencode\AGENTS.md") {
    $content = Get-Content "backups\opencode\AGENTS.md" -Raw
    $content = $content.Replace("__USER_NAME__", $userName)
    Set-Content -Path "$env:USERPROFILE\.config\opencode\AGENTS.md" -Value $content
    Write-Host "[OK] AGENTS.md configurado" -ForegroundColor Green
}

Write-Host ""
Write-Host "Verificando opencode CLI..." -ForegroundColor Yellow
$ocPath = Get-Command "opencode" -ErrorAction SilentlyContinue
if ($ocPath) {
    Write-Host "[OK] opencode CLI disponible: $($ocPath.Source)" -ForegroundColor Green
} else {
    Write-Host "[INFO] opencode CLI no encontrado. Instalando..." -ForegroundColor Yellow
    $npmOk = $false
    $npmPath = Get-Command "npm" -ErrorAction SilentlyContinue
    if ($npmPath) {
        npm install -g opencode-ai@latest
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] opencode CLI instalado via npm" -ForegroundColor Green
            $npmOk = $true
        }
    }
    if (-not $npmOk) {
        $installNode = Read-Host "npm no disponible. ¿Queres abrir nodejs.org para instalar Node.js? (s/N)"
        if ($installNode -eq "s" -or $installNode -eq "S") {
            Start-Process "https://nodejs.org"
            Write-Host "[INFO] Despues de instalar Node.js, ejecuta este script de nuevo." -ForegroundColor Yellow
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
                Move-Item $exe.FullName "$binPath\opencode.exe" -Force
                $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
                if ($currentPath -notlike "*$binPath*") {
                    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$binPath", "User")
                }
                Write-Host "[OK] opencode CLI instalado desde GitHub" -ForegroundColor Green
                $npmOk = $true
            }
        } catch {
            Write-Host "[WARN] No se pudo descargar opencode: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    if (-not $npmOk) {
        Write-Host "[WARN] No se pudo instalar opencode automaticamente." -ForegroundColor Yellow
        Write-Host "       Instalalo manualmente desde: https://opencode.ai" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "  Instalacion completa!" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para buildear el instalador .exe:"
Write-Host "  npm run build:win"
Write-Host ""
Write-Host "Para abrir AMELI Code directamente:"
Write-Host "  npm start"
Write-Host ""
