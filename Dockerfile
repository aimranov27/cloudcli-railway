# CloudCLI (Claude Code UI) for Railway, with Claude Code, Codex and OpenCode.
# Versions are pinned so every deploy is reproducible. The update workflow
# (.github/workflows/update.yml) bumps them automatically after a smoke test.
FROM node:22-bookworm-slim

ARG CLOUDCLI_VERSION=1.37.5
ARG CLAUDE_CODE_VERSION=2.1.302
ARG CODEX_VERSION=0.163.0
ARG OPENCODE_VERSION=1.19.3

# Build tools are needed for native modules (node-pty, better-sqlite3, bcrypt).
# The rest is what coding agents commonly expect to find on the box.
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential python3 python3-setuptools \
      ca-certificates curl git gosu jq openssh-client procps ripgrep sqlite3 tree unzip vim-tiny zip \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g --no-audit --no-fund \
      "@cloudcli-ai/cloudcli@${CLOUDCLI_VERSION}" \
      "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
      "@openai/codex@${CODEX_VERSION}" \
      "opencode-ai@${OPENCODE_VERSION}" \
    && npm cache clean --force \
    && cloudcli version && claude --version && codex --version && opencode --version

# Run as an unprivileged user; the entrypoint fixes volume ownership first.
RUN useradd --create-home --shell /bin/bash coder

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENV DATA_DIR=/data \
    DISABLE_AUTOUPDATER=1 \
    OPENCODE_DISABLE_AUTOUPDATE=1 \
    PORT=8080 \
    NODE_ENV=production

EXPOSE 8080
ENTRYPOINT ["docker-entrypoint.sh"]
