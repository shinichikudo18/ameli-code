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
    IfFileExists "$PROFILE\AppData\Roaming\fnm\node-versions\*\installation\node_modules\opencode-ai\bin\opencode.js" 0 +2
    StrCpy $0 0
  ${EndIf}

  ${If} $0 != 0
    DetailPrint "opencode CLI no encontrado. Intentando via npm..."
    ExecWait '"$WINDIR\System32\cmd.exe" /c "npm install -g opencode-ai"' $1
    ${If} $1 != 0
      DetailPrint "npm no disponible. No se pudo instalar automaticamente."
      DetailPrint "Instalalo manualmente desde: https://opencode.ai"
    ${Else}
      DetailPrint "opencode CLI instalado via npm"
    ${EndIf}
  ${Else}
    DetailPrint "opencode CLI ya esta instalado"
  ${EndIf}
!macroend
