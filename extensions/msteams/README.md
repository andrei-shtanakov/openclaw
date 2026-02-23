# Microsoft Teams (OpenClaw plugin)

Microsoft Teams bot support via Azure Bot and Bot Framework webhook.

Docs: https://docs.openclaw.ai/channels/msteams

## Enable

```bash
openclaw plugins enable msteams
```

## Config

Minimal config in `openclaw.json`:

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

See [full documentation](https://docs.openclaw.ai/channels/msteams) for all options.
