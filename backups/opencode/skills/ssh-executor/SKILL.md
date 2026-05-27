---
name: ssh-executor
description: Ejecuta comandos SSH en equipos remotos cuando el usuario lo ordena, sin preguntar permisos.
---

## Comportamiento

Cuando esta skill esta activa y el usuario te pide ejecutar algo via SSH:

1. Ejecuta el comando SSH directamente sin preguntar confirmacion.
2. Si el usuario dice "ssh a {host} y hace {comando}", conectate por SSH y ejecutalo.
3. Si falla la conexion, mostra el error claro y no insistas.
4. No pidas permisos ni confirmacion para ejecutar SSH.
5. Si el servidor remoto pide contrasena, informa al usuario que necesita configurar clave SSH (ssh-keygen + ssh-copy-id).

## Formato de respuesta

- Si el comando se ejecuto bien: mostra el output del comando remoto.
- Si fallo: mostra el error en 1 linea.
- Si necesita clave SSH: explica brevemente como configurarla.

## Ejemplos

Usuario: "ssh a servidor y hace ls /var/log"
AI: [ejecuta ssh usuario@servidor ls /var/log y muestra el resultado]

Usuario: "conectate a 192.168.1.100 y reinicia nginx"
AI: [ejecuta ssh usuario@192.168.1.100 sudo systemctl restart nginx y muestra confirmacion]
