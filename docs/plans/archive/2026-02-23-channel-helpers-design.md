# Channel Helper Factories — Design

## Problem

7 channel extensions duplicate ~40 lines each of security and setup adapter code:

- `resolveDmPolicy` — builds DM policy object with config paths and normalizer
- `collectWarnings` — checks groupPolicy, emits warnings about open policies
- `resolveAccountId` + `applyAccountName` — identical boilerplate in setup adapter

Total: ~280 lines of duplicated code across extensions.

## Solution

Add factory functions to `src/channels/plugins/security-helpers.ts`, export via plugin-sdk. Each extension replaces inline code with a factory call, passing only channel-specific parameters.

### 1. `buildResolveDmPolicy` factory

Takes channel key, config accessors, and normalizer. Returns a `resolveDmPolicy` method matching `ChannelSecurityAdapter`.

Channels differ in:

- Config path to DM policy (Telegram: `config.dmPolicy`, Slack: `dm.policy`)
- Config path to allowFrom (Telegram: `config.allowFrom`, Slack: `dm.allowFrom`)
- Entry normalizer (strip `telegram:`, `slack:` prefixes)

### 2. `buildCollectWarnings` factory

Takes channel key, group policy resolver reference, allowlist accessor, and warning message strings. Returns `collectWarnings` method.

Channels differ in:

- Which group policy resolver to use (allowlist vs open provider)
- How to access group/channel allowlist from account config
- Warning message text

### 3. `buildSetupDefaults` factory

Takes channel key. Returns `{ resolveAccountId, applyAccountName }` — these are identical in all 7 extensions.

## What we don't change

- No changes to `ChannelPlugin` type or adapter interfaces
- No changes to existing `config-helpers.ts` or `setup-helpers.ts`
- No changes to channel-specific logic (normalizers, targets, outbound)
- Extensions keep full control — factories provide defaults

## Files to modify

| File                                       | Change                   |
| ------------------------------------------ | ------------------------ |
| `src/channels/plugins/security-helpers.ts` | New: factory functions   |
| `src/channels/plugins/index.ts`            | Export new helpers       |
| `src/plugin-sdk/index.ts`                  | Re-export for extensions |
| `extensions/telegram/src/channel.ts`       | Use factories            |
| `extensions/discord/src/channel.ts`        | Use factories            |
| `extensions/slack/src/channel.ts`          | Use factories            |
| `extensions/signal/src/channel.ts`         | Use factories            |
| `extensions/imessage/src/channel.ts`       | Use factories            |
| `extensions/whatsapp/src/channel.ts`       | Use factories            |
| `extensions/line/src/channel.ts`           | Use factories            |

## Impact

- ~280 lines removed (40 per extension × 7)
- ~80 lines added (security-helpers.ts)
- Net: ~200 lines eliminated
- All existing tests pass unchanged
