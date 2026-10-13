# CloudCLI on Railway

Run [CloudCLI](https://github.com/siteboon/claudecodeui) (Claude Code UI) on an always-on Railway server and use Claude Code, Codex or OpenCode from any browser, including your phone.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/cloudcli-claude-code-ui?utm_medium=integration&utm_source=template&utm_campaign=cloudcli)

## What you get

- CloudCLI web UI: chat, file tree and editor, git, terminal, MCP settings.
- Claude Code, OpenAI Codex and OpenCode CLIs preinstalled.
- A persistent volume: your projects, sessions and agent logins survive redeploys.
- A login created for you on first boot, so nobody else can claim your instance.

## After deploying

1. Open the service's public URL.
2. Sign in with `CLOUDCLI_USERNAME` and `CLOUDCLI_PASSWORD`. You'll find them in the service's **Variables** tab. The password was generated for you.
3. Connect an agent. Either:
   - open the **Shell** tab, run `claude`, and follow the login link (works with a Claude Pro/Max subscription), or
   - set `ANTHROPIC_API_KEY` (or `CLAUDE_CODE_OAUTH_TOKEN` from `claude setup-token`) in **Variables**.

   For Codex, run `codex` in the shell and log in, or set `OPENAI_API_KEY`.
   For OpenCode, run `opencode auth login` in the shell, or set the API key variable for your provider (for example `OPENROUTER_API_KEY`).
4. Create or clone projects under `~/projects`.

## Variables

| Variable | Default | Purpose |
|---|---|---|
| `CLOUDCLI_USERNAME` | `admin` | Login created on first boot |
| `CLOUDCLI_PASSWORD` | generated | Password for that login |
| `ANTHROPIC_API_KEY` | — | Optional. Claude API key instead of logging in |
| `CLAUDE_CODE_OAUTH_TOKEN` | — | Optional. Token from `claude setup-token` |
| `OPENAI_API_KEY` | — | Optional. For Codex |
| `OPENROUTER_API_KEY` | — | Optional. For OpenCode. One key gives access to many models |

Public networking should point at port `8080`, the port Railway gives the service by default.

The login is only created on the first boot. Changing `CLOUDCLI_PASSWORD` later does not change it. Use CloudCLI's settings instead.

## Storage

The volume is mounted at `/data`, and `HOME` is `/data/home`. Everything CloudCLI, Claude Code, Codex and OpenCode save lives there.

## Updates

This template pins the CloudCLI, Claude Code, Codex and OpenCode versions. A GitHub Action checks npm every day:

- New CloudCLI releases are picked up the same day.
- Claude Code, Codex and OpenCode are bumped weekly, or together with a CloudCLI release.
- Every bump is built and smoke-tested before it is merged. Failed bumps open an issue instead.

When a bump lands, Railway shows an **update available** notice in your project. Updates are opt-in: apply them when it suits you. Your volume is kept.

## License

The files in this repository are MIT licensed. CloudCLI itself is [AGPL-3.0](https://github.com/siteboon/claudecodeui/blob/main/LICENSE) and is installed unmodified from npm. Claude Code, Codex and OpenCode are subject to their own licenses and terms.
