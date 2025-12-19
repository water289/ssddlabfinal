#!/usr/bin/env bash
set -euo pipefail

HOST="0.0.0.0"
PORT="8000"
APP="main:app"

if [[ -n "${SSL_CERTFILE:-}" && -n "${SSL_KEYFILE:-}" ]]; then
  exec uvicorn "$APP" --host "$HOST" --port "$PORT" --ssl-keyfile "$SSL_KEYFILE" --ssl-certfile "$SSL_CERTFILE"
else
  exec uvicorn "$APP" --host "$HOST" --port "$PORT"
fi
