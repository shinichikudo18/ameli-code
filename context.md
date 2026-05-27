# Contexto - Katherine Code

## Ultima sesion (2026-05-27)
- Instalador Windows: detección robusta de opencode (busca en %APPDATA%\npm, %LOCALAPPDATA%, ProgramFiles, PATH)
- NSIS: log detallado en %TEMP%\ameli-install-opencode.log + MessageBox final con resumen
- main.js: findOpencodeBinary() busca opencode en rutas comunes (no solo PATH) para que `opencode serve` funcione al iniciar desde acceso directo
- HTML: eliminado hardcoded "v1.0.0", la version se setea dinámicamente desde app.getVersion()
- Archivos: main.js, renderer/index.html, build/installer.nsh
- Releases: v1.1.11, v1.1.12 (falló build), v1.1.13

## Estado actual
- App Electron local para manejar OpenCode terminal.
- UI con sesiones, modelos, skills, proyectos y bandeja.
- Instalador Windows: busca opencode → npm → GitHub directo → ofrece Node.js / opencode.ai
- findOpencodeBinary() search paths: Roaming\npm, Local\opencode, Local\opencode-windows-x64, ProgramFiles\nodejs, /usr/local/bin, ~/.local/bin, SystemRoot\System32
- Auto-updater via electron-updater + version.json fallback

## Reglas importantes
- Cuando Franco pida "subir a GitHub", primero asegurate de guardar todos los cambios locales y dejar el repo listo antes de empujar.
- Mantener este archivo liviano y actualizado con decisiones importantes.
