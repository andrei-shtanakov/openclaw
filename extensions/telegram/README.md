# Telegram (OpenClaw channel)

Telegram bot support via grammY with long polling or webhook mode.

Docs: https://docs.openclaw.ai/channels/telegram

## Enable

Telegram is a built-in channel. Enable it in `openclaw.json`:

```json5
{
  channels: {
    telegram: {
      enabled: true,
      botToken: "123456:ABC-DEF...",
    },
  },
}
```

## Config

Key fields:

- `botToken` — Bot token from BotFather
- `dmPolicy` — `"pairing"` (default), `"allowlist"`, `"open"`, or `"disabled"`
- `groupPolicy` — `"allowlist"` (default), `"open"`, or `"disabled"`

See [full documentation](https://docs.openclaw.ai/channels/telegram) for all options.
