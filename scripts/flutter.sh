#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS="$ROOT/.tools"
FLUTTER_BIN="$TOOLS/flutter/bin"

if [[ -x "$FLUTTER_BIN/flutter" ]]; then
  export PATH="$FLUTTER_BIN:$PATH"
elif ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter no esta instalado en $TOOLS/flutter ni en el PATH." >&2
  exit 1
fi

export PUB_CACHE="$TOOLS/pub-cache"
export FLUTTER_SUPPRESS_ANALYTICS="true"

exec flutter "$@"

