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
      MessageBox MB_YESNO "AMELI Code necesita opencode CLI para funcionar.$\n$\n¿Querés que se abra la página de descarga?" IDYES download IDNO skip
      download:
        ExecShell "open" "https://opencode.ai"
      skip:
    ${Else}
      DetailPrint "opencode CLI instalado via npm"
    ${EndIf}
  ${Else}
    DetailPrint "opencode CLI ya esta instalado"
  ${EndIf}
!macroend
