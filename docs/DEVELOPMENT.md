# Development Guide

## Requirements

- **Node.js** >= 22.12.0
- **pnpm** 10.23.0 (specified in `package.json` via `packageManager`)

## Setup

```bash
git clone https://github.com/orchid/orchid.git
cd orchid

pnpm install
pnpm ui:build   # auto-installs UI deps on first run
pnpm build
```

Copy `.env.example` to `.env` (or `~/.orchid/.env` for daemon mode) and set at least one LLM provider key:

```bash
cp .env.example .env
# Edit .env — set OPENAI_API_KEY, ANTHROPIC_API_KEY, or another provider key
```

## Running the Gateway

```bash
# Production-like (from build output)
pnpm orchid gateway --port 18789 --verbose

# Development (skip channels, fast startup)
pnpm gateway:dev

# Development with file watcher (auto-rebuild on changes)
pnpm gateway:watch
```

`pnpm gateway:dev` sets `ORCHID_SKIP_CHANNELS=1` so you can iterate on core logic without configuring bot tokens.

## Code Quality

Run all checks (same as CI):

```bash
pnpm check   # format:check + tsgo + lint
```

Individual tools:

| Command             | What it does                    |
| ------------------- | ------------------------------- |
| `pnpm format`       | Format code (oxfmt)             |
| `pnpm format:check` | Check formatting without fixing |
| `pnpm tsgo`         | Type check                      |
| `pnpm lint`         | Lint (oxlint, type-aware)       |
| `pnpm lint:fix`     | Lint with auto-fix              |

## Tests

```bash
# Fast unit tests
pnpm test:fast

# All unit tests (parallel)
pnpm test

# Watch mode (interactive)
pnpm test:watch

# Single file
npx vitest run src/agents/model-config/model-catalog.test.ts

# Single extension
npx vitest run extensions/telegram/

# Full suite (lint + build + unit + e2e + live + docker)
pnpm test:all
```

Specialized suites:

| Command              | Scope                                |
| -------------------- | ------------------------------------ |
| `pnpm test:e2e`      | End-to-end tests                     |
| `pnpm test:gateway`  | Gateway-specific tests               |
| `pnpm test:live`     | Live API tests (needs provider keys) |
| `pnpm test:ui`       | React UI component tests             |
| `pnpm test:coverage` | Unit tests with coverage report      |

Coverage thresholds: 70% lines/functions/statements, 55% branches.

## Environment Variables

**Core:**

| Variable               | Purpose                                                  |
| ---------------------- | -------------------------------------------------------- |
| `ORCHID_GATEWAY_TOKEN` | Gateway auth token (required if binding beyond loopback) |
| `ORCHID_STATE_DIR`     | State directory (default: `~/.orchid`)                   |
| `ORCHID_CONFIG_PATH`   | Config file path (default: `~/.orchid/orchid.json`)      |

**LLM providers** (set at least one):

| Variable             | Provider      |
| -------------------- | ------------- |
| `OPENAI_API_KEY`     | OpenAI        |
| `ANTHROPIC_API_KEY`  | Anthropic     |
| `GEMINI_API_KEY`     | Google Gemini |
| `OPENROUTER_API_KEY` | OpenRouter    |

**Channel tokens** (only for channels you enable):

| Variable                              | Channel  |
| ------------------------------------- | -------- |
| `TELEGRAM_BOT_TOKEN`                  | Telegram |
| `DISCORD_BOT_TOKEN`                   | Discord  |
| `SLACK_BOT_TOKEN` + `SLACK_APP_TOKEN` | Slack    |

**Dev/test flags:**

| Variable                     | Effect                                        |
| ---------------------------- | --------------------------------------------- |
| `ORCHID_SKIP_CHANNELS=1`     | Skip channel initialization                   |
| `ORCHID_LIVE_TEST=1`         | Enable live testing                           |
| `ORCHID_TEST_PROFILE=serial` | Serial test execution (low-resource machines) |

Env precedence (highest to lowest): process env > `./.env` > `~/.orchid/.env` > `orchid.json` `env` block.

## Extension Development

Extensions live in `extensions/<name>/`. Each has:

```
extensions/my-extension/
├── index.ts                  # Plugin entry point
├── package.json              # With "orchid" metadata
├── orchid.plugin.json      # Plugin manifest (optional)
├── README.md
└── src/
    ├── channel.ts            # Channel adapter (if channel plugin)
    └── channel.test.ts
```

Entry point pattern:

```typescript
import type { OrchidPluginApi } from "orchid/plugin-sdk";
import { emptyPluginConfigSchema } from "orchid/plugin-sdk";

export default {
  id: "my-extension",
  name: "My Extension",
  configSchema: emptyPluginConfigSchema(),
  register(api: OrchidPluginApi) {
    // Register channels, hooks, tools, etc.
  },
};
```

Enable with `orchid plugins enable my-extension` or via config.

## Docker

```bash
# Build
docker build -t orchid:local .

# With browser support (+300MB, speeds up container start)
docker build --build-arg ORCHID_INSTALL_BROWSER=1 -t orchid:local .

# Run via compose
ORCHID_GATEWAY_TOKEN="your-token" docker-compose up
```

## Storage

Orchid is self-contained — no external database required.

- **Config:** `~/.orchid/orchid.json`
- **State:** `~/.orchid/` (SQLite-based, file-backed)
- **Memory:** `~/.orchid/memory/` (optional LanceDB or file-based)

## Documentation

```bash
pnpm docs:dev           # Local Mintlify docs preview
pnpm docs:check-links   # Verify links
pnpm docs:spellcheck    # Spell check
pnpm format:docs        # Format markdown
```

## Before You Commit

```bash
pnpm check    # format + types + lint
pnpm test     # unit tests
```

Full pre-merge validation:

```bash
pnpm build && pnpm check && pnpm test
```
