# Memory Core (Orchid plugin)

File-backed memory search tools and CLI for agent long-term memory.

## Enable

```bash
orchid plugins enable memory-core
```

Or set as the memory slot provider in `orchid.json`:

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

No additional configuration required. Memory-core uses the default file-based storage at `~/.orchid/memory/`.
