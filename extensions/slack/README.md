# Slack (Orchid channel)

Slack bot support via Socket Mode (default) or HTTP Events API.

Docs: https://docs.orchid.ai/channels/slack

## Enable

Slack is a built-in channel. Enable it in `orchid.json`:

```json5
{
  channels: {
    slack: {
      enabled: true,
      botToken: "xoxb-...",
      appToken: "xapp-...", // for Socket Mode
    },
  },
}
```

## Config

Key fields:

- `botToken` — Slack bot token (`xoxb-...`)
- `appToken` — Slack app token (`xapp-...`) for Socket Mode
- `mode` — `"socket"` (default) or `"http"`
- `signingSecret` — Required for HTTP mode
- `dmPolicy` — `"pairing"` (default), `"allowlist"`, `"open"`, or `"disabled"`

See [full documentation](https://docs.orchid.ai/channels/slack) for all options.
