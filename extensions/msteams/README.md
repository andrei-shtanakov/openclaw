# Microsoft Teams (Orchid plugin)

Microsoft Teams bot support via Azure Bot and Bot Framework webhook.

Docs: https://docs.orchid.ai/channels/msteams

## Enable

```bash
orchid plugins enable msteams
```

## Config

Minimal config in `orchid.json`:

```json5
{
  channels: {
    msteams: {
      enabled: true,
      appId: "your-azure-bot-app-id",
      appPassword: "your-client-secret",
      tenantId: "your-azure-tenant-id",
    },
  },
}
```

See [full documentation](https://docs.orchid.ai/channels/msteams) for all options.
