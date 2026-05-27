#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Uso: ./scripts/release.sh <version>"
  echo "Ej:  ./scripts/release.sh 1.2.0"
  exit 1
fi

VERSION="$1"
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$APP_DIR"

echo "Actualizando package.json a v$VERSION..."
sed -i "s/\"version\": \".*\"/\"version\": \"$VERSION\"/" package.json

echo "Actualizando version.json..."
cat > version.json << JSON
{
  "latest": "$VERSION",
  "releaseUrl": "https://github.com/shinichikudo18/ameli-code/releases/tag/v$VERSION",
  "downloadUrl": "https://github.com/shinichikudo18/ameli-code/releases/download/v$VERSION/AMELI.Code.Setup.$VERSION.exe"
}
JSON

echo "Haciendo commit y tag v$VERSION..."
git add package.json version.json
git commit -m "bump version to $VERSION"
git tag "v$VERSION"
git push && git push origin "v$VERSION"

echo "Buildeando .exe para Windows..."
npm run build:win

echo "Creando release en GitHub..."
gh release create "v$VERSION" \
  "dist/AMELI Code Setup $VERSION.exe" \
  --title "AMELI Code v$VERSION" \
  --notes "Release v$VERSION"

echo ""
echo "✅ Release v$VERSION creada y publicada:"
echo "   https://github.com/shinichikudo18/ameli-code/releases/tag/v$VERSION"
