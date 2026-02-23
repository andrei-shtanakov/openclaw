# LINE (Orchid channel)

LINE Messaging API support for direct messages and groups.

Docs: https://docs.orchid.ai/channels/line

## Enable

LINE is a built-in channel. Enable it in `orchid.json`:

```json5
{
  channels: {
    line: {
      enabled: true,
      channelAccessToken: "your-channel-access-token",
      channelSecret: "your-channel-secret",
    },
  },
}
```

## Config

Key fields:

- `channelAccessToken` — LINE channel access token
- `channelSecret` — LINE channel secret for webhook verification
- `dmPolicy` — `"pairing"` (default), `"allowlist"`, `"open"`, or `"disabled"`

See [full documentation](https://docs.orchid.ai/channels/line) for all options.
