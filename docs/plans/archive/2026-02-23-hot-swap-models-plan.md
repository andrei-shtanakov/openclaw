# Hot-Swap Model Config — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enable hot-reload for model configuration so changing models doesn't require a gateway restart.

**Architecture:** Add "reload-models" action to the existing config-reload pipeline. Clear the model catalog cache and re-run discovery when models.\* config changes are detected.

**Tech Stack:** TypeScript, Vitest

---

## Task 1: Add reloadModels to GatewayReloadPlan type and builder

**Files:**

- Modify: `src/gateway/config-reload.ts`
- Test: `src/gateway/config-reload.test.ts`

**Step 1: Add "reload-models" to ReloadAction union (line ~35-41)**

```typescript
type ReloadAction =
  | "reload-hooks"
  | "reload-models" // ← ADD THIS
  | "restart-gmail-watcher"
  | "restart-browser-control"
  | "restart-cron"
  | "restart-heartbeat"
  | `restart-channel:${ChannelId}`;
```

**Step 2: Add reloadModels to GatewayReloadPlan type (line ~15-27)**

```typescript
export type GatewayReloadPlan = {
  // ... existing fields ...
  reloadModels: boolean; // ← ADD THIS
  // ... existing fields ...
};
```

**Step 3: Initialize reloadModels in buildGatewayReloadPlan (line ~180-192)**

```typescript
reloadModels: false,          // ← ADD THIS to initialization
```

**Step 4: Add action case in applyAction function (line ~194-219)**

```typescript
case "reload-models":
  plan.reloadModels = true;
  break;
```

**Step 5: Change models reload rule (line 74)**

From: `{ prefix: "models", kind: "none" }`
To: `{ prefix: "models", kind: "hot", actions: ["reload-models"] }`

**Step 6: Write test**

Add test in config-reload.test.ts verifying that a change to "models.providers" results in plan.reloadModels === true.

**Step 7: Run tests**

`pnpm vitest run src/gateway/config-reload.test.ts --reporter=verbose`

**Step 8: Commit**

`scripts/committer "feat(config-reload): add reload-models action to hot-reload pipeline" src/gateway/config-reload.ts src/gateway/config-reload.test.ts`

---

## Task 2: Export invalidateModelCatalog() from model-catalog

**Files:**

- Modify: `src/agents/model-config/model-catalog.ts`
- Test: existing tests or new test

**Step 1: Create public invalidateModelCatalog function**

Near line 62 (next to resetModelCatalogCacheForTest):

```typescript
export function invalidateModelCatalog(): void {
  modelCatalogPromise = null;
}
```

This is intentionally simpler than resetModelCatalogCacheForTest() — it only clears the cache promise, not the error state or import function (those are test-only concerns).

**Step 2: Verify existing tests still pass**

`pnpm vitest run src/agents/model-config/ --reporter=verbose`

**Step 3: Commit**

`scripts/committer "feat(model-catalog): export invalidateModelCatalog for hot-reload" src/agents/model-config/model-catalog.ts`

---

## Task 3: Register reloadModels handler in server-reload-handlers

**Files:**

- Modify: `src/gateway/server-reload-handlers.ts`
- Test: `src/gateway/server-reload-handlers.test.ts` (if exists) or add inline test

**Step 1: Import required functions**

Add imports for:

- `invalidateModelCatalog` from model-catalog
- `ensureOpenClawModelsJson` from models-config

**Step 2: Add reloadModels block in applyHotReload() (after existing blocks, ~line 62)**

Following the existing pattern:

```typescript
if (plan.reloadModels) {
  invalidateModelCatalog();
  await ensureOpenClawModelsJson(nextConfig);
  logger.info("[reload] model registry reloaded");
}
```

**Step 3: Run tests**

`pnpm vitest run src/gateway/ --reporter=verbose`

**Step 4: Commit**

`scripts/committer "feat(gateway): handle model hot-reload in applyHotReload" src/gateway/server-reload-handlers.ts`

---

## Task 4: Integration test and final verification

**Step 1: Run full test suite**

`pnpm vitest run --reporter=verbose 2>&1 | tail -30`

**Step 2: Type check**

`pnpm tsgo 2>&1 | tail -10`

**Step 3: Commit all**

If any fixes needed, commit them.

---

## Summary

| Task      | What                                       | Risk | Time      |
| --------- | ------------------------------------------ | ---- | --------- |
| 1         | Add reloadModels to config-reload pipeline | Low  | 30min     |
| 2         | Export invalidateModelCatalog()            | Low  | 15min     |
| 3         | Register handler in server-reload-handlers | Low  | 30min     |
| 4         | Integration test                           | None | 15min     |
| **Total** |                                            |      | **~1.5h** |
