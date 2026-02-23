# Memory LanceDB (Orchid plugin)

LanceDB-backed long-term memory with auto-recall and auto-capture.

## Enable

```bash
orchid plugins enable memory-lancedb
```

Or set as the memory slot provider in `orchid.json`:

```json5
{
  plugins: {
    slots: {
      memory: "memory-lancedb",
    },
  },
}
```

## Config

```json5
{
  plugins: {
    entries: {
      "memory-lancedb": {
        enabled: true,
        config: {
          embedding: {
            apiKey: "${OPENAI_API_KEY}",
            model: "text-embedding-3-small", // or "text-embedding-3-large"
          },
          dbPath: "~/.orchid/memory/lancedb", // default
          autoCapture: true, // auto-capture important info
          autoRecall: true, // auto-inject relevant memories
        },
      },
    },
  },
}
```

Key fields:

- `embedding.apiKey` — OpenAI API key (required; supports env var expansion)
- `embedding.model` — Embedding model (default: `text-embedding-3-small`)
- `autoCapture` / `autoRecall` — Toggle automatic memory capture and retrieval
