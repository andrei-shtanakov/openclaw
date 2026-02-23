# Mattermost (OpenClaw plugin)

Mattermost bot support via token and WebSocket.

Docs: https://docs.openclaw.ai/channels/mattermost

## Enable

```bash
openclaw plugins enable mattermost
```

## Config

Minimal config in `openclaw.json`:

```json5
{
  channels: {
    mattermost: {
      enabled: true,
      botToken: "your-bot-token",
      baseUrl: "https://chat.example.com",
    },
  },
}
```

See [full documentation](https://docs.openclaw.ai/channels/mattermost) for all options.
