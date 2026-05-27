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
      MessageBox MB_YESNO "AMELI Code necesita opencode CLI para funcionar.$\n$\n¿Querés que lo descargue e instale automáticamente?" IDYES download IDNO skip
      download:
        DetailPrint "Descargando opencode CLI desde GitHub..."
        ExecWait '"$WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -Command "
          \$zip = \"\$env:TEMP\opencode-windows-x64.zip\"
          \$dest = \"\$env:LOCALAPPDATA\opencode\"
          [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
          Invoke-WebRequest -Uri \"https://github.com/anomalyco/opencode/releases/latest/download/opencode-windows-x64.zip\" -OutFile \$zip
          Remove-Item -Path \$dest -Recurse -Force -ErrorAction SilentlyContinue
          Expand-Archive -Path \$zip -DestinationPath \$dest -Force
          Remove-Item \$zip -Force
          \$binPath = \"\$dest\opencode-windows-x64\"
          \$ren = Get-ChildItem -Path \$binPath -Filter *.exe | Select-Object -First 1
          if (\$ren) { Rename-Item \$ren.FullName \"\$binPath\opencode.exe\" -Force }
          \$currentPath = [Environment]::GetEnvironmentVariable(\"PATH\", \"User\")
          if (\$currentPath -notlike \"*\$binPath*\") {
            [Environment]::SetEnvironmentVariable(\"PATH\", \"\$currentPath;\$binPath\", \"User\")
          }
        "' $2
        ${If} $2 == 0
          DetailPrint "opencode CLI instalado correctamente"
        ${Else}
          DetailPrint "No se pudo descargar automaticamente."
          DetailPrint "Instalalo manualmente desde: https://opencode.ai"
        ${EndIf}
      skip:
    ${Else}
      DetailPrint "opencode CLI instalado via npm"
    ${EndIf}
  ${Else}
    DetailPrint "opencode CLI ya esta instalado"
  ${EndIf}
!macroend
