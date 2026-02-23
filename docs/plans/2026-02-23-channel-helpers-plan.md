# Channel Helper Factories — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Extract duplicated security and setup adapter code from 7 channel extensions into shared factory functions in the plugin-sdk.

**Architecture:** Add `security-helpers.ts` with 3 factory functions (`buildResolveDmPolicy`, `buildCollectWarnings`, `buildSetupDefaults`) to `src/channels/plugins/`. Export via `src/plugin-sdk/index.ts`. Update each extension to use factories instead of inline code.

**Tech Stack:** TypeScript, Vitest

---

## Task 1: Create security-helpers.ts with factory functions

**Files:**

- Create: `src/channels/plugins/security-helpers.ts`
- Create: `src/channels/plugins/security-helpers.test.ts`

**Step 1: Write the test file**

```typescript
// src/channels/plugins/security-helpers.test.ts
import { describe, expect, it } from "vitest";
import {
  buildResolveDmPolicy,
  buildCollectWarnings,
  buildSetupDefaults,
} from "./security-helpers.js";

describe("buildResolveDmPolicy", () => {
  const resolve = buildResolveDmPolicy({
    channelKey: "testchan",
    getPolicy: (account) => account.config.dmPolicy,
    getAllowFrom: (account) => account.config.allowFrom ?? [],
    normalizeEntry: (raw) => raw.replace(/^testchan:/i, ""),
  });

  it("returns policy from account config", () => {
    const result = resolve({
      cfg: { channels: { testchan: {} } } as any,
      accountId: "default",
      account: { accountId: "default", config: { dmPolicy: "open", allowFrom: ["alice"] } },
    });
    expect(result).toMatchObject({
      policy: "open",
      allowFrom: ["alice"],
      approveHint: expect.stringContaining("testchan"),
      normalizeEntry: expect.any(Function),
    });
  });

  it("uses base path when no accounts sub-object", () => {
    const result = resolve({
      cfg: { channels: { testchan: {} } } as any,
      accountId: "default",
      account: { accountId: "default", config: { dmPolicy: "pairing", allowFrom: [] } },
    });
    expect(result!.allowFromPath).toBe("channels.testchan.");
  });

  it("uses account path when accounts sub-object exists", () => {
    const result = resolve({
      cfg: { channels: { testchan: { accounts: { mybot: {} } } } } as any,
      accountId: "mybot",
      account: { accountId: "mybot", config: { dmPolicy: "pairing", allowFrom: [] } },
    });
    expect(result!.allowFromPath).toBe("channels.testchan.accounts.mybot.");
  });

  it("defaults policy to pairing when undefined", () => {
    const result = resolve({
      cfg: { channels: { testchan: {} } } as any,
      accountId: "default",
      account: { accountId: "default", config: {} },
    });
    expect(result!.policy).toBe("pairing");
  });

  it("supports custom allowFromPath for nested DM config", () => {
    const nestedResolve = buildResolveDmPolicy({
      channelKey: "slack",
      getPolicy: (account) => account.dm?.policy,
      getAllowFrom: (account) => account.dm?.allowFrom ?? [],
      allowFromSubpath: "dm.",
      normalizeEntry: (raw) => raw.replace(/^slack:/i, ""),
    });
    const result = nestedResolve({
      cfg: { channels: { slack: { accounts: { work: {} } } } } as any,
      accountId: "work",
      account: { accountId: "work", dm: { policy: "open", allowFrom: ["bob"] } },
    });
    expect(result!.allowFromPath).toBe("channels.slack.accounts.work.dm.");
  });
});

describe("buildCollectWarnings", () => {
  it("returns empty when groupPolicy is not open", () => {
    const collect = buildCollectWarnings({
      channelKey: "testchan",
      policyResolver: "allowlist",
      getGroupAllowlist: (account) => account.config.groups,
      warningWithAllowlist:
        '- TestChan groups: groupPolicy="open" allows any member in allowed groups.',
      warningWithoutAllowlist: '- TestChan groups: groupPolicy="open" with no allowlist.',
    });
    const result = collect({
      cfg: { channels: { testchan: {} } } as any,
      account: { config: { groupPolicy: "allowlist" } },
    });
    expect(result).toEqual([]);
  });

  it("returns allowlist warning when groups configured and policy is open", () => {
    const collect = buildCollectWarnings({
      channelKey: "testchan",
      policyResolver: "allowlist",
      getGroupAllowlist: (account) => account.config.groups,
      warningWithAllowlist: "with-allowlist warning",
      warningWithoutAllowlist: "without-allowlist warning",
    });
    const result = collect({
      cfg: { channels: { testchan: {} } } as any,
      account: { config: { groupPolicy: "open", groups: { g1: {} } } },
    });
    expect(result).toEqual(["with-allowlist warning"]);
  });

  it("returns no-allowlist warning when groups empty and policy is open", () => {
    const collect = buildCollectWarnings({
      channelKey: "testchan",
      policyResolver: "allowlist",
      getGroupAllowlist: (account) => account.config.groups,
      warningWithAllowlist: "with-allowlist warning",
      warningWithoutAllowlist: "without-allowlist warning",
    });
    const result = collect({
      cfg: { channels: { testchan: {} } } as any,
      account: { config: { groupPolicy: "open" } },
    });
    expect(result).toEqual(["without-allowlist warning"]);
  });

  it("uses open policy resolver when configured", () => {
    const collect = buildCollectWarnings({
      channelKey: "slack",
      policyResolver: "open",
      getGroupAllowlist: (account) => account.config.channels,
      warningWithAllowlist: "with warning",
      warningWithoutAllowlist: "without warning",
    });
    // With open resolver and provider present but no groupPolicy, defaults to "open"
    const result = collect({
      cfg: { channels: { slack: {} } } as any,
      account: { config: {} },
    });
    expect(result).toEqual(["without warning"]);
  });
});

describe("buildSetupDefaults", () => {
  it("returns resolveAccountId and applyAccountName", () => {
    const defaults = buildSetupDefaults("telegram");
    expect(defaults.resolveAccountId).toBeTypeOf("function");
    expect(defaults.applyAccountName).toBeTypeOf("function");
  });

  it("resolveAccountId normalizes the account ID", () => {
    const defaults = buildSetupDefaults("telegram");
    expect(defaults.resolveAccountId({ accountId: "  MyBot  " } as any)).toBe("mybot");
  });
});
```

**Step 2: Run tests to verify they fail**

```bash
pnpm vitest run src/channels/plugins/security-helpers.test.ts --reporter=verbose
```

Expected: FAIL (module not found)

**Step 3: Implement security-helpers.ts**

```typescript
// src/channels/plugins/security-helpers.ts
import type { OpenClawConfig } from "../../config/config.js";
import type { ChannelSecurityDmPolicy } from "./types.core.js";
import { DEFAULT_ACCOUNT_ID, normalizeAccountId } from "../../routing/session-key.js";
import { formatPairingApproveHint } from "./helpers.js";
import {
  resolveDefaultGroupPolicy,
  resolveAllowlistProviderRuntimeGroupPolicy,
  resolveOpenProviderRuntimeGroupPolicy,
} from "../../config/runtime-group-policy.js";
import { applyAccountNameToChannelSection } from "./setup-helpers.js";

// ---------------------------------------------------------------------------
// buildResolveDmPolicy
// ---------------------------------------------------------------------------

export type BuildResolveDmPolicyOpts = {
  channelKey: string;
  getPolicy: (account: any) => string | undefined;
  getAllowFrom: (account: any) => Array<string | number>;
  /** Sub-path between the account base and the allowFrom key (e.g. "dm." for Slack/Discord). */
  allowFromSubpath?: string;
  normalizeEntry?: (raw: string) => string;
};

export function buildResolveDmPolicy(
  opts: BuildResolveDmPolicyOpts,
): (ctx: {
  cfg: OpenClawConfig;
  accountId?: string | null;
  account: any;
}) => ChannelSecurityDmPolicy {
  return ({ cfg, accountId, account }) => {
    const resolvedAccountId = accountId ?? account.accountId ?? DEFAULT_ACCOUNT_ID;
    const channelConfig = (cfg.channels as Record<string, any> | undefined)?.[opts.channelKey];
    const useAccountPath = Boolean(channelConfig?.accounts?.[resolvedAccountId]);
    const sub = opts.allowFromSubpath ?? "";
    const basePath = useAccountPath
      ? `channels.${opts.channelKey}.accounts.${resolvedAccountId}.${sub}`
      : `channels.${opts.channelKey}.${sub}`;
    return {
      policy: opts.getPolicy(account) ?? "pairing",
      allowFrom: opts.getAllowFrom(account),
      policyPath: `${basePath.replace(/\.$/, "")}.dmPolicy`.replace(/\.\./, "."),
      allowFromPath: basePath,
      approveHint: formatPairingApproveHint(opts.channelKey),
      ...(opts.normalizeEntry ? { normalizeEntry: opts.normalizeEntry } : {}),
    };
  };
}

// ---------------------------------------------------------------------------
// buildCollectWarnings
// ---------------------------------------------------------------------------

export type BuildCollectWarningsOpts = {
  channelKey: string;
  /** Which group policy resolver to use: "allowlist" (strict) or "open" (permissive default). */
  policyResolver: "allowlist" | "open";
  getGroupAllowlist: (account: any) => Record<string, unknown> | undefined;
  warningWithAllowlist: string;
  warningWithoutAllowlist: string;
};

export function buildCollectWarnings(
  opts: BuildCollectWarningsOpts,
): (ctx: { cfg: OpenClawConfig; account: any }) => string[] {
  const resolve =
    opts.policyResolver === "allowlist"
      ? resolveAllowlistProviderRuntimeGroupPolicy
      : resolveOpenProviderRuntimeGroupPolicy;
  return ({ cfg, account }) => {
    const defaultGroupPolicy = resolveDefaultGroupPolicy(cfg);
    const channelConfig = (cfg.channels as Record<string, any> | undefined)?.[opts.channelKey];
    const { groupPolicy } = resolve({
      providerConfigPresent: channelConfig !== undefined,
      groupPolicy: account.config?.groupPolicy ?? account.groupPolicy,
      defaultGroupPolicy,
    });
    if (groupPolicy !== "open") {
      return [];
    }
    const allowlist = opts.getGroupAllowlist(account);
    const allowlistConfigured = Boolean(allowlist) && Object.keys(allowlist ?? {}).length > 0;
    return [allowlistConfigured ? opts.warningWithAllowlist : opts.warningWithoutAllowlist];
  };
}

// ---------------------------------------------------------------------------
// buildSetupDefaults
// ---------------------------------------------------------------------------

export function buildSetupDefaults(channelKey: string) {
  return {
    resolveAccountId: ({ accountId }: { accountId?: string }) => normalizeAccountId(accountId),
    applyAccountName: ({
      cfg,
      accountId,
      name,
    }: {
      cfg: OpenClawConfig;
      accountId: string;
      name?: string;
    }) => applyAccountNameToChannelSection({ cfg, channelKey, accountId, name }),
  };
}
```

**Step 4: Run tests to verify they pass**

```bash
pnpm vitest run src/channels/plugins/security-helpers.test.ts --reporter=verbose
```

Expected: All tests PASS

**Step 5: Commit**

```bash
scripts/committer "feat(plugin-sdk): add security and setup helper factories" src/channels/plugins/security-helpers.ts src/channels/plugins/security-helpers.test.ts
```

---

## Task 2: Export factories from plugin-sdk

**Files:**

- Modify: `src/plugin-sdk/index.ts`

**Step 1: Add exports**

After the existing `setup-helpers.js` export block (~line 310), add:

```typescript
export {
  buildResolveDmPolicy,
  buildCollectWarnings,
  buildSetupDefaults,
} from "../channels/plugins/security-helpers.js";
```

**Step 2: Type check**

```bash
pnpm tsgo 2>&1 | head -5
```

Expected: no new errors

**Step 3: Commit**

```bash
scripts/committer "feat(plugin-sdk): export channel helper factories" src/plugin-sdk/index.ts
```

---

## Task 3: Migrate Telegram extension to use factories

**Files:**

- Modify: `extensions/telegram/src/channel.ts`

**Step 1: Add imports**

Add to existing imports from plugin-sdk:

```typescript
import {
  // ... existing imports ...
  buildResolveDmPolicy,
  buildCollectWarnings,
  buildSetupDefaults,
} from "openclaw/plugin-sdk";
```

**Step 2: Replace security.resolveDmPolicy (lines ~184-198)**

Replace the inline `resolveDmPolicy` with:

```typescript
resolveDmPolicy: buildResolveDmPolicy({
  channelKey: "telegram",
  getPolicy: (account) => account.config.dmPolicy,
  getAllowFrom: (account) => account.config.allowFrom ?? [],
  normalizeEntry: (raw) => raw.replace(/^(telegram|tg):/i, ""),
}),
```

**Step 3: Replace security.collectWarnings (lines ~199-219)**

Replace inline `collectWarnings` with:

```typescript
collectWarnings: buildCollectWarnings({
  channelKey: "telegram",
  policyResolver: "allowlist",
  getGroupAllowlist: (account) => account.config.groups,
  warningWithAllowlist:
    '- Telegram groups: groupPolicy="open" allows any member in allowed groups to trigger (mention-gated). Set channels.telegram.groupPolicy="allowlist" + channels.telegram.groupAllowFrom to restrict senders.',
  warningWithoutAllowlist:
    '- Telegram groups: groupPolicy="open" with no channels.telegram.groups allowlist; any group can add + ping (mention-gated). Set channels.telegram.groupPolicy="allowlist" + channels.telegram.groupAllowFrom or configure channels.telegram.groups.',
}),
```

**Step 4: Replace setup.resolveAccountId and applyAccountName (lines ~242-249)**

Replace the two inline methods with spread:

```typescript
setup: {
  ...buildSetupDefaults("telegram"),
  validateInput: ({ accountId, input }) => {
    // ... keep existing validateInput unchanged ...
```

**Step 5: Remove unused imports**

Remove `resolveDefaultGroupPolicy`, `resolveAllowlistProviderRuntimeGroupPolicy` if no longer used directly.

**Step 6: Run Telegram tests**

```bash
pnpm vitest run extensions/telegram/ --reporter=verbose 2>&1 | tail -10
```

Expected: All tests PASS

**Step 7: Commit**

```bash
scripts/committer "refactor(telegram): use shared channel helper factories" extensions/telegram/src/channel.ts
```

---

## Task 4: Migrate Discord extension to use factories

**Files:**

- Modify: `extensions/discord/src/channel.ts`

**Step 1: Add imports and replace security/setup**

Same pattern as Telegram, with these channel-specific values:

```typescript
// security.resolveDmPolicy:
buildResolveDmPolicy({
  channelKey: "discord",
  getPolicy: (account) => account.config.dm?.policy,
  getAllowFrom: (account) => account.config.dm?.allowFrom ?? [],
  allowFromSubpath: "dm.",
  normalizeEntry: (raw) => raw.replace(/^(discord|user):/i, "").replace(/^<@!?(\d+)>$/, "$1"),
}),

// security.collectWarnings:
buildCollectWarnings({
  channelKey: "discord",
  policyResolver: "open",
  getGroupAllowlist: (account) => account.config.guilds,
  warningWithAllowlist:
    '- Discord guilds: groupPolicy="open" allows any channel not explicitly denied to trigger (mention-gated). Set channels.discord.groupPolicy="allowlist" and configure channels.discord.guilds.<id>.channels.',
  warningWithoutAllowlist:
    '- Discord guilds: groupPolicy="open" with no guild/channel allowlist; any channel can trigger (mention-gated). Set channels.discord.groupPolicy="allowlist" and configure channels.discord.guilds.<id>.channels.',
}),

// setup:
...buildSetupDefaults("discord"),
```

**Step 2: Run Discord tests**

```bash
pnpm vitest run extensions/discord/ --reporter=verbose 2>&1 | tail -10
```

**Step 3: Commit**

```bash
scripts/committer "refactor(discord): use shared channel helper factories" extensions/discord/src/channel.ts
```

---

## Task 5: Migrate Slack extension to use factories

**Files:**

- Modify: `extensions/slack/src/channel.ts`

**Step 1: Replace with channel-specific values**

```typescript
// security.resolveDmPolicy:
buildResolveDmPolicy({
  channelKey: "slack",
  getPolicy: (account) => account.dm?.policy,
  getAllowFrom: (account) => account.dm?.allowFrom ?? [],
  allowFromSubpath: "dm.",
  normalizeEntry: (raw) => raw.replace(/^(slack|user):/i, ""),
}),

// security.collectWarnings:
buildCollectWarnings({
  channelKey: "slack",
  policyResolver: "open",
  getGroupAllowlist: (account) => account.config.channels,
  warningWithAllowlist:
    '- Slack channels: groupPolicy="open" allows any channel not explicitly denied to trigger (mention-gated). Set channels.slack.groupPolicy="allowlist" and configure channels.slack.channels.',
  warningWithoutAllowlist:
    '- Slack channels: groupPolicy="open" with no channel allowlist; any channel can trigger (mention-gated). Set channels.slack.groupPolicy="allowlist" and configure channels.slack.channels.',
}),

// setup:
...buildSetupDefaults("slack"),
```

**Step 2: Run Slack tests**

```bash
pnpm vitest run extensions/slack/ --reporter=verbose 2>&1 | tail -10
```

**Step 3: Commit**

```bash
scripts/committer "refactor(slack): use shared channel helper factories" extensions/slack/src/channel.ts
```

---

## Task 6: Migrate Signal extension to use factories

**Files:**

- Modify: `extensions/signal/src/channel.ts`

**Step 1: Replace with channel-specific values**

```typescript
// security.resolveDmPolicy:
buildResolveDmPolicy({
  channelKey: "signal",
  getPolicy: (account) => account.config.dmPolicy,
  getAllowFrom: (account) => account.config.allowFrom ?? [],
  normalizeEntry: (raw) => normalizeE164(raw.replace(/^signal:/i, "").trim()),
}),

// security.collectWarnings:
buildCollectWarnings({
  channelKey: "signal",
  policyResolver: "allowlist",
  getGroupAllowlist: () => undefined, // Signal has no group allowlist config
  warningWithAllowlist: "", // unused — no allowlist concept
  warningWithoutAllowlist:
    '- Signal groups: groupPolicy="open" allows any member to trigger the bot. Set channels.signal.groupPolicy="allowlist" + channels.signal.groupAllowFrom to restrict senders.',
}),

// setup:
...buildSetupDefaults("signal"),
```

**Step 2: Run Signal tests**

```bash
pnpm vitest run extensions/signal/ --reporter=verbose 2>&1 | tail -10
```

**Step 3: Commit**

```bash
scripts/committer "refactor(signal): use shared channel helper factories" extensions/signal/src/channel.ts
```

---

## Task 7: Migrate iMessage extension to use factories

**Files:**

- Modify: `extensions/imessage/src/channel.ts`

**Step 1: Replace with channel-specific values**

```typescript
// security.resolveDmPolicy (note: no normalizeEntry — iMessage doesn't strip prefixes):
buildResolveDmPolicy({
  channelKey: "imessage",
  getPolicy: (account) => account.config.dmPolicy,
  getAllowFrom: (account) => account.config.allowFrom ?? [],
}),

// security.collectWarnings:
buildCollectWarnings({
  channelKey: "imessage",
  policyResolver: "allowlist",
  getGroupAllowlist: () => undefined,
  warningWithAllowlist: "",
  warningWithoutAllowlist:
    '- iMessage groups: groupPolicy="open" allows any member to trigger the bot. Set channels.imessage.groupPolicy="allowlist" + channels.imessage.groupAllowFrom to restrict senders.',
}),

// setup:
...buildSetupDefaults("imessage"),
```

**Step 2: Run iMessage tests**

```bash
pnpm vitest run extensions/imessage/ --reporter=verbose 2>&1 | tail -10
```

**Step 3: Commit**

```bash
scripts/committer "refactor(imessage): use shared channel helper factories" extensions/imessage/src/channel.ts
```

---

## Task 8: Migrate WhatsApp extension to use factories

**Files:**

- Modify: `extensions/whatsapp/src/channel.ts`

**Step 1: Replace with channel-specific values**

Note: WhatsApp account config is flatter — `account.dmPolicy` not `account.config.dmPolicy`.

```typescript
// security.resolveDmPolicy:
buildResolveDmPolicy({
  channelKey: "whatsapp",
  getPolicy: (account) => account.dmPolicy,
  getAllowFrom: (account) => account.allowFrom ?? [],
  normalizeEntry: (raw) => normalizeE164(raw),
}),

// security.collectWarnings:
buildCollectWarnings({
  channelKey: "whatsapp",
  policyResolver: "allowlist",
  getGroupAllowlist: (account) => account.groups,
  warningWithAllowlist:
    '- WhatsApp groups: groupPolicy="open" allows any member in allowed groups to trigger (mention-gated). Set channels.whatsapp.groupPolicy="allowlist" + channels.whatsapp.groupAllowFrom to restrict senders.',
  warningWithoutAllowlist:
    '- WhatsApp groups: groupPolicy="open" with no channels.whatsapp.groups allowlist; any group can add + ping (mention-gated). Set channels.whatsapp.groupPolicy="allowlist" + channels.whatsapp.groupAllowFrom or configure channels.whatsapp.groups.',
}),

// setup (note: alwaysUseAccounts for WhatsApp requires custom applyAccountName):
resolveAccountId: buildSetupDefaults("whatsapp").resolveAccountId,
// Keep existing custom applyAccountName with alwaysUseAccounts: true
```

**Step 2: Run WhatsApp tests**

```bash
pnpm vitest run extensions/whatsapp/ --reporter=verbose 2>&1 | tail -10
```

**Step 3: Commit**

```bash
scripts/committer "refactor(whatsapp): use shared channel helper factories" extensions/whatsapp/src/channel.ts
```

---

## Task 9: Migrate LINE extension to use factories

**Files:**

- Modify: `extensions/line/src/channel.ts`

**Step 1: Replace with channel-specific values**

Note: LINE uses `formatPairingApproveHint` with a custom string instead of the channel key, and has a custom `applyAccountName` with `alwaysUseAccounts`.

```typescript
// security.resolveDmPolicy (LINE uses custom approveHint — pass it via override after factory):
buildResolveDmPolicy({
  channelKey: "line",
  getPolicy: (account) => account.config.dmPolicy,
  getAllowFrom: (account) => account.config.allowFrom ?? [],
  normalizeEntry: (raw) => raw.replace(/^line:(?:user:)?/i, ""),
}),

// security.collectWarnings:
buildCollectWarnings({
  channelKey: "line",
  policyResolver: "allowlist",
  getGroupAllowlist: (account) => account.config.groups,
  warningWithAllowlist:
    '- LINE groups: groupPolicy="open" allows any member in groups to trigger. Set channels.line.groupPolicy="allowlist" + channels.line.groupAllowFrom to restrict senders.',
  warningWithoutAllowlist:
    '- LINE groups: groupPolicy="open" allows any member in groups to trigger. Set channels.line.groupPolicy="allowlist" + channels.line.groupAllowFrom to restrict senders.',
}),

// setup:
resolveAccountId: buildSetupDefaults("line").resolveAccountId,
// Keep existing custom applyAccountName (LINE has alwaysUseAccounts + migration logic)
```

**Step 2: Run LINE tests**

```bash
pnpm vitest run extensions/line/ --reporter=verbose 2>&1 | tail -10
```

**Step 3: Commit**

```bash
scripts/committer "refactor(line): use shared channel helper factories" extensions/line/src/channel.ts
```

---

## Task 10: Final verification

**Step 1: Run full test suite**

```bash
pnpm vitest run --reporter=verbose 2>&1 | tail -30
```

**Step 2: Type check**

```bash
pnpm tsgo 2>&1 | tail -10
```

**Step 3: Commit any fixes**

If any issues found, fix and commit.

---

## Summary

| Task      | What                               | Risk | Files  |
| --------- | ---------------------------------- | ---- | ------ |
| 1         | Create security-helpers.ts + tests | Low  | 2      |
| 2         | Export from plugin-sdk             | Low  | 1      |
| 3         | Migrate Telegram                   | Low  | 1      |
| 4         | Migrate Discord                    | Low  | 1      |
| 5         | Migrate Slack                      | Low  | 1      |
| 6         | Migrate Signal                     | Low  | 1      |
| 7         | Migrate iMessage                   | Low  | 1      |
| 8         | Migrate WhatsApp                   | Low  | 1      |
| 9         | Migrate LINE                       | Low  | 1      |
| 10        | Final verification                 | None | 0      |
| **Total** |                                    |      | **10** |
