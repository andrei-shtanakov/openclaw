# iMessage (Orchid channel)

iMessage support via legacy imsg CLI integration. For new setups, consider BlueBubbles.

Docs: https://docs.orchid.ai/channels/imessage

## Enable

iMessage is a built-in channel. Enable it in `orchid.json`:

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

See [full documentation](https://docs.orchid.ai/channels/imessage) for all options.
