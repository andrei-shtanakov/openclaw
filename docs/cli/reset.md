---
summary: "CLI reference for `orchid reset` (reset local state/config)"
read_when:
  - You want to wipe local state while keeping the CLI installed
  - You want a dry-run of what would be removed
title: "reset"
---

# `orchid reset`

Reset local config/state (keeps the CLI installed).

```bash
orchid reset
orchid reset --dry-run
orchid reset --scope config+creds+sessions --yes --non-interactive
```
