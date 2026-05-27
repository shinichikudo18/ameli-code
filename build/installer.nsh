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
    DetailPrint "opencode CLI no encontrado. Intentando via npm..."
    ExecWait '"$WINDIR\System32\cmd.exe" /c "npm install -g opencode-ai"' $1
    ${If} $1 != 0
      DetailPrint "npm no disponible."
      MessageBox MB_YESNO "¿Querés descargar Node.js (incluye npm) para que AMELI Code pueda instalar opencode automáticamente?" IDYES installNode IDNO askOpencode
      installNode:
        ExecShell "open" "https://nodejs.org"
        DetailPrint "Después de instalar Node.js, ejecutá: npm install -g opencode-ai"
        Goto askOpencode
      askOpencode:
        MessageBox MB_YESNO "¿Querés ir a opencode.ai para descargar opencode CLI?" IDYES openOC IDNO done
      openOC:
        ExecShell "open" "https://opencode.ai"
      done:
    ${Else}
      DetailPrint "opencode CLI instalado via npm"
    ${EndIf}
  ${Else}
    DetailPrint "opencode CLI ya esta instalado"
  ${EndIf}
!macroend
