# Openclaw Reorganization Plan

## Philosophy: Refactoring over Amputation

The SUGGESTIONS.md approach (cut to Telegram-only) kills the product's main differentiator:
multi-channel support. Instead, restructure the internals while keeping the full channel set
behind config-driven enable/disable.

---

## Phase 1: Structural Cleanup (stabilize core)

### 1.1. Split `src/agents/` (419 files — the biggest module)

Currently agents/ mixes: LLM providers, auth profiles, model config, bash tools,
patch apply, schema cleaning, tool execution.

**Proposed structure:**

```
src/
├── llm/                    # extracted from agents/ — providers and model config
│   ├── providers/          # anthropic, openai, openrouter specifics
│   ├── auth-profiles/      # key rotation, cooldown, failover
│   ├── models-config/      # model registry, resolution
│   └── schema/             # tool schema cleanup per provider
├── agent-runtime/          # execution: sessions, tools, sandbox
│   ├── tools/              # bash, computer-use, MCP bridge
│   ├── sandbox/            # Docker/container isolation
│   └── sessions/           # session lifecycle
├── channels/               # channel abstraction (already clean)
├── gateway/                # control plane (already clean)
├── memory/                 # already clean
├── plugins/                # already clean
└── cli/                    # already clean
```

**Impact:** ~40% reduction in navigation complexity. The 419-file agents/ dir
is the #1 source of confusion — not the channel count.

### 1.2. Plugin loading isolation

`src/plugins/loader.ts` — if one plugin throws on top-level import, entire registry fails.

**Fix:** wrap each plugin import in try-catch, log error, continue loading others. ~20 LOC.

### 1.3. Remove legacy packages

- `packages/clawdbot` and `packages/moltbot` — old product names (aliases)
- Remove if they are just re-exports

---

## Phase 2: State Management

### 2.1. SQLite WAL for all state (not just sessions)

Migrate to SQLite:
- Sessions (JSON5 -> SQLite) — as in SUGGESTIONS.md
- Plugin config state
- Auth profile rotation state

Use existing migration framework (`src/infra/state-migrations.ts`).

**Schema (sessions):**

```sql
CREATE TABLE sessions (
    id TEXT PRIMARY KEY,
    agent_id TEXT NOT NULL,
    channel TEXT NOT NULL,
    session_key TEXT NOT NULL UNIQUE,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    metadata JSON
);

CREATE INDEX idx_agent_channel ON sessions(agent_id, channel);

CREATE TABLE session_messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL REFERENCES sessions(id),
    role TEXT NOT NULL,
    content TEXT NOT NULL,
    timestamp INTEGER NOT NULL
);
```

WAL mode for concurrent reads + atomic writes. Auto-migration on first launch.

### 2.2. Hot-swap model config

`src/gateway/config-reload.ts:72` has `{ prefix: "models", kind: "none" }` — requires full restart.

**Fix:**
- Change to `{ prefix: "models", kind: "hot", actions: ["reload-models"] }`
- Create `src/agents/model-reload-handler.ts` (~200 LOC)
- Add `invalidateModelCache()` to models-config
- CLI: `openclaw models switch <model-name>`

---

## Phase 3: Channel Abstraction Hardening

Instead of deleting channels — improve the abstraction layer.

### 3.1. Formalize channel interface

```typescript
interface ChannelAdapter {
  connect(config: ChannelConfig): Promise<void>
  disconnect(): Promise<void>
  sendMessage(msg: OutboundMessage): Promise<DeliveryResult>
  onMessage(handler: InboundHandler): void
  healthCheck(): Promise<HealthStatus>
}
```

Benefits:
- Uniform testing across all channels
- New channels in 1-2 hours
- Disable via config without removing code

### 3.2. Config-driven channel registry

```yaml
# ~/.openclaw/channels.yml
enabled:
  - telegram
  - discord
disabled:
  - slack      # installed but off
  - whatsapp   # installed but off
```

Channels not enabled = not loaded. Zero runtime cost, code remains.

---

## Phase 4: Selective Trimming (not amputation)

Only remove what is dead or duplicates:

| What to remove | Reason | Files |
|---|---|---|
| `src/browser/` | macOS-only computer-use, niche | ~113 |
| `src/canvas-host/` | Tied to browser module | ~8 |
| `Swabble/` | Swift pkg, check if used in production apps | ~15 dirs |
| `packages/clawdbot`, `packages/moltbot` | Legacy aliases | small |
| `extensions/tlon` | Niche platform | ~28 |
| `extensions/synology-chat` | Niche | ~13 |
| `extensions/lobster` | Unclear purpose | ~5 |
| Google Gemini auth extensions | If Google provider unused | ~10 |

**Total: ~200-250 files** (vs ~1,200 in SUGGESTIONS.md). Core stays full-featured.

---

## Phase 5: Documentation and DX

- Split `AGENTS.md` (22KB) into `ARCHITECTURE.md` (for humans) + `AGENTS.md` (for AI)
- Add `docs/architecture/` with message flow diagrams
- Trim `README.md` (152KB!) to ~5KB essentials + links to docs site

---

## Comparison: SUGGESTIONS.md vs This Plan

| Aspect | SUGGESTIONS.md | This Plan |
|---|---|---|
| Philosophy | Amputation | Refactoring + config |
| Channels | 15 -> 1 | 15 -> 15 (config-driven) |
| Web UI | Remove | Keep, decouple from gateway |
| State | Sessions -> SQLite | All state -> SQLite |
| agents/ dir | Untouched | Split into 2-3 modules |
| Files removed | ~1,200 | ~200-250 |
| Files restructured | ~50-60 | ~400-500 (agents/ split) |
| Effort | 14-20h | 25-35h |
| Result | Telegram bot | Full multi-channel assistant, clean architecture |

---

## Priority Order

1. **Plugin loading fix** — 20 min, immediate win
2. **agents/ split** — biggest impact on maintainability
3. **SQLite state migration** — data safety
4. **Channel abstraction + config-driven registry** — extensibility
5. **Hot-swap LLM** — UX improvement
6. **Selective trimming** — cleanup
7. **Documentation** — can be done incrementally

---

## Key Thesis

The complexity of openclaw is NOT in the number of channels.
It is in the lack of boundaries between LLM orchestration, tool execution,
and model management inside `src/agents/`.
That is where effort should be directed.
