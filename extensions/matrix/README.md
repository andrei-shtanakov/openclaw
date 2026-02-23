# Matrix (Orchid plugin)

Matrix protocol support via @vector-im/matrix-bot-sdk with E2EE support.

Docs: https://docs.orchid.ai/channels/matrix

## Enable

```bash
orchid plugins enable matrix
```

## Config

Minimal config in `orchid.json`:

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

See [full documentation](https://docs.orchid.ai/channels/matrix) for all options.
