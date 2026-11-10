#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8000}"

if ! "$ROOT/scripts/db.sh" status >/dev/null 2>&1; then
  echo "Iniciando PostgreSQL en el puerto 5433..."
  "$ROOT/scripts/db.sh" start
fi

pkill -f "launcher.server" 2>/dev/null || true

export PYTHONPATH="$ROOT/src"
echo "Iniciando Marcano Inventario (API + Web) en http://$HOST:$PORT ..."
exec "$ROOT/.venv/bin/python" -m launcher.server \
  --host "$HOST" \
  --port "$PORT" \
  --web-root "$ROOT/flutter_app/build/web"

