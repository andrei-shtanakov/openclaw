---
summary: "CLI reference for `orchid config` (get/set/unset config values)"
read_when:
  - You want to read or edit config non-interactively
title: "config"
---

# `orchid config`

Config helpers: get/set/unset values by path. Run without a subcommand to open
the configure wizard (same as `orchid configure`).

## Examples

```bash
orchid config get browser.executablePath
orchid config set browser.executablePath "/usr/bin/google-chrome"
orchid config set agents.defaults.heartbeat.every "2h"
orchid config set agents.list[0].tools.exec.node "node-id-or-name"
orchid config unset tools.web.search.apiKey
```

## Paths

Paths use dot or bracket notation:

```bash
orchid config get agents.defaults.workspace
orchid config get agents.list[0].id
```

Use the agent list index to target a specific agent:

```bash
orchid config get agents.list
orchid config set agents.list[1].tools.exec.node "node-id-or-name"
```

## Values

Values are parsed as JSON5 when possible; otherwise they are treated as strings.
Use `--strict-json` to require JSON5 parsing. `--json` remains supported as a legacy alias.

```bash
orchid config set agents.defaults.heartbeat.every "0m"
orchid config set gateway.port 19001 --strict-json
orchid config set channels.whatsapp.groups '["*"]' --strict-json
```

Restart the gateway after edits.
