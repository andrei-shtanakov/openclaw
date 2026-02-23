# Matrix (OpenClaw plugin)

Matrix protocol support via @vector-im/matrix-bot-sdk with E2EE support.

Docs: https://docs.openclaw.ai/channels/matrix

## Enable

```bash
openclaw plugins enable matrix
```

## Config

Minimal config in `openclaw.json`:

```json5
{
  channels: {
    matrix: {
      enabled: true,
      homeserver: "https://matrix.example.org",
      accessToken: "your-access-token",
    },
  },
}
```

See [full documentation](https://docs.openclaw.ai/channels/matrix) for all options.
