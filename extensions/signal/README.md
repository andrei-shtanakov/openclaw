# Signal (OpenClaw channel)

Signal support via signal-cli JSON-RPC with an external daemon.

Docs: https://docs.openclaw.ai/channels/signal

## Enable

Signal is a built-in channel. Enable it in `openclaw.json`:

```json5
{
  channels: {
    signal: {
      enabled: true,
      account: "+15551234567",
      cliPath: "/usr/local/bin/signal-cli",
    },
  },
}
```

## Config

Key fields:

- `account` — Bot phone number in E.164 format
- `cliPath` — Path to signal-cli binary
- `dmPolicy` — `"pairing"` (default), `"allowlist"`, `"open"`, or `"disabled"`

See [full documentation](https://docs.openclaw.ai/channels/signal) for all options.
