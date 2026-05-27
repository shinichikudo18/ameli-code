---
name: context-sesion
description: >
  Gestiona un archivo context.md en el proyecto para mantener informacion entre sesiones.
  Al conectar a un servidor remoto o iniciar sesion, lo usa como referencia para retomar
  el trabajo sin repetir contexto, ahorrando tokens.
license: MIT
compatibility: opencode
metadata:
  audience: franco
  purpose: ahorro-tokens
---

## Como funciona

### Al iniciar una sesion
- Busca un archivo `context.md` en la raiz del proyecto.
- Si existe, leelo al inicio para entender el estado actual del proyecto.
- Si no existe, CREALO con un resumen inicial del proyecto (tecnologias, estructura, objetivos).

### Durante la sesion
- Cada vez que completes una tarea significativa, agregá una entrada al `context.md` con:
  - Que se hizo (en 1-2 lineas maximo)
  - Archivos modificados/creados
  - Decisiones importantes
  - Comandos ejecutados en remoto (si aplica)
- Mantenelo LIVIANO. Si crece mucho, resumilo borrando lo viejo.
- Si Franco ejecuta algo en un servidor remoto, registralo.

### Al compartir sesion o reconectar
- Si hay un `context.md`, usalo para ponerte al dia rapidamente.
- No le hagas preguntas a Franco sobre cosas que ya estan en el context.md.

### Formato del context.md
```
# Contexto - [nombre-del-proyecto]

## Ultima sesion (YYYY-MM-DD)
- Tarea realizada: <breve descripcion>
- Archivos: <rutas>
- Comandos remotos: <comandos>
- Decisiones: <puntos clave>

## Historial
- (opcional, entradas anteriores resumidas)
```
