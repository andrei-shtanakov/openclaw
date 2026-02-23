# WhatsApp (Orchid channel)

WhatsApp support via WhatsApp Web (Baileys) gateway session.

Docs: https://docs.orchid.ai/channels/whatsapp

## Enable

WhatsApp is a built-in channel. Enable it in `orchid.json`:

```json5
{
  channels: {
    whatsapp: {
      enabled: true,
    },
  },
}
```

## Config

Key fields:

- `dmPolicy` — `"pairing"` (default), `"allowlist"`, `"open"`, or `"disabled"`
- `allowFrom` — E.164-style phone numbers for DM allowlist
- `groupPolicy` — `"allowlist"` (default), `"open"`, or `"disabled"`

See [full documentation](https://docs.orchid.ai/channels/whatsapp) for all options.
