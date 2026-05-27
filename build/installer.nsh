!macro customInstall
  DetailPrint "Verificando opencode CLI..."
  ExecWait '"$WINDIR\System32\cmd.exe" /c "where opencode >nul 2>nul"' $0
  ${If} $0 != 0
    DetailPrint "opencode CLI no encontrado. Intentando instalar..."
    SetDetailsView show
    ExecWait '"$WINDIR\System32\cmd.exe" /c "npm install -g opencode-ai"' $1
    ${If} $1 != 0
      DetailPrint "npm no disponible. Probando chocolatey..."
      ExecWait '"$WINDIR\System32\cmd.exe" /c "choco install opencode -y"' $2
      ${If} $2 != 0
        DetailPrint "No se pudo instalar opencode CLI."
        MessageBox MB_OK "AMELI Code necesita opencode CLI para funcionar.$\n$\nNo se pudo instalar automaticamente.$\nInstalalo manualmente desde:$\nhttps://opencode.ai"
      ${Else}
        DetailPrint "opencode CLI instalado via chocolatey"
      ${EndIf}
    ${Else}
      DetailPrint "opencode CLI instalado via npm"
    ${EndIf}
  ${Else}
    DetailPrint "opencode CLI ya esta instalado"
  ${EndIf}
!macroend
