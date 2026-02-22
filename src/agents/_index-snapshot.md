# agents/ External Import Surface Snapshot

> Generated 2026-02-22 before Phase 1 reorganization.
> 120 unique import paths from outside agents/ into agents/.
> These paths MUST continue to resolve after reorganization (via barrel re-exports).

## Top imports (≥5 usages from external code)

| Import path            | External refs | Target subdirectory             |
| ---------------------- | ------------- | ------------------------------- |
| agent-scope.js         | 95            | (root — utility)                |
| model-selection.js     | 57            | model-config/                   |
| model-auth.js          | 32            | model-config/                   |
| auth-profiles.js       | 32            | auth-profiles/ (already subdir) |
| defaults.js            | 26            | model-config/                   |
| pi-embedded.js         | 25            | (root — runtime entry)          |
| model-catalog.js       | 25            | model-config/                   |
| workspace.js           | 20            | workspace/                      |
| skills.js              | 19            | skills/ (already subdir)        |
| identity.js            | 17            | identity/                       |
| tools/common.js        | 16            | tools/ (already subdir)         |
| subagent-registry.js   | 16            | subagents/                      |
| sandbox.js             | 16            | sandbox/ (already subdir)       |
| usage.js               | 11            | (root — utility)                |
| context.js             | 11            | (root — utility)                |
| skills-status.js       | 8             | skills/                         |
| skills/refresh.js      | 6             | skills/ (already subdir)        |
| pi-embedded-helpers.js | 6             | (root — runtime)                |
| model-fallback.js      | 6             | model-config/                   |
| agent-paths.js         | 6             | (root — utility)                |
| tool-policy.js         | 5             | tools/                          |
| pi-model-discovery.js  | 5             | model-config/                   |
| memory-search.js       | 5             | (root — utility)                |
| cli-session.js         | 5             | sessions/                       |

## Medium imports (2-4 usages)

| Import path                       | Refs | Target                        |
| --------------------------------- | ---- | ----------------------------- |
| timeout.js                        | 4    | (root)                        |
| subagent-announce.js              | 4    | subagents/                    |
| date-time.js                      | 4    | (root)                        |
| current-time.js                   | 4    | (root)                        |
| cli-runner.js                     | 4    | (root)                        |
| bash-tools.js                     | 4    | tools/                        |
| auth-health.js                    | 4    | auth-profiles/                |
| workspace-dirs.js                 | 3    | workspace/                    |
| tools/sessions-helpers.js         | 3    | tools/ (already)              |
| skills-install.js                 | 3    | skills/                       |
| session-write-lock.js             | 3    | sessions/                     |
| pi-tools.policy.js                | 3    | tools/                        |
| models-config.providers.js        | 3    | model-config/                 |
| models-config.js                  | 3    | model-config/                 |
| model-auth-label.js               | 3    | model-config/                 |
| lanes.js                          | 3    | (root)                        |
| identity-file.js                  | 3    | identity/                     |
| identity-avatar.js                | 3    | identity/                     |
| chutes-oauth.js                   | 3    | auth-profiles/                |
| auth-profiles/types.js            | 3    | auth-profiles/ (already)      |
| auth-profiles/session-override.js | 3    | auth-profiles/ (already)      |
| venice-models.js                  | 2    | model-config/                 |
| tools/slack-actions.js            | 2    | tools/ (already)              |
| tools/discord-actions.js          | 2    | tools/ (already)              |
| tool-display.js                   | 2    | tools/                        |
| synthetic-models.js               | 2    | model-config/                 |
| subagent-spawn.js                 | 2    | subagents/                    |
| shell-utils.js                    | 2    | (root)                        |
| session-dirs.js                   | 2    | sessions/                     |
| sandbox/types.js                  | 2    | sandbox/ (already)            |
| sandbox/docker.js                 | 2    | sandbox/ (already)            |
| sandbox-paths.js                  | 2    | sandbox/                      |
| pi-settings.js                    | 2    | (root)                        |
| pi-embedded-runner/runs.js        | 2    | pi-embedded-runner/ (already) |
| pi-embedded-runner/run/params.js  | 2    | pi-embedded-runner/ (already) |
| pi-embedded-runner/model.js       | 2    | pi-embedded-runner/ (already) |
| openclaw-tools.js                 | 2    | subagents/                    |
| model-forward-compat.js           | 2    | model-config/                 |
| huggingface-models.js             | 2    | model-config/                 |
| cloudflare-ai-gateway.js          | 2    | model-config/                 |
| api-key-rotation.js               | 2    | auth-profiles/                |

## Low imports (1 usage) — 44 paths

Single-reference imports that need re-export shims but are low priority.
See full list in the generation command output.

## Re-export strategy

For each moved file, create a shim at the original path:

```typescript
// src/agents/model-selection.ts (shim)
export * from "./model-config/model-selection.js";
```

This preserves all 612 external import references with zero changes to consuming code.
