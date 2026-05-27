param(
  [Parameter(Mandatory=$true)]
  [string]$Version
)

$ErrorActionPreference = "Stop"
$AppDir = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
Set-Location $AppDir

Write-Host "Actualizando package.json a v$Version..." -ForegroundColor Yellow
$pkg = Get-Content package.json -Raw | ConvertFrom-Json
$pkg.version = $Version
$pkg | ConvertTo-Json | Set-Content package.json

Write-Host "Actualizando version.json..." -ForegroundColor Yellow
@{
  latest = $Version
  releaseUrl = "https://github.com/shinichikudo18/ameli-code/releases/tag/v$Version"
  downloadUrl = "https://github.com/shinichikudo18/ameli-code/releases/download/v$Version/AMELI.Code.Setup.$Version.exe"
} | ConvertTo-Json | Set-Content version.json

Write-Host "Haciendo commit y tag v$Version..." -ForegroundColor Yellow
git add package.json version.json
git commit -m "bump version to $Version"
git tag "v$Version"
git push
git push origin "v$Version"

Write-Host "Buildeando .exe para Windows..." -ForegroundColor Yellow
npm run build:win

Write-Host "Creando release en GitHub..." -ForegroundColor Yellow
gh release create "v$Version" "dist/AMELI Code Setup $Version.exe" --title "AMELI Code v$Version" --notes "Release v$Version"

Write-Host ""
Write-Host "✅ Release v$Version creada y publicada:" -ForegroundColor Green
Write-Host "   https://github.com/shinichikudo18/ameli-code/releases/tag/v$Version" -ForegroundColor Cyan
