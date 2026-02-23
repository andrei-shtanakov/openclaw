# Nextcloud Talk (OpenClaw plugin)

Nextcloud Talk bot support via webhook and shared secret.

Docs: https://docs.openclaw.ai/channels/nextcloud-talk

## Enable

```bash
openclaw plugins enable nextcloud-talk
```

## Config

Minimal config in `openclaw.json`:

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

See [full documentation](https://docs.openclaw.ai/channels/nextcloud-talk) for all options.
