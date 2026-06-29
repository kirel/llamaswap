# Repository Instructions

This repository manages a local macOS `llama-swap` setup for Qwen3.6 MTP models via Homebrew and `launchd`.

## Before changing or operating the service

- Keep this repo machine-portable: do not commit absolute machine-specific paths except placeholders in templates.
- Do not commit generated LaunchAgent plists from `~/Library/LaunchAgents/` or runtime logs.

## Key files

- `config.yaml` — `llama-swap` model configuration and aliases.
- `local.llama-swap.plist.template` — LaunchAgent template; preserve `__PROJECT_DIR__`, `__LLAMA_SWAP_BIN__`, and `__PATH_ENV__` placeholders.
- `install-launchd.sh` — renders and installs the user LaunchAgent, then starts it.
- `uninstall-launchd.sh` — stops and removes the installed user LaunchAgent.
- `llama-swap.out.log` / `llama-swap.err.log` — local runtime logs, ignored by git.

## Common commands

Install or cleanly reinstall the LaunchAgent after plist-template changes:

```bash
./install-launchd.sh
```

Fast restart of the already-loaded service:

```bash
launchctl kickstart -k gui/$(id -u)/local.llama-swap
```

Stop and remove the autostart LaunchAgent:

```bash
./uninstall-launchd.sh
```

Check service health:

```bash
curl http://127.0.0.1:8080/health
curl http://127.0.0.1:8080/v1/models
```

Inspect service status:

```bash
launchctl list | rg -i 'llama|swap'
lsof -nP -iTCP:8080 -sTCP:LISTEN
```

Follow logs from the project directory:

```bash
tail -f ./llama-swap.out.log
tail -f ./llama-swap.err.log
```

## Editing guidance

- Preserve OpenAI-compatible endpoint behavior on `127.0.0.1:8080` unless the user explicitly requests a port/listen-address change.
- Keep model IDs in `config.yaml` aligned with the README and Pi `models.json` example:
  - `qwen3.6-27b`
  - `qwen3.6-27b:nothink`
  - `qwen3.6-35b-a3b`
  - `qwen3.6-35b-a3b:nothink`
- The `:nothink` aliases should continue to use `enable_thinking: false` without forcing a separate model reload.
- Be careful with memory-heavy changes. This setup is documented as tested on Apple Silicon with 64 GB unified memory.
- If changing launchd behavior, validate with `plutil -lint local.llama-swap.plist.template` where applicable and reinstall via `./install-launchd.sh`.

## Validation after changes

After configuration or launchd changes, run the relevant checks:

```bash
./install-launchd.sh
curl http://127.0.0.1:8080/health
curl http://127.0.0.1:8080/v1/models
launchctl list | rg -i 'llama|swap'
```

If a restart fails, inspect:

```bash
launchctl print gui/$(id -u)/local.llama-swap
tail -n 50 ./llama-swap.out.log
tail -n 50 ./llama-swap.err.log
```
