# LINE (OpenClaw plugin)

LINE Messaging API support for direct messages and groups.

Docs: https://docs.openclaw.ai/channels/line

## Enable

```bash
openclaw plugins enable line
```

## Config

Minimal config in `openclaw.json`:

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

See [full documentation](https://docs.openclaw.ai/channels/line) for all options.
