---
summary: "Sign in to GitHub Copilot from Orchid using the device flow"
read_when:
  - You want to use GitHub Copilot as a model provider
  - You need the `orchid models auth login-github-copilot` flow
title: "GitHub Copilot"
---

# GitHub Copilot

## What is GitHub Copilot?

GitHub Copilot is GitHub's AI coding assistant. It provides access to Copilot
models for your GitHub account and plan. Orchid can use Copilot as a model
provider.

Use the native device-login flow to obtain a GitHub token, then exchange it for
Copilot API tokens when Orchid runs. The login command runs
the GitHub device flow, saves an auth profile, and updates your config to use that
profile.

## CLI setup

```bash
orchid models auth login-github-copilot
```

You'll be prompted to visit a URL and enter a one-time code. Keep the terminal
open until it completes.

### Optional flags

```bash
orchid models auth login-github-copilot --profile-id github-copilot:work
orchid models auth login-github-copilot --yes
```

## Set a default model

```bash
orchid models set github-copilot/gpt-4o
```

### Config snippet

```json5
{
  agents: { defaults: { model: { primary: "github-copilot/gpt-4o" } } },
}
```

## Notes

- Requires an interactive TTY; run it directly in a terminal.
- Copilot model availability depends on your plan; if a model is rejected, try
  another ID (for example `github-copilot/gpt-4.1`).
- The login stores a GitHub token in the auth profile store and exchanges it for a
  Copilot API token when Orchid runs.
