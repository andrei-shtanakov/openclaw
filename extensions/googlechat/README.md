# Google Chat (Orchid plugin)

Google Chat bot support via Service Account and HTTP webhooks.

Docs: https://docs.orchid.ai/channels/googlechat

## Enable

```bash
orchid plugins enable googlechat
```

## Config

Minimal config in `orchid.json`:

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

See [full documentation](https://docs.orchid.ai/channels/googlechat) for all options.
