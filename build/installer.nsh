!macro customInstall
  DetailPrint "Verificando opencode CLI..."
  SetDetailsView show

  StrCpy $0 0

  ExecWait '"$WINDIR\System32\cmd.exe" /c "where opencode >nul 2>nul"' $0
  ${If} $0 != 0
    IfFileExists "$PROFILE\AppData\Roaming\npm\opencode.exe" 0 +2
    StrCpy $0 0
  ${EndIf}

  ${If} $0 != 0
    DetailPrint "Buscando npm..."
    StrCpy $2 ""
    ExecWait '"$WINDIR\System32\cmd.exe" /c "where npm >nul 2>nul"' $1
    ${If} $1 == 0
      StrCpy $2 "npm"
    ${Else}
      IfFileExists "$PROFILE\AppData\Roaming\npm\npm.cmd" 0 +2
      StrCpy $2 "$PROFILE\AppData\Roaming\npm\npm.cmd"
      ${If} $2 == ""
        IfFileExists "$PROGRAMFILES64\nodejs\npm.cmd" 0 +2
        StrCpy $2 "$PROGRAMFILES64\nodejs\npm.cmd"
        ${If} $2 == ""
          IfFileExists "$PROGRAMFILES\nodejs\npm.cmd" 0 +2
          StrCpy $2 "$PROGRAMFILES\nodejs\npm.cmd"
        ${EndIf}
      ${EndIf}
    ${EndIf}

    ${If} $2 != ""
      DetailPrint "Instalando opencode via npm..."
      ExecWait '"$WINDIR\System32\cmd.exe" /c ""$2" install -g opencode-ai"' $1
      ${If} $1 == 0
        StrCpy $0 0
        DetailPrint "opencode CLI instalado via npm"
      ${EndIf}
    ${EndIf}
  ${EndIf}

  ${If} $0 != 0
    DetailPrint "Descargando opencode desde GitHub..."
    CreateDirectory "$TEMP\ameli-install"
    ExecWait '"$WINDIR\System32\curl.exe" -sL -o "$TEMP\ameli-install\opencode.zip" "https://github.com/anomalyco/opencode/releases/latest/download/opencode-windows-x64.zip"' $1
    ${If} $1 == 0
      ExecWait "$\"$WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe$\" -Command $\"Expand-Archive -Path '$TEMP\ameli-install\opencode.zip' -DestinationPath '$TEMP\ameli-install' -Force; $$exe = (Get-ChildItem '$TEMP\ameli-install\opencode-windows-x64\*.exe' | Select-Object -First 1).FullName; Copy-Item $$exe '$PROFILE\AppData\Roaming\npm\opencode.exe' -Force$\"" $2
      ${If} $2 == 0
        IfFileExists "$PROFILE\AppData\Roaming\npm\opencode.exe" 0 +2
        StrCpy $0 0
      ${EndIf}
      RMDir /r "$TEMP\ameli-install"
    ${EndIf}
  ${EndIf}

  ${If} $0 != 0
    DetailPrint "No se pudo instalar opencode automaticamente."
    MessageBox MB_YESNO "$\r$\nNo se encontró npm (Node.js).$\r$\n$\r$\n¿Querés descargar Node.js para que AMELI Code pueda instalar opencode?" IDYES installNode IDNO askOpen
    installNode:
      ExecShell "open" "https://nodejs.org"
    askOpen:
    MessageBox MB_YESNO "$\r$\n¿Querés ir a opencode.ai para descargar opencode manualmente?" IDYES openOC IDNO done
    openOC:
      ExecShell "open" "https://opencode.ai"
    done:
  ${Else}
    DetailPrint "opencode CLI listo"
  ${EndIf}
!macroend
