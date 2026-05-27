!macro customInstall
  SetDetailsView show
  StrCpy $8 "$TEMP\ameli-install-opencode.log"

  FileOpen $9 $8 w
  FileWrite $9 "=== AMELI Code - Instalacion de opencode CLI ===$\r$\n"
  FileWrite $9 "Build: ${__DATE__} ${__TIME__}$\r$\n$\r$\n"
  FileWrite $9 "[1/5] Verificando si opencode ya esta instalado...$\r$\n"

  DetailPrint "[1/5] Verificando opencode CLI..."
  StrCpy $0 0

  ExecWait '"$WINDIR\System32\cmd.exe" /c "opencode --version >nul 2>nul"' $0
  ${If} $0 == 0
    FileWrite $9 "  [OK] opencode --version exitoso$\r$\n"
  ${EndIf}
  ${If} $0 != 0
    ExecWait '"$WINDIR\System32\cmd.exe" /c "where opencode >nul 2>nul"' $0
    ${If} $0 == 0
      FileWrite $9 "  [OK] where opencode lo encontró en PATH$\r$\n"
    ${EndIf}
  ${EndIf}
  ${If} $0 != 0
    IfFileExists "$PROFILE\AppData\Roaming\npm\opencode.exe" 0 +3
    StrCpy $0 0
    FileWrite $9 "  [OK] encontrado en %APPDATA%\npm\opencode.exe$\r$\n"
  ${EndIf}
  ${If} $0 != 0
    IfFileExists "$PROFILE\AppData\Local\opencode\opencode-windows-x64\opencode.exe" 0 +3
    StrCpy $0 0
    FileWrite $9 "  [OK] encontrado en %LOCALAPPDATA%\opencode-windows-x64\$\r$\n"
  ${EndIf}
  ${If} $0 != 0
    IfFileExists "$PROFILE\AppData\Local\opencode\opencode.exe" 0 +3
    StrCpy $0 0
    FileWrite $9 "  [OK] encontrado en %LOCALAPPDATA%\opencode\$\r$\n"
  ${EndIf}
  ${If} $0 != 0
    IfFileExists "$PROGRAMFILES64\nodejs\opencode.exe" 0 +3
    StrCpy $0 0
    FileWrite $9 "  [OK] encontrado en %PROGRAMFILES64%\nodejs\$\r$\n"
  ${EndIf}
  ${If} $0 != 0
    IfFileExists "$PROGRAMFILES\nodejs\opencode.exe" 0 +3
    StrCpy $0 0
    FileWrite $9 "  [OK] encontrado en %PROGRAMFILES%\nodejs\$\r$\n"
  ${EndIf}

  ${If} $0 == 0
    FileWrite $9 "  [OK] opencode CLI ya está instalado. No se requiere acción.$\r$\n"
    Goto showResult
  ${EndIf}

  FileWrite $9 "  [INFO] opencode no encontrado. Procediendo a instalar...$\r$\n"

  FileWrite $9 "$\r$\n[2/5] Buscando npm...$\r$\n"
  DetailPrint "[2/5] Buscando npm..."
  StrCpy $2 ""
  ExecWait '"$WINDIR\System32\cmd.exe" /c "where npm >nul 2>nul"' $1
  ${If} $1 == 0
    StrCpy $2 "npm"
    FileWrite $9 "  [OK] npm encontrado en PATH$\r$\n"
  ${Else}
    IfFileExists "$PROFILE\AppData\Roaming\npm\npm.cmd" 0 +3
    StrCpy $2 "$PROFILE\AppData\Roaming\npm\npm.cmd"
    FileWrite $9 "  [OK] npm encontrado en %APPDATA%\npm\$\r$\n"
    ${If} $2 == ""
      IfFileExists "$PROGRAMFILES64\nodejs\npm.cmd" 0 +3
      StrCpy $2 "$PROGRAMFILES64\nodejs\npm.cmd"
      FileWrite $9 "  [OK] npm encontrado en %PROGRAMFILES64%\nodejs\$\r$\n"
      ${If} $2 == ""
        IfFileExists "$PROGRAMFILES\nodejs\npm.cmd" 0 +3
        StrCpy $2 "$PROGRAMFILES\nodejs\npm.cmd"
        FileWrite $9 "  [OK] npm encontrado en %PROGRAMFILES%\nodejs\$\r$\n"
      ${EndIf}
    ${EndIf}
  ${EndIf}

  ${If} $2 != ""
    FileWrite $9 "$\r$\n[3/5] Instalando opencode via npm...$\r$\n"
    DetailPrint "[3/5] Instalando opencode via npm..."
    FileWrite $9 "  Ejecutando: $2 install -g opencode-ai$\r$\n"
    ExecWait '"$WINDIR\System32\cmd.exe" /c ""$2" install -g opencode-ai"' $1
    ${If} $1 == 0
      StrCpy $0 0
      DetailPrint "opencode CLI instalado via npm"
      FileWrite $9 "  [OK] npm install -g opencode-ai exitoso (codigo $1)$\r$\n"
    ${Else}
      FileWrite $9 "  [ERROR] npm falló con código $1$\r$\n"
    ${EndIf}
  ${Else}
    FileWrite $9 "  [ERROR] npm no encontrado en ninguna ubicación$\r$\n"
  ${EndIf}

  ${If} $0 != 0
    FileWrite $9 "$\r$\n[4/5] Descargando opencode desde GitHub...$\r$\n"
    DetailPrint "[4/5] Descargando opencode desde GitHub..."
    CreateDirectory "$TEMP\ameli-install"
    ExecWait '"$WINDIR\System32\curl.exe" -sL -o "$TEMP\ameli-install\opencode.zip" "https://github.com/anomalyco/opencode/releases/latest/download/opencode-windows-x64.zip"' $1
    ${If} $1 == 0
      FileWrite $9 "  [OK] Descarga ZIP completada (curl código $1)$\r$\n"
      DetailPrint "Extrayendo e instalando..."
      ExecWait "$\"$WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe$\" -Command $\"Expand-Archive -Path '$TEMP\ameli-install\opencode.zip' -DestinationPath '$TEMP\ameli-install' -Force; $$exe = (Get-ChildItem '$TEMP\ameli-install\opencode-windows-x64\*.exe' | Select-Object -First 1).FullName; Copy-Item $$exe '$PROFILE\AppData\Roaming\npm\opencode.exe' -Force$\"" $2
      ${If} $2 == 0
        IfFileExists "$PROFILE\AppData\Roaming\npm\opencode.exe" 0 +3
        StrCpy $0 0
        FileWrite $9 "  [OK] opencode copiado a %APPDATA%\npm\opencode.exe$\r$\n"
        FileWrite $9 "  [OK] ¡Instalación directa exitosa!$\r$\n"
      ${Else}
        FileWrite $9 "  [ERROR] PowerShell falló con código $2$\r$\n"
      ${EndIf}
      RMDir /r "$TEMP\ameli-install"
    ${Else}
      FileWrite $9 "  [ERROR] curl falló con código $1 (sin conexión o URL inválida)$\r$\n"
    ${EndIf}
  ${EndIf}

  ${If} $0 != 0
    FileWrite $9 "$\r$\n[5/5] Instalación automática fallida$\r$\n"
    DetailPrint "[5/5] Instalación automática fallida"
    FileWrite $9 "  [INFO] Se ofrecerán opciones manuales al usuario$\r$\n"
  ${EndIf}

showResult:
  FileWrite $9 "$\r$\n=== Fin del log ===$\r$\n"
  FileClose $9

  ${If} $0 == 0
    DetailPrint "opencode CLI listo"
    MessageBox MB_OK "$\r$\n  opencode CLI instalado correctamente.$\r$\n$\r$\n  Log completo guardado en:$\r$\n  $8"
  ${Else}
    DetailPrint "No se pudo instalar opencode automaticamente."
    MessageBox MB_YESNO "$\r$\n  No se pudo instalar opencode CLI automaticamente.$\r$\n$\r$\n  Para depurar, revisa el log:$\r$\n  $8$\r$\n$\r$\n  ¿Querés descargar Node.js para que$\r$\n  AMELI Code pueda instalar opencode?" IDYES installNode IDNO askOpen
    installNode:
      ExecShell "open" "https://nodejs.org"
    askOpen:
    MessageBox MB_YESNO "$\r$\n  ¿Querés ir a opencode.ai para$\r$\n  descargar opencode manualmente?" IDYES openOC IDNO done
    openOC:
      ExecShell "open" "https://opencode.ai"
    done:
  ${EndIf}
!macroend
