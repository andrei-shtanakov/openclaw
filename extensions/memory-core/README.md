# Memory Core (OpenClaw plugin)

File-backed memory search tools and CLI for agent long-term memory.

## Enable

```bash
openclaw plugins enable memory-core
```

Or set as the memory slot provider in `openclaw.json`:

```json5
{
  plugins: {
    slots: {
      memory: "memory-core",
    },
  },
}
```

## Config

No additional configuration required. Memory-core uses the default file-based storage at `~/.openclaw/memory/`.
