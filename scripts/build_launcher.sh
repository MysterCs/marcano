#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKIP_WEB_BUILD=false

if [[ "${1:-}" == "--skip-web-build" ]]; then
  SKIP_WEB_BUILD=true
fi

if [[ "$SKIP_WEB_BUILD" == "false" ]]; then
  pushd "$ROOT/flutter_app" >/dev/null
  "$ROOT/scripts/flutter.sh" build web --release
  popd >/dev/null
fi

if [[ ! -x "$ROOT/.venv/bin/python" ]]; then
  echo "No se encontro el entorno virtual en $ROOT/.venv." >&2
  exit 1
fi

"$ROOT/.venv/bin/python" -m PyInstaller \
  --onefile \
  --windowed \
  --name MarcanoControl \
  --distpath "$ROOT" \
  --workpath "$ROOT/.tools/pyinstaller" \
  --specpath "$ROOT/.tools/pyinstaller" \
  "$ROOT/launcher/control.py"

echo "Ejecutable creado en $ROOT/MarcanoControl"
