---
name: creacion-de-contexto
description: Guardar el contexto de la sesion en un archivo context.md y pedir que sesion anterior reutilizar.
---

## Que hace
- Guarda el contexto importante de la sesion actual en un archivo `context.md`.
- Registra el nombre de la sesion en el archivo correspondiente.
- Cuando se abre una nueva sesion, pregunta que sesion anterior quiere reutilizar.

## Reglas
- No selecciones automaticamente una sesion anterior si el usuario no lo indica.
- Siempre deja que el usuario indique que contexto anterior necesita.
- Mantiene el historial separado por nombre de sesion.

## Respuesta
- Corta.
- En espanol.
- Solo resultado.
