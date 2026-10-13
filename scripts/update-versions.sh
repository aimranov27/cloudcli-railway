#!/usr/bin/env bash
# Bumps the pinned versions in the Dockerfile to the latest npm releases.
#
# CloudCLI is bumped as soon as it releases. Claude Code, Codex and OpenCode release
# almost daily, so they are only bumped alongside a CloudCLI release, on
# Mondays, or when FORCE_ALL=1. That keeps "update available" notices for
# template users to roughly one a week.
#
# Prints a markdown summary of changes; prints nothing if nothing changed.
set -euo pipefail

DOCKERFILE="$(dirname "$0")/../Dockerfile"

current() { sed -n "s/^ARG $1=//p" "$DOCKERFILE"; }
latest() { npm view "$1" version; }
bump() { sed -i.bak "s/^ARG $1=.*/ARG $1=$2/" "$DOCKERFILE" && rm -f "$DOCKERFILE.bak"; }

changes=""
check() {
  local arg="$1" pkg="$2" label="$3" old new
  old="$(current "$arg")"
  new="$(latest "$pkg")"
  if [ "$old" != "$new" ]; then
    bump "$arg" "$new"
    changes+="- ${label}: \`${old}\` → \`${new}\`"$'\n'
  fi
}

check CLOUDCLI_VERSION @cloudcli-ai/cloudcli CloudCLI
cloudcli_changed="$changes"

if [ -n "$cloudcli_changed" ] || [ "$(date -u +%u)" = 1 ] || [ "${FORCE_ALL:-}" = 1 ]; then
  check CLAUDE_CODE_VERSION @anthropic-ai/claude-code "Claude Code"
  check CODEX_VERSION @openai/codex Codex
  check OPENCODE_VERSION opencode-ai OpenCode
fi

printf '%s' "$changes"
