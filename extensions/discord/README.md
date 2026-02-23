# Discord (OpenClaw channel)

Discord bot support via the official Discord gateway for DMs and guild channels.

Docs: https://docs.openclaw.ai/channels/discord

## Enable

Discord is a built-in channel. Enable it in `openclaw.json`:

```json5
{
  channels: {
    discord: {
      enabled: true,
      token: "your-bot-token",
    },
  },
}
```

## Config

Key fields:

- `token` — Bot token from the Discord Developer Portal
- `dmPolicy` — `"pairing"` (default), `"allowlist"`, `"open"`, or `"disabled"`
- `groupPolicy` — `"allowlist"` (default), `"open"`, or `"disabled"`

See [full documentation](https://docs.openclaw.ai/channels/discord) for all options.
