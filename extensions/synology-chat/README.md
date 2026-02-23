# Synology Chat (Orchid plugin)

Synology Chat bot support for NAS-hosted team messaging.

Docs: https://docs.orchid.ai/channels/synology-chat

## Enable

```bash
orchid plugins enable synology-chat
```

## Config

Minimal config in `orchid.json`:

```json5
{
  channels: {
    "synology-chat": {
      enabled: true,
    },
  },
}
```

See [full documentation](https://docs.orchid.ai/channels/synology-chat) for all options.
