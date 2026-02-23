# Предложения по доработке проекта orchid

## Стратегия: радикальное упрощение

Из 15-канального personal AI gateway → lean Telegram AI assistant с CLI/TUI.
Удаление ~1,200 файлов, сохранение данных, миграция структуры.

---

## 1. Удаление каналов (оставить только Telegram)

### 1.1. Что удалить

**Source directories:**

| Директория      | Файлов | Описание               |
| --------------- | ------ | ---------------------- |
| `src/discord/`  | 114    | Discord bot            |
| `src/slack/`    | 82     | Slack integration      |
| `src/web/`      | 78     | WhatsApp Web (Baileys) |
| `src/line/`     | 42     | LINE messenger         |
| `src/signal/`   | 31     | Signal protocol        |
| `src/imessage/` | 16     | iMessage bridge        |
| `src/whatsapp/` | 4      | WhatsApp core          |

**Extensions (удалить все кроме `extensions/telegram/`):**

```
extensions/bluebubbles/    extensions/discord/       extensions/feishu/
extensions/googlechat/     extensions/imessage/      extensions/irc/
extensions/line/           extensions/lobster/       extensions/matrix/
extensions/mattermost/     extensions/nostr/         extensions/signal/
extensions/slack/          extensions/synology-chat/ extensions/talk-voice/
extensions/twitch/         extensions/voice-call/    extensions/whatsapp/
extensions/zalo/           extensions/zalouser/      extensions/nextcloud-talk/
```

### 1.2. Что модифицировать

| Файл                              | Изменение                                                 |
| --------------------------------- | --------------------------------------------------------- |
| `src/channels/registry.ts`        | `CHAT_CHANNEL_ORDER` → только `["telegram"]`              |
| `src/channels/plugins/catalog.ts` | Удалить регистрации каналов кроме Telegram                |
| `src/cli/channels-cli.ts`         | Упростить до Telegram-only flow                           |
| `src/cli/channel-auth.ts`         | Удалить non-Telegram auth paths                           |
| `src/config/`                     | Удалить типы конфигов каналов (types.googlechat.ts и др.) |

### 1.3. Порядок удаления

1. Начать с наименее связанных: IRC, iMessage, Line
2. Затем: Signal, Matrix, Nostr, остальные extensions
3. Затем: Discord, Slack (больше coupling points)
4. Последним: WhatsApp + `src/web/` (наибольшая связность)
5. После каждого удаления — тесты

**Итого:** ~800-900 файлов удалить, ~50-60 модифицировать. **Усилия:** 3-4ч.

---

## 2. Удаление Google сервисов

### 2.1. Файлы на удаление

**Gemini LLM provider:**

```
src/infra/gemini-auth.ts
src/infra/provider-usage.fetch.gemini.ts
src/infra/provider-usage.fetch.gemini.test.ts
src/memory/embeddings-gemini.ts
src/memory/batch-gemini.ts
src/agents/pi-embedded-runner/google.ts
src/agents/pi-embedded-runner/google.e2e.test.ts
src/agents/schema/clean-for-gemini.ts
src/commands/google-gemini-model-default.ts
src/commands/auth-choice.apply.google-gemini-cli.ts
src/commands/auth-choice.apply.google-antigravity.ts
```

**Extensions:**

```
extensions/google-gemini-cli-auth/
extensions/google-antigravity-auth/
extensions/googlechat/
```

### 2.2. Файлы на модификацию

| Файл                                    | Изменение                             |
| --------------------------------------- | ------------------------------------- |
| `src/agents/models-config.ts`           | Удалить Gemini provider normalization |
| `src/agents/models-config.providers.ts` | Удалить Google provider handling      |
| `src/config/defaults.ts`                | Удалить Google service defaults       |
| `src/memory/manager-embedding-ops.ts`   | Удалить Gemini embedding fallback     |

**Итого:** ~30-35 файлов удалить, ~15-20 модифицировать. **Усилия:** 1-2ч.

---

## 3. Удаление web-интерфейса (оставить CLI/TUI)

### 3.1. Что удалить

| Директория                | Файлов | Описание                        |
| ------------------------- | ------ | ------------------------------- |
| `ui/`                     | ~200   | Весь React/Angular SPA frontend |
| `src/browser/`            | 99     | Browser automation (macOS app)  |
| `src/canvas-host/`        | 8      | Drawing surface (macOS app)     |
| `extensions/device-pair/` | —      | Device pairing UI               |
| `extensions/talk-voice/`  | —      | Voice call UI                   |
| `extensions/voice-call/`  | —      | Voice call extension            |

### 3.2. Что сохранить

- `src/gateway/` — control plane (HTTP API используется CLI/TUI)
- `src/cli/` (140+ файлов) — CLI commands
- `src/tui/` (~23K LOC) — Terminal UI

### 3.3. Что модифицировать

| Файл                                   | Изменение                                    |
| -------------------------------------- | -------------------------------------------- |
| `src/gateway/server.impl.ts`           | Удалить web UI route handling                |
| `src/gateway/server-runtime-config.ts` | `controlUiEnabled = false` всегда            |
| `src/gateway/control-ui.ts`            | Удалить serving static assets                |
| `src/gateway/control-ui-csp.ts`        | Удалить (CSP не нужен без web)               |
| `package.json`                         | Удалить Vite, React, Angular, UI зависимости |

**Итого:** ~350-400 файлов удалить, ~10-15 модифицировать. **Усилия:** 1-1.5ч.

---

## 4. Hot-swap LLM без перезагрузки

### 4.1. Текущее ограничение

`src/gateway/config-reload.ts:72`:

```typescript
{ prefix: "models", kind: "none" },  // ← требует ПОЛНЫЙ RESTART!
```

Модели загружаются при старте gateway через `ensureOrchidModelsJson()`. Изменение модели = перезапуск.

### 4.2. Решение: hot-reload для model config

**Создать:** `src/agents/model-reload-handler.ts` (~200 LOC)

```typescript
export function setupModelReloadHandler(gateway: GatewayContext) {
  // 1. Watch models.json для изменений
  // 2. Re-parse provider configs
  // 3. Invalidate model registry cache
  // 4. Emit "models-reloaded" event
  // 5. Текущие сессии продолжают с новой моделью
}
```

**Модифицировать:**

| Файл                                    | Изменение                                                       |
| --------------------------------------- | --------------------------------------------------------------- |
| `src/gateway/config-reload.ts`          | `{ prefix: "models", kind: "hot", actions: ["reload-models"] }` |
| `src/gateway/server-reload-handlers.ts` | Зарегистрировать model reload handler                           |
| `src/agents/models-config.ts`           | Добавить `invalidateModelCache()`                               |
| `src/agents/models-config.providers.ts` | Сделать provider registry обновляемым                           |

**CLI:** `orchid models switch <model-name>` — переключение без рестарта.

**Усилия:** 3-4ч (создание handler + интеграция + тесты).

---

## 5. Session store: JSON5 → SQLite

### 5.1. Текущая архитектура

- Sessions в `~/.orchid/state/sessions/default.json5`
- Весь файл загружается в память при старте
- Atomic write через `writeFileAtomically()`
- Нет locking, нет query — только full read/write

### 5.2. SQLite schema

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

**WAL mode** для concurrent reads + atomic writes.

### 5.3. Файлы

**Создать:**

| Файл                                   | LOC     | Назначение              |
| -------------------------------------- | ------- | ----------------------- |
| `src/config/session-store-sqlite.ts`   | 300-400 | SQLite schema + CRUD    |
| `src/config/migrate-sessions.ts`       | 200-300 | JSON5 → SQLite миграция |
| `src/commands/migrate-sessions-cli.ts` | 100-150 | CLI команда миграции    |

**Модифицировать:**

| Файл                     | Изменение                                         |
| ------------------------ | ------------------------------------------------- |
| `src/config/sessions.ts` | Dual backend: SQLite (primary) + JSON5 (fallback) |
| `src/config/config.ts`   | Добавить `sessionStore?: "json5" \| "sqlite"`     |
| `package.json`           | Добавить `better-sqlite3`                         |

### 5.4. Auto-migration при первом запуске

```typescript
async function loadSessionStore() {
  if (await sqliteDbExists()) {
    return sqliteStore.listSessions(agentId);
  }
  // Fallback: читаем JSON5, автоматически мигрируем
  const entries = await readJson5Sessions();
  await migrateToSQLite(entries);
  // JSON5 файл сохраняется как backup
  return entries;
}
```

**Усилия:** 4-5ч.

---

## 6. Миграция данных

### 6.1. Существующая инфраструктура

Уже есть migration framework:

- `src/infra/state-migrations.ts` (~500 LOC) — оркестратор миграций
- `src/config/legacy.migrations.part-{1,2,3}.ts` — конкретные миграции
- `src/commands/doctor-state-migrations.ts` — CLI

### 6.2. Расширение для новых миграций

Зарегистрировать новые миграции в существующий framework:

```typescript
registerMigration({
  id: "sessions-json5-to-sqlite-v1",
  version: "2026.3",

  async detect(): Promise<boolean> {
    return fileExists(jsonPath) && !fileExists(dbPath);
  },

  async migrate({ backup, dryRun }): Promise<MigrationResult> {
    if (backup) await backupFile(jsonPath);
    return await migrateSessionsToSQLite({ jsonPath, dbPath, dryRun });
  },

  async rollback(): Promise<void> {
    await restoreBackup(jsonPath);
    await remove(dbPath);
  },
});
```

**CLI:**

```bash
orchid config doctor --auto-migrate          # автоматически
orchid config doctor --list-migrations       # список
orchid config doctor --rollback <migration>  # откат
```

**Усилия:** 1-1.5ч (framework уже есть).

---

## 7. Баги для исправления попутно

### 7.1. Plugin loading all-or-nothing (HIGH)

`src/plugins/loader.ts` — если один plugin бросает exception на top-level import, весь registry не загружается. Нужен try-catch per-plugin.

**Fix:** ~20 строк — обернуть каждый plugin import в try-catch, логировать ошибку, продолжить загрузку остальных.

### 7.2. Race condition в session writes (MEDIUM)

Рекурсивный `fs.rm` конкурирует с in-flight session store writes. Документировано в тестах (`src/web/auto-reply.test-harness.ts:47-68`).

**Fix:** решается переходом на SQLite (WAL mode даёт atomic writes).

### 7.3. Hardcoded limits (LOW)

| Файл                                       | Значение                               | Предложение |
| ------------------------------------------ | -------------------------------------- | ----------- |
| `src/gateway/auth-rate-limit.ts:78`        | `MAX_ATTEMPTS = 10`                    | → config    |
| `src/gateway/server-channels.ts:18`        | `MAX_RESTART_ATTEMPTS = 10`            | → config    |
| `src/agents/pi-embedded-runner/run.ts:494` | `MAX_OVERFLOW_COMPACTION_ATTEMPTS = 3` | → config    |
| `src/memory/manager-embedding-ops.ts:29`   | `EMBEDDING_RETRY_MAX_ATTEMPTS = 3`     | → config    |

---

## 8. Что НЕ делать

| Идея                                | Причина отказа                               |
| ----------------------------------- | -------------------------------------------- |
| Prometheus metrics                  | Для personal tool достаточно Pino-логов      |
| Встроенный cost tracking            | Пользователь видит billing у провайдера      |
| Process isolation для plugins       | Try-catch per-plugin достаточен              |
| Distributed tracing (OpenTelemetry) | Single-process, single-user — overkill       |
| DAG orchestration (из Maestro/hive) | Openclaw маршрутизирует сообщения, не задачи |
| MITM proxy (из pylon/cc-wiretap)    | Контролирует LLM вызовы напрямую             |

---

## 9. Приоритетный roadmap

### Phase 1: Удаление каналов и Google (4-6ч)

1. Удалить extensions каналов (кроме telegram) — 20 директорий
2. Удалить src directories каналов (discord, slack, signal, imessage, whatsapp, web, line)
3. Удалить Google integrations (Gemini, Google Chat, auth extensions)
4. Обновить registry, config types, CLI
5. Тесты после каждого крупного удаления

### Phase 2: Удаление web UI (1-1.5ч)

1. Удалить `ui/` директорию целиком
2. Удалить `src/browser/`, `src/canvas-host/`
3. Отключить web UI serving в gateway
4. Очистить package.json от UI зависимостей

### Phase 3: Hot-swap LLM (3-4ч)

1. Создать `model-reload-handler.ts`
2. Изменить `config-reload.ts`: `models` kind → `"hot"`
3. Добавить `invalidateModelCache()` в models-config
4. CLI команда `orchid models switch`
5. Тесты reload pipeline

### Phase 4: SQLite sessions + миграция (5-6ч)

1. Создать SQLite session store с WAL mode
2. Создать migration tool (JSON5 → SQLite)
3. Зарегистрировать в existing migration framework
4. Auto-migration при первом запуске
5. CLI: `orchid config doctor --auto-migrate`
6. Тесты: round-trip, concurrent access, rollback

### Phase 5: Cleanup (1-2ч)

1. Fix plugin loading (try-catch per-plugin)
2. Вынести hardcoded limits в конфиг
3. Удалить неиспользуемые зависимости из package.json
4. Финальный full test suite

---

## 10. Итоговая оценка

| Метрика       | До                                | После                                 |
| ------------- | --------------------------------- | ------------------------------------- |
| Файлов в src  | ~3,440                            | ~2,000-2,200                          |
| Extensions    | 38                                | 1 (telegram)                          |
| Каналов       | 15+                               | 1 (Telegram)                          |
| UI targets    | Web + CLI + TUI                   | CLI + TUI                             |
| LLM providers | Anthropic + OpenAI + Gemini + ... | Anthropic + OpenAI + ... (без Google) |
| Session store | JSON5 (in-memory)                 | SQLite (WAL)                          |
| LLM switch    | Requires restart                  | Hot-swap                              |
| Усилия        | —                                 | 14-20ч (~2-3 дня)                     |
