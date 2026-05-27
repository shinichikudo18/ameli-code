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
New-Item -ItemType Directory -Path "$skillsTarget\ameli-personal" -Force | Out-Null
if (Test-Path "backups\opencode\skills\ameli-personal\SKILL.md") {
    $content = Get-Content "backups\opencode\skills\ameli-personal\SKILL.md" -Raw
    $content = $content.Replace("__USER_NAME__", $userName)
    Set-Content -Path "$skillsTarget\ameli-personal\SKILL.md" -Value $content
    Write-Host "[OK] Skill ameli-personal instalada" -ForegroundColor Green
}
if (Test-Path "backups\opencode\skills\context-sesion\SKILL.md") {
    New-Item -ItemType Directory -Path "$skillsTarget\context-sesion" -Force | Out-Null
    Copy-Item "backups\opencode\skills\context-sesion\SKILL.md" "$skillsTarget\context-sesion\SKILL.md"
    Write-Host "[OK] Skill context-sesion instalada" -ForegroundColor Green
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
        $chocoPath = Get-Command "choco" -ErrorAction SilentlyContinue
        if ($chocoPath) {
            choco install opencode -y
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] opencode CLI instalado via chocolatey" -ForegroundColor Green
                $npmOk = $true
            }
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
