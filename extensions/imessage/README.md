# iMessage (OpenClaw channel)

iMessage support via legacy imsg CLI integration. For new setups, consider BlueBubbles.

Docs: https://docs.openclaw.ai/channels/imessage

## Enable

iMessage is a built-in channel. Enable it in `openclaw.json`:

```json5
{
  channels: {
    imessage: {
      enabled: true,
      cliPath: "/usr/local/bin/imsg",
    },
  },
}
```

## Config

Key fields:

- `cliPath` — Path to imsg binary
- `dbPath` — Path to Messages database (chat.db)
- `dmPolicy` — `"pairing"` (default), `"allowlist"`, `"open"`, or `"disabled"`

See [full documentation](https://docs.openclaw.ai/channels/imessage) for all options.
