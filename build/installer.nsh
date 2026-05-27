!macro customInstall
  SetDetailsView show
  StrCpy $8 "$TEMP\ameli-install-opencode.log"

  FileOpen $9 $8 w
  FileWrite $9 "=== AMELI Code - Instalacion de opencode CLI ===$\r$\n"
  FileWrite $9 "Build: ${__DATE__} ${__TIME__}$\r$\n$\r$\n"
  FileWrite $9 "[1/5] Verificando si opencode ya esta instalado...$\r$\n"

  DetailPrint "[1/5] Verificando opencode CLI..."
  StrCpy $0 0
  StrCpy $6 "$PROFILE\AppData\Roaming\npm\opencode.exe"

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
    IfFileExists $6 0 +3
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

  FileWrite $9 "$\r\n[2/5] Buscando npm...$\r\n"
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
    FileWrite $9 "$\r\n[3/5] Instalando opencode via npm...$\r\n"
    DetailPrint "[3/5] Instalando opencode via npm..."
    FileWrite $9 "  Ejecutando: $2 install -g opencode-ai --prefix $PROFILE\AppData\Roaming\npm$\r$\n"
    nsExec::ExecToLog '"cmd.exe" /c "$2 install -g opencode-ai --prefix $PROFILE\AppData\Roaming\npm"'
    Pop $1
    ${If} $1 == 0
      IfFileExists $6 0 +3
      StrCpy $0 0
      FileWrite $9 "  [OK] opencode encontrado en %APPDATA%\npm\$\r$\n"
      ${If} $0 != 0
        FileWrite $9 "  [INFO] npm reporta exito pero opencode no esta en %APPDATA%\npm. Buscando...$\r$\n"
        IfFileExists "$PROGRAMFILES64\nodejs\opencode.exe" 0 +3
        StrCpy $0 0
        CopyFiles /SILENT "$PROGRAMFILES64\nodejs\opencode.exe" $6
        FileWrite $9 "  [OK] opencode copiado desde %PROGRAMFILES64%\nodejs$\r$\n"
        ${If} $0 != 0
          IfFileExists "$PROGRAMFILES\nodejs\opencode.exe" 0 +3
          StrCpy $0 0
          CopyFiles /SILENT "$PROGRAMFILES\nodejs\opencode.exe" $6
          FileWrite $9 "  [OK] opencode copiado desde %PROGRAMFILES%\nodejs$\r$\n"
        ${EndIf}
      ${EndIf}
    ${Else}
      FileWrite $9 "  [ERROR] npm falló con código $1$\r$\n"
    ${EndIf}
  ${Else}
    FileWrite $9 "  [INFO] npm no encontrado directamente. Verificando si Node.js esta instalado...$\r$\n"
    StrCpy $3 ""
    ExecWait '"$WINDIR\System32\cmd.exe" /c "where node >nul 2>nul"' $1
    ${If} $1 == 0
      StrCpy $3 "node"
      FileWrite $9 "  [OK] node.exe encontrado en PATH$\r$\n"
    ${Else}
      IfFileExists "$PROGRAMFILES64\nodejs\node.exe" 0 +3
      StrCpy $3 "$PROGRAMFILES64\nodejs\node.exe"
      FileWrite $9 "  [OK] node.exe encontrado en %PROGRAMFILES64%\nodejs\$\r$\n"
      ${If} $3 == ""
        IfFileExists "$PROGRAMFILES\nodejs\node.exe" 0 +3
        StrCpy $3 "$PROGRAMFILES\nodejs\node.exe"
        FileWrite $9 "  [OK] node.exe encontrado en %PROGRAMFILES%\nodejs\$\r$\n"
      ${EndIf}
    ${EndIf}

    ${If} $3 != ""
      FileWrite $9 "  [INFO] Node.js instalado pero npm no encontrado. Usando npm directo desde Node.js...$\r$\n"
      DetailPrint "Node.js detectado. Buscando npm-cli.js..."
      StrCpy $4 ""
      IfFileExists "$PROFILE\AppData\Roaming\npm\node_modules\npm\bin\npm-cli.js" 0 +3
      StrCpy $4 "$PROFILE\AppData\Roaming\npm\node_modules\npm\bin\npm-cli.js"
      FileWrite $9 "  [OK] npm-cli.js encontrado en %APPDATA%\npm\$\r$\n"
      ${If} $4 == ""
        IfFileExists "$PROGRAMFILES64\nodejs\node_modules\npm\bin\npm-cli.js" 0 +3
        StrCpy $4 "$PROGRAMFILES64\nodejs\node_modules\npm\bin\npm-cli.js"
        FileWrite $9 "  [OK] npm-cli.js encontrado en %PROGRAMFILES64%\nodejs\$\r$\n"
        ${If} $4 == ""
          IfFileExists "$PROGRAMFILES\nodejs\node_modules\npm\bin\npm-cli.js" 0 +3
          StrCpy $4 "$PROGRAMFILES\nodejs\node_modules\npm\bin\npm-cli.js"
          FileWrite $9 "  [OK] npm-cli.js encontrado en %PROGRAMFILES%\nodejs\$\r$\n"
        ${EndIf}
      ${EndIf}

      ${If} $4 != ""
        FileWrite $9 "  Ejecutando: $3 $4 install -g opencode-ai --prefix $PROFILE\AppData\Roaming\npm$\r$\n"
        nsExec::ExecToLog '"cmd.exe" /c "$3 $4 install -g opencode-ai --prefix $PROFILE\AppData\Roaming\npm"'
        Pop $1
        ${If} $1 == 0
          IfFileExists $6 0 +3
          StrCpy $0 0
          FileWrite $9 "  [OK] opencode encontrado en %APPDATA%\npm$\r$\n"
          ${If} $0 != 0
            FileWrite $9 "  [INFO] npm reporta exito pero opencode no esta en %APPDATA%\npm. Buscando...$\r$\n"
            IfFileExists "$PROGRAMFILES64\nodejs\opencode.exe" 0 +3
            StrCpy $0 0
            CopyFiles /SILENT "$PROGRAMFILES64\nodejs\opencode.exe" $6
            FileWrite $9 "  [OK] opencode copiado desde %PROGRAMFILES64%\nodejs$\r$\n"
            ${If} $0 != 0
              IfFileExists "$PROGRAMFILES\nodejs\opencode.exe" 0 +3
              StrCpy $0 0
              CopyFiles /SILENT "$PROGRAMFILES\nodejs\opencode.exe" $6
              FileWrite $9 "  [OK] opencode copiado desde %PROGRAMFILES%\nodejs$\r$\n"
            ${EndIf}
          ${EndIf}
        ${Else}
          FileWrite $9 "  [ERROR] npm-cli.js falló con código $1$\r$\n"
        ${EndIf}
      ${Else}
        FileWrite $9 "  [ERROR] npm-cli.js no encontrado en ninguna ubicación$\r$\n"
      ${EndIf}
    ${Else}
      FileWrite $9 "  [INFO] Node.js no encontrado. Instalando Node.js via winget...$\r$\n"
      DetailPrint "Instalando Node.js LTS via winget..."
      nsExec::ExecToLog '"powershell.exe" -Command "winget install OpenJS.NodeJS.LTS --silent --accept-package-agreements"'
      Pop $1
      ${If} $1 == 0
        FileWrite $9 "  [OK] winget install OpenJS.NodeJS.LTS exitoso (codigo $1)$\r$\n"
        FileWrite $9 "  [INFO] Buscando npm en rutas de instalacion...$\r$\n"
        StrCpy $2 ""
        IfFileExists "$PROGRAMFILES64\nodejs\npm.cmd" 0 +3
        StrCpy $2 "$PROGRAMFILES64\nodejs\npm.cmd"
        FileWrite $9 "  [OK] npm encontrado en %PROGRAMFILES64%\nodejs$\r$\n"
        ${If} $2 == ""
          IfFileExists "$PROGRAMFILES\nodejs\npm.cmd" 0 +3
          StrCpy $2 "$PROGRAMFILES\nodejs\npm.cmd"
          FileWrite $9 "  [OK] npm encontrado en %PROGRAMFILES%\nodejs$\r$\n"
          ${If} $2 == ""
            IfFileExists "$PROFILE\AppData\Roaming\npm\npm.cmd" 0 +3
            StrCpy $2 "$PROFILE\AppData\Roaming\npm\npm.cmd"
            FileWrite $9 "  [OK] npm encontrado en %APPDATA%\npm$\r$\n"
          ${EndIf}
        ${EndIf}
        ${If} $2 != ""
          FileWrite $9 "  [INFO] Ejecutando: $2 install -g opencode-ai --prefix $PROFILE\AppData\Roaming\npm$\r$\n"
          nsExec::ExecToLog '"cmd.exe" /c "$2 install -g opencode-ai --prefix $PROFILE\AppData\Roaming\npm"'
          Pop $1
          ${If} $1 == 0
            IfFileExists $6 0 +3
            StrCpy $0 0
            FileWrite $9 "  [OK] opencode encontrado en %APPDATA%\npm$\r$\n"
            ${If} $0 != 0
              FileWrite $9 "  [INFO] npm reporta exito pero opencode no esta en %APPDATA%\npm. Buscando...$\r$\n"
              IfFileExists "$PROGRAMFILES64\nodejs\opencode.exe" 0 +3
              StrCpy $0 0
              CopyFiles /SILENT "$PROGRAMFILES64\nodejs\opencode.exe" $6
              FileWrite $9 "  [OK] opencode copiado desde %PROGRAMFILES64%\nodejs$\r$\n"
              ${If} $0 != 0
                IfFileExists "$PROGRAMFILES\nodejs\opencode.exe" 0 +3
                StrCpy $0 0
                CopyFiles /SILENT "$PROGRAMFILES\nodejs\opencode.exe" $6
                FileWrite $9 "  [OK] opencode copiado desde %PROGRAMFILES%\nodejs$\r$\n"
              ${EndIf}
            ${EndIf}
          ${Else}
            FileWrite $9 "  [ERROR] npm install -g opencode-ai falló con código $1$\r$\n"
          ${EndIf}
        ${Else}
          FileWrite $9 "  [ERROR] npm no encontrado incluso despues de winget$\r$\n"
        ${EndIf}
      ${Else}
        FileWrite $9 "  [ERROR] winget falló con código $1 (puede no estar disponible)$\r$\n"
      ${EndIf}
    ${EndIf}
  ${EndIf}

  ${If} $0 != 0
    FileWrite $9 "$\r$\n[4/5] Descargando opencode desde GitHub...$\r$\n"
    DetailPrint "[4/5] Descargando opencode desde GitHub..."
    CreateDirectory "$TEMP\ameli-install"
    nsExec::ExecToLog '"cmd.exe" /c "curl -sL -o $TEMP\ameli-install\opencode.zip https://github.com/anomalyco/opencode/releases/latest/download/opencode-windows-x64.zip"'
    Pop $1
    ${If} $1 == 0
      FileWrite $9 "  [OK] Descarga ZIP completada (curl codigo $1)$\r$\n"
      DetailPrint "Extrayendo e instalando..."
      nsExec::ExecToLog '"powershell.exe" -Command "Expand-Archive -Path $TEMP\ameli-install\opencode.zip -DestinationPath $TEMP\ameli-install -Force; Copy-Item (Get-ChildItem $TEMP\ameli-install\opencode-windows-x64\*.exe | Select-Object -First 1).FullName $PROFILE\AppData\Roaming\npm\opencode.exe -Force"'
      Pop $2
      ${If} $2 == 0
        IfFileExists $6 0 +3
        StrCpy $0 0
        FileWrite $9 "  [OK] opencode copiado a %APPDATA%\npm\opencode.exe$\r$\n"
      ${Else}
        FileWrite $9 "  [ERROR] PowerShell falló con código $2$\r$\n"
      ${EndIf}
      RMDir /r "$TEMP\ameli-install"
    ${Else}
      FileWrite $9 "  [ERROR] curl falló con código $1 (sin conexion o URL invalida)$\r$\n"
    ${EndIf}
  ${EndIf}

  ${If} $0 != 0
    FileWrite $9 "$\r$\n[5/5] Instalacion automatica fallida$\r$\n"
    DetailPrint "[5/5] Instalacion automatica fallida"
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
