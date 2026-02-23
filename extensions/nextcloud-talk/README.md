# Nextcloud Talk (Orchid plugin)

Nextcloud Talk bot support via webhook and shared secret.

Docs: https://docs.orchid.ai/channels/nextcloud-talk

## Enable

```bash
orchid plugins enable nextcloud-talk
```

## Config

Minimal config in `orchid.json`:

```json5
{
  channels: {
    "nextcloud-talk": {
      enabled: true,
      baseUrl: "https://cloud.example.com",
      botSecret: "your-shared-secret",
    },
  },
}
```

See [full documentation](https://docs.orchid.ai/channels/nextcloud-talk) for all options.
