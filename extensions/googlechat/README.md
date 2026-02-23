# Google Chat (OpenClaw plugin)

Google Chat bot support via Service Account and HTTP webhooks.

Docs: https://docs.openclaw.ai/channels/googlechat

## Enable

```bash
openclaw plugins enable googlechat
```

## Config

Minimal config in `openclaw.json`:

```json5
{
  channels: {
    googlechat: {
      enabled: true,
      serviceAccountFile: "/path/to/service-account.json",
      audience: "https://your-project.cloudfunctions.net",
    },
  },
}
```

See [full documentation](https://docs.openclaw.ai/channels/googlechat) for all options.
