# IRC (OpenClaw plugin)

IRC channel and direct message support.

Docs: https://docs.openclaw.ai/channels/irc

## Enable

```bash
openclaw plugins enable irc
```

## Config

Minimal config in `openclaw.json`:

```json5
{
  channels: {
    irc: {
      enabled: true,
      host: "irc.example.com",
      port: 6697,
      tls: true,
      nick: "openclaw",
      channels: ["#general"],
    },
  },
}
```

See [full documentation](https://docs.openclaw.ai/channels/irc) for all options.
