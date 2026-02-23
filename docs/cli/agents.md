---
summary: "CLI reference for `orchid agents` (list/add/delete/set identity)"
read_when:
  - You want multiple isolated agents (workspaces + routing + auth)
title: "agents"
---

# `orchid agents`

Manage isolated agents (workspaces + auth + routing).

Related:

- Multi-agent routing: [Multi-Agent Routing](/concepts/multi-agent)
- Agent workspace: [Agent workspace](/concepts/agent-workspace)

## Examples

```bash
orchid agents list
orchid agents add work --workspace ~/.orchid/workspace-work
orchid agents set-identity --workspace ~/.orchid/workspace --from-identity
orchid agents set-identity --agent main --avatar avatars/orchid.png
orchid agents delete work
```

## Identity files

Each agent workspace can include an `IDENTITY.md` at the workspace root:

- Example path: `~/.orchid/workspace/IDENTITY.md`
- `set-identity --from-identity` reads from the workspace root (or an explicit `--identity-file`)

Avatar paths resolve relative to the workspace root.

## Set identity

`set-identity` writes fields into `agents.list[].identity`:

- `name`
- `theme`
- `emoji`
- `avatar` (workspace-relative path, http(s) URL, or data URI)

Load from `IDENTITY.md`:

```bash
orchid agents set-identity --workspace ~/.orchid/workspace --from-identity
```

Override fields explicitly:

```bash
orchid agents set-identity --agent main --name "Orchid" --emoji "🦞" --avatar avatars/orchid.png
```

Config sample:

```json5
{
  agents: {
    list: [
      {
        id: "main",
        identity: {
          name: "Orchid",
          theme: "space lobster",
          emoji: "🦞",
          avatar: "avatars/orchid.png",
        },
      },
    ],
  },
}
```
