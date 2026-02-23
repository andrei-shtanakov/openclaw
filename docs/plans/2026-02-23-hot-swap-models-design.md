# Hot-Swap Model Config — Design

## Problem

Model config changes require full gateway restart because:

1. `src/gateway/config-reload.ts` marks `models` as `kind: "none"` (ignored)
2. Model catalog is cached in module-level promise (`modelCatalogPromise`) that never invalidates
3. `ensureOpenClawModelsJson()` only runs at startup

## Solution

### 1. Config reload rule change

In `src/gateway/config-reload.ts`, change the models rule:

- From: `{ prefix: "models", kind: "none" }`
- To: `{ prefix: "models", kind: "hot", actions: ["reloadModels"] }`

### 2. Model catalog cache invalidation

In `src/agents/model-config/model-catalog.ts`, export a new function:

```typescript
export function invalidateModelCatalog(): void {
  modelCatalogPromise = null;
}
```

### 3. Reload handler registration

In `src/gateway/server-reload-handlers.ts`, add a `reloadModels` handler:

- Call `invalidateModelCatalog()`
- Re-run `ensureOpenClawModelsJson()` with current config
- Log: "Model registry reloaded"

### 4. Runtime behavior

- Config file change detected by chokidar watcher
- `diffConfigPaths()` identifies models.\* changes
- `buildGatewayReloadPlan()` classifies as hot reload with `reloadModels` action
- `applyHotReload()` calls the models reload handler
- New requests use updated model registry
- Active sessions continue with current model until next request

### What we don't change

- No new dependencies
- No session storage changes
- No auth profile changes
- No new CLI commands
- Active sessions are NOT interrupted

## Files to modify

| File                                       | Change                         |
| ------------------------------------------ | ------------------------------ |
| `src/gateway/config-reload.ts`             | models rule: none → hot        |
| `src/agents/model-config/model-catalog.ts` | Add `invalidateModelCatalog()` |
| `src/gateway/server-reload-handlers.ts`    | Register reloadModels handler  |
| Tests for each modified file               | Verify hot-reload behavior     |
