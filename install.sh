#!/bin/bash
set -e

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        AMELI Code Installer          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}¿Dónde tenés tu proyecto de OpenCode?${NC}"
echo -e "  (Dejalo vacío si usás el default: ${GREEN}~/Opencode${NC})"
read -p "Ruta: " PROJECT_DIR
PROJECT_DIR="${PROJECT_DIR:-$HOME/Opencode}"
PROJECT_DIR="${PROJECT_DIR/#\~/$HOME}"

if [ -d "$PROJECT_DIR/.git" ] || [ -d "$PROJECT_DIR" ]; then
  echo -e "${GREEN}✅ Proyecto encontrado en: $PROJECT_DIR${NC}"
else
  echo ""
  echo -e "${YELLOW}⚠️  No existe: $PROJECT_DIR${NC}"
  read -p "¿Querés crearlo? (s/N): " CREATE_DIR
  if [[ "$CREATE_DIR" =~ ^[sS]$ ]]; then
    mkdir -p "$PROJECT_DIR"
    echo -e "${GREEN}✅ Creado: $PROJECT_DIR${NC}"
  else
    echo -e "${YELLOW}Continuando sin proyecto. Después podés usar 'Nuevo proyecto' en la app.${NC}"
    PROJECT_DIR=""
  fi
fi

echo ""
echo -e "${YELLOW}Instalando dependencias...${NC}"
cd "$APP_DIR"
npm install
echo -e "${GREEN}✅ Dependencias instaladas${NC}"

echo ""
echo -e "${YELLOW}Guardando configuración...${NC}"
CONFIG_DIR="$HOME/.config/ameli-code"
mkdir -p "$CONFIG_DIR"
if [ -n "$PROJECT_DIR" ]; then
  echo "{\"projectDir\": \"$PROJECT_DIR\"}" > "$CONFIG_DIR/config.json"
  echo -e "${GREEN}✅ Proyecto configurado: $PROJECT_DIR${NC}"
else
  echo "{}" > "$CONFIG_DIR/config.json"
  echo -e "${GREEN}✅ Config creada (sin proyecto)${NC}"
fi

echo ""
echo -e "${YELLOW}Creando acceso directo en el menú...${NC}"
ICON_SRC="$APP_DIR/assets/logo/ameli-icon.png"
mkdir -p "$HOME/.local/share/icons"
if [ -f "$ICON_SRC" ]; then
  cp "$ICON_SRC" "$HOME/.local/share/icons/ameli-code.png"
  echo -e "${GREEN}✅ Icono instalado${NC}"
else
  echo -e "${RED}⚠️  No se encontró el icono en $ICON_SRC${NC}"
fi

DESKTOP_FILE="$HOME/.local/share/applications/ameli-code.desktop"
cat > "$DESKTOP_FILE" << DESKTOP_EOF
[Desktop Entry]
Name=AMELI Code
Comment=App de AMELI para gestionar sesiones de opencode
Exec=$APP_DIR/node_modules/.bin/electron $APP_DIR
Icon=ameli-code
Terminal=false
Type=Application
Categories=Development;Utility;
StartupWMClass=AMELI Code
DESKTOP_EOF
chmod +x "$DESKTOP_FILE"
echo -e "${GREEN}✅ Acceso directo creado: $DESKTOP_FILE${NC}"

echo ""
echo -e "${YELLOW}Verificando opencode CLI...${NC}"
if command -v opencode &> /dev/null; then
  echo -e "${GREEN}✅ opencode CLI disponible: $(which opencode)${NC}"
elif command -v opencode-cli &> /dev/null; then
  echo -e "${YELLOW}⚠️  opencode-cli encontrado, creando enlace...${NC}"
  if [ -w "/usr/local/bin" ]; then
    ln -sf /usr/bin/opencode-cli /usr/local/bin/opencode
    echo -e "${GREEN}✅ Enlace creado en /usr/local/bin/opencode${NC}"
  else
    mkdir -p "$HOME/.local/bin"
    ln -sf /usr/bin/opencode-cli "$HOME/.local/bin/opencode"
    echo -e "${GREEN}✅ Enlace creado en $HOME/.local/bin/opencode${NC}"
    echo -e "${YELLOW}   Asegurate de tener ~/.local/bin en tu PATH${NC}"
  fi
else
  echo -e "${YELLOW}⚠️  opencode CLI no encontrado. Instalalo desde https://opencode.ai${NC}"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Instalación completa 🎉          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"
echo ""
echo -e "  Para abrir AMELI Code, buscá en tu menú de aplicaciones o ejecutá:"
echo -e "    ${GREEN}$APP_DIR/node_modules/.bin/electron $APP_DIR${NC}"
echo ""
