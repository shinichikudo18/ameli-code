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
      FileWrite $9 "  [OK] where opencode lo encontr en PATH$\r$\n"
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
    FileWrite $9 "  [OK] opencode CLI ya est instalado. No se requiere accin.$\r$\n"
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
    nsExec::ExecToStack '"cmd.exe" /c "$2 install -g opencode-ai"'
    Pop $1
    Pop $5
    DetailPrint "$5"
    ${If} $1 == 0
      StrCpy $0 0
      DetailPrint "opencode CLI instalado via npm"
      FileWrite $9 "  [OK] npm install -g opencode-ai exitoso$\r$\n"
    ${Else}
      FileWrite $9 "  [ERROR] npm fall con codigo $1$\r$\n"
      FileWrite $9 "  [npm output]:$\r$\n$5$\r$\n"
    ${EndIf}
  ${Else}
    FileWrite $9 "  [INFO] npm no encontrado. Instalando Node.js via winget...$\r$\n"
    DetailPrint "[3/5] Instalando Node.js via winget..."
    nsExec::ExecToLog '"powershell.exe" -Command "winget install OpenJS.NodeJS.LTS --silent --accept-package-agreements"'
    Pop $1
    ${If} $1 == 0
      FileWrite $9 "  [OK] winget install OpenJS.NodeJS.LTS exitoso$\r$\n"
      FileWrite $9 "  [INFO] Ejecutando: npm install -g opencode-ai$\r$\n"
      nsExec::ExecToStack '"cmd.exe" /c "npm install -g opencode-ai"'
      Pop $1
      Pop $5
      DetailPrint "$5"
      ${If} $1 == 0
        StrCpy $0 0
        FileWrite $9 "  [OK] opencode instalado via npm (despues de winget)$\r$\n"
      ${Else}
        FileWrite $9 "  [ERROR] npm install -g opencode-ai fall con codigo $1$\r$\n"
        FileWrite $9 "  [npm output]:$\r$\n$5$\r$\n"
      ${EndIf}
    ${Else}
      FileWrite $9 "  [ERROR] winget fall con cdigo $1 (puede no estar disponible)$\r$\n"
    ${EndIf}
  ${EndIf}

  ${If} $0 != 0
    FileWrite $9 "$\r$\n[4/5] Descargando opencode desde GitHub...$\r$\n"
    DetailPrint "[4/5] Descargando opencode desde GitHub..."
    CreateDirectory "$TEMP\ameli-install"
    nsExec::ExecToLog '"cmd.exe" /c "curl -sL -o $TEMP\ameli-install\opencode.zip https://github.com/anomalyco/opencode/releases/latest/download/opencode-windows-x64.zip"'
    Pop $1
    ${If} $1 == 0
      FileWrite $9 "  [OK] Descarga ZIP completada$\r$\n"
      DetailPrint "Extrayendo e instalando..."
      nsExec::ExecToLog '"powershell.exe" -Command "Expand-Archive -Path $TEMP\ameli-install\opencode.zip -DestinationPath $TEMP\ameli-install -Force; if ((Get-ChildItem $TEMP\ameli-install\*.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1)) { Copy-Item (Get-ChildItem $TEMP\ameli-install\*.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).FullName $PROFILE\AppData\Roaming\npm\opencode.exe -Force; exit 0 } else { exit 1 }"'
      Pop $2
      ${If} $2 == 0
        IfFileExists "$PROFILE\AppData\Roaming\npm\opencode.exe" 0 +3
        StrCpy $0 0
        FileWrite $9 "  [OK] opencode copiado a %APPDATA%\npm\opencode.exe$\r$\n"
      ${Else}
        FileWrite $9 "  [ERROR] PowerShell fall con cdigo $2$\r$\n"
      ${EndIf}
      RMDir /r "$TEMP\ameli-install"
    ${Else}
      FileWrite $9 "  [ERROR] curl fall con cdigo $1 (sin conexin o URL invlida)$\r$\n"
    ${EndIf}
  ${EndIf}

  ${If} $0 != 0
    FileWrite $9 "$\r$\n[5/5] Instalacin automtica fallida$\r$\n"
    DetailPrint "[5/5] Instalacin automtica fallida"
    FileWrite $9 "  [INFO] opencode no se pudo instalar automaticamente$\r$\n"
  ${EndIf}

showResult:
  FileWrite $9 "$\r$\n=== Fin del log ===$\r$\n"
  FileClose $9

  ${If} $0 == 0
    DetailPrint "opencode CLI listo"
    MessageBox MB_OK "$\r$\n  opencode CLI instalado correctamente.$\r$\n$\r$\n  Log completo guardado en:$\r$\n  $8"
  ${Else}
    DetailPrint "No se pudo instalar opencode automaticamente."
    MessageBox MB_OK "$\r$\n  No se pudo instalar opencode CLI automaticamente.$\r$\n$\r$\n  Para depurar, revisa el log:$\r$\n  $8$\r$\n$\r$\n  AMELI Code puede seguir usandose, pero$\r$\n  las funciones de terminal requeriran$\r$\n  opencode instalado manualmente."
  ${EndIf}
!macroend
