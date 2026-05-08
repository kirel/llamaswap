# llama-swap on macOS

Native `llama-swap` setup for local Qwen3.6 models using Homebrew and `launchd`.

## Files

- `config.yaml` — llama-swap model config
- `com.daniel.llama-swap.plist` — launchd service definition kept in this project
- `install-launchd.sh` — installs the plist by symlinking it into `~/Library/LaunchAgents/` and starts the service
- `uninstall-launchd.sh` — stops the service and removes the symlink from `~/Library/LaunchAgents/`
- `.gitignore` — ignores local log files

## Installed binaries

Installed via Homebrew:

```bash
brew tap mostlygeek/llama-swap
brew install llama-swap llama.cpp
```

Binary paths:

```bash
/opt/homebrew/bin/llama-swap
/opt/homebrew/bin/llama-server
```

## Models exposed

- `qwen3.6-27b`
- `qwen3.6-27b:nothink`
- `qwen3.6-35b-a3b`
- `qwen3.6-35b-a3b:nothink`

The `:nothink` variants use `enable_thinking: false` without forcing a model reload.

## Start manually

```bash
cd ~/code/llamaswap
/opt/homebrew/bin/llama-swap --config ./config.yaml --listen 127.0.0.1:8080 --watch-config
```

Endpoint:

```text
http://127.0.0.1:8080
```

## Install autostart

From the project directory:

```bash
cd ~/code/llamaswap
./install-launchd.sh
```

What it does:

- stops any existing `com.daniel.llama-swap` user agent
- symlinks `./com.daniel.llama-swap.plist` to `~/Library/LaunchAgents/com.daniel.llama-swap.plist`
- bootstraps the agent with `launchctl`
- starts it immediately

## Stop / uninstall autostart

```bash
cd ~/code/llamaswap
./uninstall-launchd.sh
```

## Restart

Fast restart of the loaded service:

```bash
launchctl kickstart -k gui/$(id -u)/com.daniel.llama-swap
```

Clean reinstall after changing the plist:

```bash
cd ~/code/llamaswap
./install-launchd.sh
```

## Logs

Service logs:

```bash
tail -f ~/code/llamaswap/llama-swap.out.log
tail -f ~/code/llamaswap/llama-swap.err.log
```

## Health check

```bash
curl http://127.0.0.1:8080/health
curl http://127.0.0.1:8080/v1/models
```

## Example requests

List models:

```bash
curl http://127.0.0.1:8080/v1/models
```

Chat completion with thinking enabled:

```bash
curl http://127.0.0.1:8080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "qwen3.6-27b",
    "messages": [{"role": "user", "content": "Explain mmap simply."}],
    "stream": false
  }'
```

Chat completion with thinking disabled:

```bash
curl http://127.0.0.1:8080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "qwen3.6-27b:nothink",
    "messages": [{"role": "user", "content": "Explain mmap simply."}],
    "stream": false
  }'
```

## Notes

- Models are read directly from `~/.lmstudio/models`.
- Do not keep the same model loaded in LM Studio at the same time if you want to avoid duplicate RAM/VRAM usage.
- `llama-swap` is configured with `--watch-config`, so config changes are picked up automatically, but a restart is still the cleanest option after larger edits.
