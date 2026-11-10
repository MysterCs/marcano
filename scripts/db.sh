#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-status}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="$ROOT/data/postgresql"
LOG_FILE="$ROOT/data/postgresql.log"

case "$ACTION" in
  start)
    pg_ctl -D "$DATA_DIR" -l "$LOG_FILE" -o "-p 5433 -k /tmp" -w start
    ;;
  stop)
    pg_ctl -D "$DATA_DIR" -m fast -w stop
    ;;
  status)
    pg_ctl -D "$DATA_DIR" status
    ;;
  *)
    echo "Uso: $0 {start|stop|status}" >&2
    exit 1
    ;;
esac

