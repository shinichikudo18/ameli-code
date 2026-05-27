# AMELI Code

App de AMELI para gestionar sesiones de OpenCode en escritorio.

## Incluye

- sesiones de OpenCode
- selector de modelos
- skills contextuales
- stickers locales configurables
- bandeja del sistema
- persistencia de proyecto y sesion
- renombrar y borrar proyectos desde la sidebar
- renombrar y borrar sesiones desde la sidebar

## Assets

- `assets/logo/ameli-icon.png`
- `assets/stickers/`

## Skills y contexto

Este repo incluye skills y contexto para AMELI:

- `backups/opencode/AGENTS.md`
- `backups/opencode/skills/`
- `context.md`

## Instalacion

### Linux
```bash
./install.sh
```

### Windows
```powershell
powershell -ExecutionPolicy Bypass -File install.ps1
```

## Build para Windows (.exe)

```bash
npm run build:win
```

Esto genera un instalador .exe en `dist/` usando electron-builder (NSIS).

## Uso

```bash
npm start
```

## Stickers

- Abri `🖼 Stickers`
- Activá o desactivá stickers con el switch maestro
- Usá `+ Agregar` para importar mas stickers desde tu disco
- Elegí en qué caso se usa cada sticker
- Al importarlos, la app los copia a `assets/stickers/` y hace sync con GitHub

## Proyectos y sesiones

- En `Proyecto`, usá ✎ para renombrar y 🗑 para borrar carpetas de proyecto
- En `Sesiones`, usá ✎ para renombrar y 🗑 para borrar sesiones
- El renombrado se hace inline, sin prompts del sistema

Casos probados:
- `gracias` -> `gracias.png` / `gracias02.png`
- `vamos a crear` -> `dejamelo a mi.png` / `vamos.png` / `vamos02.png` / `voy para alla.png`

## GitHub

Si querés usarlo en otro Linux, clonal o actualizalo desde GitHub:

```bash
git clone https://github.com/shinichikudo18/ameli-code
cd ameli-code
./install.sh
```
