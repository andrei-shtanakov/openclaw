# IRC (Orchid plugin)

IRC channel and direct message support.

Docs: https://docs.orchid.ai/channels/irc

## Enable

```bash
orchid plugins enable irc
```

## Config

Minimal config in `orchid.json`:

```json5
{
  channels: {
    irc: {
      enabled: true,
      host: "irc.example.com",
      port: 6697,
      tls: true,
      nick: "orchid",
      channels: ["#general"],
    },
  },
}
```

See [full documentation](https://docs.orchid.ai/channels/irc) for all options.
