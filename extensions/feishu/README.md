# Feishu / Lark (Orchid plugin)

Feishu/Lark team messaging bot via WebSocket long connection.

Docs: https://docs.orchid.ai/channels/feishu

## Enable

```bash
orchid plugins enable feishu
```

## Config

Minimal config in `orchid.json`:

```json5
{
  channels: {
    feishu: {
      enabled: true,
      appId: "cli_xxx",
      appSecret: "your-app-secret",
    },
  },
}
```

See [full documentation](https://docs.orchid.ai/channels/feishu) for all options.
