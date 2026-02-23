# Phase 1: Structural Cleanup — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Stabilize the openclaw core by fixing plugin isolation, removing legacy packages, and reorganizing the 419-file `src/agents/` monster into logical submodules.

**Architecture:** Instead of physically moving files out of `src/agents/` (612 cross-codebase imports — too risky), we reorganize _within_ `src/agents/` by moving 177 top-level files into properly named subdirectories. This preserves all external import paths (callers use `../agents/foo.ts` → `../agents/model-config/foo.ts` requires update, but `../agents/foo.ts` could be a re-export barrel). We use barrel re-exports to avoid breaking external consumers.

**Tech Stack:** TypeScript, pnpm workspace, Vitest

**Risk mitigation:** Each task ends with `pnpm test` (or targeted test). Barrel re-exports ensure zero breakage of external imports.

---

## Task 1: Plugin Loading Error Isolation

**Files:**

- Modify: `src/plugins/loader.ts:334-672`
- Test: `src/plugins/loader.test.ts`

**Step 1: Write a failing test for discovery-phase error resilience**

Add to `src/plugins/loader.test.ts`:

```typescript
it("returns empty registry when discovery throws", () => {
  // Simulate a discovery error by passing a nonexistent loadPath
  // that triggers an OS-level error in discoverOpenClawPlugins
  const result = loadOpenClawPlugins({
    config: {
      plugins: {
        loadPaths: ["/nonexistent-path-that-triggers-error-\x00"],
      },
    },
    cache: false,
  });
  expect(result.plugins).toEqual([]);
  expect(result.diagnostics.some((d) => d.level === "error")).toBe(true);
});
```

**Step 2: Run test to verify it fails**

Run: `pnpm vitest run src/plugins/loader.test.ts --reporter=verbose 2>&1 | tail -20`
Expected: FAIL — discovery throws, entire function crashes

**Step 3: Wrap discovery phase in try-catch**

In `src/plugins/loader.ts`, wrap lines 364-374:

```typescript
let discovery: ReturnType<typeof discoverOpenClawPlugins>;
try {
  discovery = discoverOpenClawPlugins({
    workspaceDir: options.workspaceDir,
    extraPaths: normalized.loadPaths,
  });
} catch (err) {
  logger.error(`[plugins] discovery failed: ${String(err)}`);
  registry.diagnostics.push({
    level: "error",
    pluginId: undefined,
    message: `plugin discovery failed: ${String(err)}`,
  });
  discovery = { candidates: [], diagnostics: [] };
}

let manifestRegistry: ReturnType<typeof loadPluginManifestRegistry>;
try {
  manifestRegistry = loadPluginManifestRegistry({
    config: cfg,
    workspaceDir: options.workspaceDir,
    cache: options.cache,
    candidates: discovery.candidates,
    diagnostics: discovery.diagnostics,
  });
} catch (err) {
  logger.error(`[plugins] manifest load failed: ${String(err)}`);
  registry.diagnostics.push({
    level: "error",
    pluginId: undefined,
    message: `manifest registry load failed: ${String(err)}`,
  });
  manifestRegistry = { plugins: [], diagnostics: [] };
}
```

**Step 4: Wrap hook runner initialization (line 670)**

```typescript
try {
  initializeGlobalHookRunner(registry);
} catch (err) {
  logger.error(`[plugins] hook runner initialization failed: ${String(err)}`);
  registry.diagnostics.push({
    level: "error",
    pluginId: undefined,
    message: `hook runner init failed: ${String(err)}`,
  });
}
```

**Step 5: Run test to verify it passes**

Run: `pnpm vitest run src/plugins/loader.test.ts --reporter=verbose 2>&1 | tail -20`
Expected: PASS

**Step 6: Run full plugin test suite**

Run: `pnpm vitest run src/plugins/ --reporter=verbose 2>&1 | tail -30`
Expected: All tests pass

**Step 7: Commit**

```bash
scripts/committer "fix(plugins): isolate discovery and hook-runner errors from crashing entire plugin load" src/plugins/loader.ts src/plugins/loader.test.ts
```

---

## Task 2: Remove Legacy Packages

**Files:**

- Delete: `packages/clawdbot/` (entire directory)
- Delete: `packages/moltbot/` (entire directory)
- Check: `pnpm-workspace.yaml` (uses `packages/*` glob — auto-adjusts)

**Step 1: Verify no runtime code imports from these packages**

Run: `grep -r "from ['\"]clawdbot" src/ extensions/ --include="*.ts" | head -5`
Run: `grep -r "from ['\"]moltbot" src/ extensions/ --include="*.ts" | head -5`
Expected: No matches (legacy support is in `src/config/paths.ts`, not imports from the packages)

**Step 2: Delete the directories**

```bash
rm -rf packages/clawdbot packages/moltbot
```

**Step 3: Verify pnpm workspace still resolves**

Run: `pnpm install --frozen-lockfile 2>&1 | tail -10`
If lockfile mismatch: `pnpm install 2>&1 | tail -10`

**Step 4: Run tests**

Run: `pnpm vitest run --reporter=verbose 2>&1 | tail -30`
Expected: All tests pass (these packages had no tests of their own)

**Step 5: Commit**

```bash
scripts/committer "chore: remove legacy clawdbot and moltbot compatibility packages" packages/
```

---

## Task 3: Create barrel re-exports index for agents/

Before moving any files, create an `src/agents/index.ts` barrel that re-exports the current public surface. This way, after we reorganize internal files into subdirectories, external imports can migrate gradually.

**Files:**

- Create: `src/agents/_index-snapshot.md` (documentation of current public surface)

**Step 1: Generate a map of what external code imports from agents/**

Run:

```bash
grep -roh "from ['\"].*agents/[^'\"]*['\"]" src/ --include="*.ts" \
  | grep -v "src/agents/" \
  | sort | uniq -c | sort -rn | head -50
```

This produces the list of the most-imported modules from agents/.

**Step 2: Document the import surface in `_index-snapshot.md`**

Create a markdown file listing every module imported from outside agents/, sorted by frequency. This is our contract — these paths must not break.

**Step 3: Commit**

```bash
scripts/committer "docs(agents): snapshot external import surface before reorganization" src/agents/_index-snapshot.md
```

---

## Task 4: Reorganize agents/ — move model-config files into subdirectory

Start with the smallest, most cohesive group: **model config** (21 files).

**Files to move into `src/agents/model-config/`:**

- `models-config.ts`
- `models-config.providers.ts`
- `models-config.e2e-harness.ts`
- `model-catalog.ts`
- `model-catalog.test-harness.ts`
- `model-auth.ts`
- `model-auth-label.ts`
- `model-selection.ts`
- `model-compat.ts`
- `model-fallback.ts`
- `model-forward-compat.ts`
- `model-alias-lines.ts`
- `model-scan.ts`
- `live-model-filter.ts`
- `pi-model-discovery.ts`
- `defaults.ts`
- `synthetic-models.ts`
- And all their `*.test.ts` counterparts
- Provider-specific model files: `byteplus-models.ts`, `doubao-models.ts`, `huggingface-models.ts`, `minimax-vlm.ts`, `opencode-zen-models.ts`, `together-models.ts`, `venice-models.ts`, `volc-models.shared.ts`, `bedrock-discovery.ts`, `cloudflare-ai-gateway.ts`

**Step 1: Create the directory and move files**

```bash
mkdir -p src/agents/model-config
# Move each file (git mv preserves history)
git mv src/agents/models-config.ts src/agents/model-config/
git mv src/agents/models-config.providers.ts src/agents/model-config/
# ... etc for each file
```

**Step 2: Create barrel re-export at old paths**

For each moved file, create a thin re-export at the original path so external imports don't break:

```typescript
// src/agents/models-config.ts (re-export shim)
export * from "./model-config/models-config.js";
```

**Step 3: Fix internal imports within moved files**

Moved files that import `../config/` now need `../../config/` (one level deeper). Fix all relative imports within the moved files.

**Step 4: Run tests**

Run: `pnpm vitest run --reporter=verbose 2>&1 | tail -30`
Expected: All tests pass

**Step 5: Commit**

```bash
scripts/committer "refactor(agents): extract model-config into dedicated subdirectory" src/agents/model-config/ src/agents/models-config.ts src/agents/model-catalog.ts src/agents/model-auth.ts
```

---

## Task 5: Reorganize agents/ — move tool-policy and bash-tools into tools/

The `tools/` subdirectory already exists but top-level tool-related files (bash-tools._, tool-policy._, pi-tools.\*) live outside it.

**Files to move into `src/agents/tools/`:**

- `bash-tools.ts`, `bash-tools.exec.ts`, `bash-tools.exec-types.ts`, `bash-tools.exec-approval-request.ts`, `bash-tools.exec-host-gateway.ts`, `bash-tools.exec-host-node.ts`, `bash-tools.exec-runtime.ts`, `bash-tools.process.ts`, `bash-tools.shared.ts`
- `bash-process-registry.ts`
- `tool-policy.ts`, `tool-policy-pipeline.ts`, `tool-policy-shared.ts`, `tool-policy.conformance.ts`
- `sandbox-tool-policy.ts`
- `tool-call-id.ts`, `tool-mutation.ts`, `tool-display.ts`, `tool-display-common.ts`, `tool-summaries.ts`, `tool-images.ts`, `tool-loop-detection.ts`
- `pi-tools.ts`, `pi-tools.types.ts`, `pi-tools.schema.ts`, `pi-tools.policy.ts`, `pi-tools.before-tool-call.ts`, `pi-tools.read.ts`, `pi-tools.abort.ts`
- `pi-tool-definition-adapter.ts`
- And all `*.test.ts` counterparts

**Step 1: Move files with `git mv`**

```bash
git mv src/agents/bash-tools.ts src/agents/tools/
git mv src/agents/bash-tools.exec.ts src/agents/tools/
# ... etc
```

**Step 2: Create barrel re-exports at original paths**

Same pattern as Task 4: thin re-export shims.

**Step 3: Fix internal imports**

**Step 4: Run tests**

Run: `pnpm vitest run src/agents/ --reporter=verbose 2>&1 | tail -30`
Expected: All pass

**Step 5: Commit**

```bash
scripts/committer "refactor(agents): consolidate tool-policy and bash-tools into tools/ subdirectory" src/agents/tools/
```

---

## Task 6: Reorganize agents/ — move subagent files into subagents/

**Files to move into `src/agents/subagents/`:**

- `subagent-registry.ts`, `subagent-registry.types.ts`, `subagent-registry.store.ts`
- `subagent-registry.mocks.shared.ts`, `subagent-registry-queries.ts`
- `subagent-registry-state.ts`, `subagent-registry-completion.ts`
- `subagent-registry-cleanup.ts`
- `subagent-spawn.ts`, `subagent-announce.ts`, `subagent-announce-queue.ts`
- `subagent-lifecycle-events.ts`, `subagent-depth.ts`
- `openclaw-tools.ts` (includes subagent tooling)
- And all `*.test.ts` counterparts

**Steps:** Same pattern as Tasks 4-5: git mv → barrel re-exports → fix imports → test → commit.

---

## Task 7: Reorganize agents/ — move session files into sessions/

**Files to move into `src/agents/sessions/`:**

- `session-dirs.ts`, `session-slug.ts`, `session-file-repair.ts`
- `session-transcript-repair.ts`, `session-tool-result-guard.ts`
- `session-tool-result-guard-wrapper.ts`, `session-write-lock.ts`
- `cli-session.ts`
- And all `*.test.ts` counterparts

**Steps:** Same pattern: git mv → barrel re-exports → fix imports → test → commit.

---

## Task 8: Reorganize agents/ — move workspace and identity files

**Move into `src/agents/workspace/`:**

- `workspace.ts`, `workspace-dir.ts`, `workspace-dirs.ts`
- `workspace-run.ts`, `workspace-templates.ts`

**Move into `src/agents/identity/`:**

- `identity.ts`, `identity-file.ts`, `identity-avatar.ts`
- `owner-display.ts`, `image-sanitization.ts`

**Steps:** Same pattern: git mv → barrel re-exports → fix imports → test → commit.

---

## Task 9: Verify and cleanup

**Step 1: Count remaining top-level files**

```bash
ls src/agents/*.ts | grep -v '.test.ts' | wc -l
```

Target: < 30 (down from 177). Remaining files are utilities and glue that don't form a cohesive group.

**Step 2: Run full test suite**

```bash
pnpm test 2>&1 | tail -30
```

Expected: All pass.

**Step 3: Run type check**

```bash
pnpm tsgo 2>&1 | tail -20
```

Expected: No new errors.

**Step 4: Run lint**

```bash
pnpm check 2>&1 | tail -20
```

Expected: No new errors.

**Step 5: Final commit with any remaining fixes**

```bash
scripts/committer "refactor(agents): complete Phase 1 reorganization of agents/ directory"
```

---

## Summary

| Task      | What                           | Files affected       | Risk   | Time    |
| --------- | ------------------------------ | -------------------- | ------ | ------- |
| 1         | Plugin loading isolation       | 2                    | Low    | 30min   |
| 2         | Remove legacy packages         | 6 deleted            | Low    | 15min   |
| 3         | Document import surface        | 1 created            | None   | 15min   |
| 4         | Extract model-config/          | ~30 moved + 30 shims | Medium | 1.5h    |
| 5         | Consolidate tools/             | ~40 moved + 40 shims | Medium | 1.5h    |
| 6         | Extract subagents/             | ~15 moved + 15 shims | Medium | 45min   |
| 7         | Extract sessions/              | ~10 moved + 10 shims | Low    | 30min   |
| 8         | Extract workspace/ + identity/ | ~10 moved + 10 shims | Low    | 30min   |
| 9         | Verify and cleanup             | —                    | None   | 30min   |
| **Total** |                                |                      |        | **~6h** |

After completion: `src/agents/` top-level files drop from **177 → ~30**, grouped into **7 named subdirectories** matching their domain.
