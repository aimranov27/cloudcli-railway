#!/usr/bin/env bash
# Starts CloudCLI with all state on the persistent volume.
#
# CloudCLI is single-user and lets whoever opens it first create the account.
# On a public URL that is a takeover risk, so when CLOUDCLI_USERNAME and
# CLOUDCLI_PASSWORD are set we create that account on a loopback-only server
# before the public port ever opens.
set -euo pipefail

DATA_DIR="${DATA_DIR:-/data}"
APP_USER=coder

log() { echo "[railway-entrypoint] $*"; }

# Railway mounts volumes as root. Fix ownership once, then drop privileges.
if [ "$(id -u)" = 0 ]; then
  mkdir -p "$DATA_DIR"
  if [ "$(stat -c %U "$DATA_DIR")" != "$APP_USER" ]; then
    log "Giving $APP_USER ownership of $DATA_DIR"
    chown -R "$APP_USER:$APP_USER" "$DATA_DIR"
  fi
  exec gosu "$APP_USER" "$0" "$@"
fi

# Everything CloudCLI and the agents write (auth.db, ~/.claude,
# ~/.codex, projects) lives under HOME, so put HOME on the volume.
export HOME="$DATA_DIR/home"
mkdir -p "$HOME/.cloudcli" "$HOME/projects"
cd "$HOME"

SEED_MARKER="$HOME/.cloudcli/.railway-account-created"
SEED_PORT=39871

seed_account() {
  log "Creating the CloudCLI account on a private loopback server"
  SERVER_PORT="$SEED_PORT" HOST=127.0.0.1 cloudcli start >/tmp/cloudcli-seed.log 2>&1 &
  local pid=$!

  local ready=""
  for _ in $(seq 1 60); do
    if curl -fsS "http://127.0.0.1:$SEED_PORT/health" >/dev/null 2>&1; then ready=1; break; fi
    if ! kill -0 "$pid" 2>/dev/null; then break; fi
    sleep 1
  done
  if [ -z "$ready" ]; then
    cat /tmp/cloudcli-seed.log >&2 || true
    log "ERROR: CloudCLI did not start on the loopback port"
    kill "$pid" 2>/dev/null || true
    exit 1
  fi

  local needs_setup
  needs_setup="$(curl -fsS "http://127.0.0.1:$SEED_PORT/api/auth/status" | jq -r '.needsSetup')"
  if [ "$needs_setup" = "true" ]; then
    jq -n --arg u "$CLOUDCLI_USERNAME" --arg p "$CLOUDCLI_PASSWORD" '{username: $u, password: $p}' \
      | curl -fsS -X POST -H 'Content-Type: application/json' --data @- \
          "http://127.0.0.1:$SEED_PORT/api/auth/register" >/dev/null
    log "Account '$CLOUDCLI_USERNAME' created"
  else
    log "An account already exists; leaving it unchanged"
  fi
  touch "$SEED_MARKER"

  kill "$pid"
  wait "$pid" 2>/dev/null || true
}

if [ ! -f "$SEED_MARKER" ]; then
  if [ -n "${CLOUDCLI_USERNAME:-}" ] && [ -n "${CLOUDCLI_PASSWORD:-}" ]; then
    seed_account
  else
    log "WARNING: CLOUDCLI_USERNAME/CLOUDCLI_PASSWORD are not set."
    log "WARNING: The first person to open this URL can create the account."
  fi
fi

export HOST=0.0.0.0
export SERVER_PORT="${PORT:-8080}"
log "Starting CloudCLI $(cloudcli version 2>/dev/null | tail -n1) on port $SERVER_PORT"
exec cloudcli start "$@"
