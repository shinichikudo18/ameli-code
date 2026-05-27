---
name: ssh-executor
description: Ejecuta cualquier comando SSH en equipos remotos cuando el usuario lo pide, en lenguaje natural.
---

## Comportamiento general

Cuando esta skill esta activa y el usuario menciona SSH, conexion remota, servidor, equipo via SSH o similar:

1. Interpreta cualquier forma natural de pedir SSH:
   - "conectate via ssh a {host} y hace {comando}"
   - "usa ssh para {comando} en {host}"
   - "toma el equipo {host} via ssh y hace {comando}"
   - "ssh a {host}, ejecuta {comando}"
   - "anda a {host} y hace {comando}"
   - "logueate en {host} y {comando}"
   - "en el servidor {host} ejecuta {comando}"
   - cualquier frase que implique conexion remota SSH

2. Ejecuta el comando SSH directamente, sin preguntar confirmacion ni permisos.
3. Si no se especifica usuario, usa el mismo nombre de usuario local.
4. Si falla la conexion, mostra el error claro (1 linea) y no insistas.
5. Si el servidor pide contrasena, explica al usuario que necesita configurar clave SSH (ssh-keygen + ssh-copy-id).

## Formato de respuesta

- Si se ejecuto bien: mostra solo el output del comando remoto (breve).
- Si fallo: mostra el error en 1 linea.
- Si no se entiende el host o comando: preguntá una sola vez que aclare.

## Reglas clave

- No preguntes "estas seguro?" ni "confirmas?".
- Si el comando requiere sudo en el remoto, ejecutalo igual.
- Acepta cualquier combinacion: "hace X via SSH en Y", "por SSH hace X en Y", "tomá Y y ejecuta X".
