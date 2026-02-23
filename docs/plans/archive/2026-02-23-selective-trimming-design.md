# Selective Trimming — Design

## Immediate Deletions (zero risk)

### Tier 1: Swabble/ (36 files)

Swift wake-word daemon for macOS. Zero TypeScript imports. Completely isolated.

### Tier 2: Untested minimal extensions (~11 files)

- `extensions/device-pair/` (2 files) — no tests, no users
- `extensions/phone-control/` (2 files) — no tests, no users
- `extensions/talk-voice/` (2 files) — no tests, no users
- `extensions/copilot-proxy/` (5 files) — no tests, no users

### Tier 5: open-prose wrapper (~90 files)

`extensions/open-prose/` is an openclaw wrapper (index.ts, openclaw.plugin.json, package.json) around prose skill content. The substantive content has been copied to `all_ai_orchestrators/open-prose/` as standalone. Fix 1 test reference, remove docs references.

## Deferred Deletions (30-90 day metrics check)

### Tier 4: Niche channels

- `extensions/tlon/` (32 files, 6 tests) — if no real users after metrics check, delete. Otherwise mark legacy.
- `extensions/synology-chat/` (16 files, 5 tests) — same criteria.

## Keep with needs-work status

### Tier 3: Auth providers

Do NOT delete. Add status warning to each README and create tracking issues.

- `extensions/google-gemini-cli-auth/` — priority 1 (has 1 existing test)
- `extensions/minimax-portal-auth/` — needs tests
- `extensions/qwen-portal-auth/` — needs tests
- `extensions/google-antigravity-auth/` — needs tests

Each gets:

1. README warning: `> Status: experimental — requires testing and coverage before production use.`
2. Tracking issue: write tests, verify API, validate auth flow.

## Files to modify

| Action | Target                               | Files    |
| ------ | ------------------------------------ | -------- |
| Delete | `Swabble/`                           | 36       |
| Delete | `extensions/device-pair/`            | 2        |
| Delete | `extensions/phone-control/`          | 2        |
| Delete | `extensions/talk-voice/`             | 2        |
| Delete | `extensions/copilot-proxy/`          | 5        |
| Delete | `extensions/open-prose/`             | ~90      |
| Fix    | Test referencing open-prose          | 1        |
| Fix    | Docs referencing open-prose          | ~5 lines |
| Add    | README warnings to 4 auth extensions | 4        |

**Total deleted: ~137 files**
