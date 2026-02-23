# Google Antigravity Auth (Orchid plugin)

> **Status: experimental** — requires testing and coverage before production use.

OAuth provider plugin for **Google Antigravity** (Cloud Code Assist).

## Enable

Bundled plugins are disabled by default. Enable this one:

```bash
orchid plugins enable google-antigravity-auth
```

Restart the Gateway after enabling.

## Authenticate

```bash
orchid models auth login --provider google-antigravity --set-default
```

## Notes

- Antigravity uses Google Cloud project quotas.
- If requests fail, ensure Gemini for Google Cloud is enabled.
