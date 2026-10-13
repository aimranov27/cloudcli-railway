#!/usr/bin/env bash
# Builds the image and checks the things a template user depends on:
# the server starts, the account is pre-created, nobody else can register,
# and the account survives a restart. Used locally and by CI.
set -euo pipefail

IMAGE="${IMAGE:-cloudcli-railway:smoke}"
NAME="cloudcli-smoke-$$"
VOLUME="cloudcli-smoke-$$"
PORT="${SMOKE_PORT:-38080}"
USERNAME=admin
PASSWORD="smoke-$(openssl rand -hex 8)"

cleanup() {
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  docker volume rm "$VOLUME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

fail() { echo "FAIL: $*" >&2; docker logs "$NAME" 2>&1 | tail -n 50 >&2 || true; exit 1; }

start() {
  docker run -d --name "$NAME" -p "$PORT:3001" -v "$VOLUME:/data" \
    -e CLOUDCLI_USERNAME="$USERNAME" -e CLOUDCLI_PASSWORD="$PASSWORD" "$IMAGE" >/dev/null
  for _ in $(seq 1 90); do
    curl -fsS "http://127.0.0.1:$PORT/health" >/dev/null 2>&1 && return 0
    sleep 1
  done
  fail "server did not become healthy"
}

login_status() {
  curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' \
    -d "{\"username\":\"$USERNAME\",\"password\":\"$1\"}" "http://127.0.0.1:$PORT/api/auth/login"
}

if [ -z "${SKIP_BUILD:-}" ]; then
  docker build -t "$IMAGE" "$(dirname "$0")/.."
fi

echo "== versions"
docker run --rm --entrypoint sh "$IMAGE" -c 'cloudcli version; claude --version; codex --version'

echo "== first boot"
start
[ "$(curl -fsS "http://127.0.0.1:$PORT/api/auth/status" | jq -r .needsSetup)" = "false" ] \
  || fail "account was not pre-created"
[ "$(login_status "$PASSWORD")" = "200" ] || fail "login with the configured password failed"
[ "$(login_status wrong-password)" = "401" ] || fail "login with a wrong password did not return 401"
code="$(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' \
  -d '{"username":"intruder","password":"intruder123"}' "http://127.0.0.1:$PORT/api/auth/register")"
[ "$code" = "403" ] || fail "a second account could be registered (HTTP $code)"
curl -fsS "http://127.0.0.1:$PORT/" | grep -qi '<html' || fail "web UI did not load"
[ "$(docker exec "$NAME" ps -o user= -p 1 | tr -d ' ')" = "coder" ] \
  || fail "server is not running as the unprivileged user"

echo "== restart keeps the account"
docker rm -f "$NAME" >/dev/null
start
[ "$(login_status "$PASSWORD")" = "200" ] || fail "login failed after restart"

echo "PASS"
