# Synology Chat (OpenClaw plugin)

Synology Chat bot support for NAS-hosted team messaging.

Docs: https://docs.openclaw.ai/channels/synology-chat

## Enable

```bash
openclaw plugins enable synology-chat
```

## Config

Minimal config in `openclaw.json`:

```json5
{
  channels: {
    "synology-chat": {
      enabled: true,
    },
  },
}
```

See [full documentation](https://docs.openclaw.ai/channels/synology-chat) for all options.
