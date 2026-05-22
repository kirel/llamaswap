# llama-swap on macOS

Native `llama-swap` setup for local Qwen3.6 MTP models using Homebrew and `launchd`.

## Files

- `config.yaml` — llama-swap model config
- `local.llama-swap.plist.template` — launchd template with `__PROJECT_DIR__` placeholder
- `install-launchd.sh` — generates a machine-local plist in `~/Library/LaunchAgents/` and starts the service
- `uninstall-launchd.sh` — stops the service and removes the generated plist from `~/Library/LaunchAgents/`
- `.gitignore` — ignores local runtime files

## Installed binaries

Installed via Homebrew:

```bash
brew tap mostlygeek/llama-swap
brew install llama-swap llama.cpp
```

The launchd installer auto-detects `llama-swap` from your `PATH`, so no machine-specific binary path needs to be committed.

## Models exposed

Backed by Unsloth MTP GGUFs via `llama-server -hf`, so models are fetched automatically on first load.

- `qwen3.6-27b`
- `qwen3.6-27b:nothink`
- `qwen3.6-35b-a3b`
- `qwen3.6-35b-a3b:nothink`

## Tested hardware

Tested on an Apple Silicon Mac with **64 GB unified memory**.

- `qwen3.6-27b` works well on this setup
- `qwen3.6-35b-a3b` also works, but with less memory headroom
- MTP uses slightly more memory than standard GGUFs
- closing other heavy local AI apps is recommended

The `:nothink` variants use `enable_thinking: false` without forcing a model reload.

MTP best-practice defaults applied from the Unsloth guide:
- `--spec-type draft-mtp`
- `--spec-draft-n-max 2`
- `UD-Q4_K_XL` quant via Hugging Face auto-download

Coding-optimized sampling defaults applied:
- thinking mode: `temperature 0.6`, `top_p 0.95`, `presence_penalty 0.0`
- non-thinking mode: `temperature 1.0`, `top_p 0.95`, `presence_penalty 1.5`

If you want to tune throughput further, Unsloth recommends testing `--spec-draft-n-max` values from `1` to `6`, though `2` is their default recommendation and they do not recommend going above `2` in general.

## Start manually

```bash
cd /path/to/llamaswap
llama-swap --config ./config.yaml --listen 127.0.0.1:8080 --watch-config
```

Endpoint:

```text
http://127.0.0.1:8080
```

## Install autostart

The repo contains no absolute paths. Instead, `install-launchd.sh` detects its own directory and renders `local.llama-swap.plist.template` into a machine-local plist under `~/Library/LaunchAgents/`.

From the project directory:

```bash
cd /path/to/llamaswap
./install-launchd.sh
```

What it does:

- stops any existing `local.llama-swap` user agent
- renders a local plist from `./local.llama-swap.plist.template`
- auto-detects the `llama-swap` binary from your `PATH`
- writes the result to `~/Library/LaunchAgents/local.llama-swap.plist`
- bootstraps the agent with `launchctl`
- starts it immediately

## Stop / uninstall autostart

```bash
cd /path/to/llamaswap
./uninstall-launchd.sh
```

## Restart

Fast restart of the loaded service:

```bash
launchctl kickstart -k gui/$(id -u)/local.llama-swap
```

Clean reinstall after changing the plist:

```bash
cd /path/to/llamaswap
./install-launchd.sh
```

## Logs

Service logs (from the project directory):

```bash
tail -f ./llama-swap.out.log
tail -f ./llama-swap.err.log
```

## Health check

```bash
curl http://127.0.0.1:8080/health
curl http://127.0.0.1:8080/v1/models
```

## Pi coding agent setup

Pi can use `llama-swap` as an OpenAI-compatible local provider. Add the models to:

```text
~/.pi/agent/models.json
```

Recommended configuration:

```json
{
  "providers": {
    "llama-swap": {
      "baseUrl": "http://127.0.0.1:8080/v1",
      "api": "openai-completions",
      "apiKey": "local",
      "compat": {
        "supportsDeveloperRole": false,
        "supportsReasoningEffort": false,
        "maxTokensField": "max_tokens",
        "thinkingFormat": "qwen-chat-template"
      },
      "models": [
        {
          "id": "qwen3.6-27b",
          "name": "Qwen3.6 27B Thinking",
          "reasoning": true,
          "input": ["text"],
          "contextWindow": 262144,
          "maxTokens": 32768,
          "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 }
        },
        {
          "id": "qwen3.6-27b:nothink",
          "name": "Qwen3.6 27B No Thinking",
          "reasoning": false,
          "input": ["text"],
          "contextWindow": 262144,
          "maxTokens": 32768,
          "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 }
        },
        {
          "id": "qwen3.6-35b-a3b",
          "name": "Qwen3.6 35B A3B Thinking",
          "reasoning": true,
          "input": ["text"],
          "contextWindow": 262144,
          "maxTokens": 32768,
          "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 }
        },
        {
          "id": "qwen3.6-35b-a3b:nothink",
          "name": "Qwen3.6 35B A3B No Thinking",
          "reasoning": false,
          "input": ["text"],
          "contextWindow": 262144,
          "maxTokens": 32768,
          "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 }
        }
      ]
    }
  }
}
```

Notes:

- `apiKey` is required by Pi's provider config, but `llama-swap` ignores it; any non-empty value works.
- `supportsDeveloperRole: false` makes Pi send the main instruction as a `system` message, which is safer for `llama.cpp` OpenAI compatibility.
- `supportsReasoningEffort: false` prevents Pi from sending OpenAI-specific `reasoning_effort` parameters.
- The `:nothink` model IDs use the `enable_thinking: false` aliases configured in `config.yaml` and avoid a model reload.
- After editing `models.json`, open `/model` in Pi; the file is reloaded when the model picker opens.

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

- Models are now fetched directly from Hugging Face via `llama-server -hf` on first use.
- MTP uses slightly more RAM/VRAM than standard GGUFs; keep roughly ~1 GB extra headroom per loaded model.
- Unsloth notes that thinking mode and non-thinking mode use different recommended sampling params; those presets are configured in `config.yaml`.
- `llama-swap` is configured with `--watch-config`, so config changes are picked up automatically, but a restart is still the cleanest option after larger edits.
