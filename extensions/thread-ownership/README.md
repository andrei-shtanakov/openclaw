# Thread Ownership (OpenClaw plugin)

Prevents multiple agents from responding in the same Slack thread. Uses HTTP calls to the slack-forwarder ownership API.

## Enable

```bash
openclaw plugins enable thread-ownership
```

## Config

```json5
{
  plugins: {
    entries: {
      "thread-ownership": {
        enabled: true,
        config: {
          forwarderUrl: "http://slack-forwarder:8750", // default
          abTestChannels: [], // Slack channel IDs to enforce ownership
        },
      },
    },
  },
}
```

Key fields:

- `forwarderUrl` — Base URL of the slack-forwarder ownership API
- `abTestChannels` — Array of Slack channel IDs where thread ownership is enforced (empty = enforce everywhere)
