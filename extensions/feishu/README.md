# Feishu / Lark (OpenClaw plugin)

Feishu/Lark team messaging bot via WebSocket long connection.

Docs: https://docs.openclaw.ai/channels/feishu

## Enable

```bash
openclaw plugins enable feishu
```

## Config

Minimal config in `openclaw.json`:

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

See [full documentation](https://docs.openclaw.ai/channels/feishu) for all options.
