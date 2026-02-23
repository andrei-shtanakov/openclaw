# Mattermost (Orchid plugin)

Mattermost bot support via token and WebSocket.

Docs: https://docs.orchid.ai/channels/mattermost

## Enable

```bash
orchid plugins enable mattermost
```

## Config

Minimal config in `orchid.json`:

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

See [full documentation](https://docs.orchid.ai/channels/mattermost) for all options.
