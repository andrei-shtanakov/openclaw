import { describe, expect, it } from "vitest";
import type { OrchidConfig } from "../../config/config.js";
import {
  buildCollectWarnings,
  buildResolveDmPolicy,
  buildSetupDefaults,
} from "./security-helpers.js";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function cfg(channelKey: string, section?: Record<string, unknown> | null): OrchidConfig {
  if (section === null) {
    return {} as unknown as OrchidConfig;
  }
  return {
    channels: { [channelKey]: section ?? {} },
  } as unknown as OrchidConfig;
}

// ---------------------------------------------------------------------------
// buildResolveDmPolicy
// ---------------------------------------------------------------------------

describe("buildResolveDmPolicy", () => {
  const resolve = buildResolveDmPolicy({
    channelKey: "telegram",
    getPolicy: (acc) => (acc as { config?: { dmPolicy?: string } })?.config?.dmPolicy,
    getAllowFrom: (acc) => (acc as { config?: { allowFrom?: string[] } })?.config?.allowFrom ?? [],
    normalizeEntry: (raw) => raw.toLowerCase(),
  });

  it("returns default policy 'pairing' when account has no dmPolicy", () => {
    const result = resolve({
      cfg: cfg("telegram"),
      accountId: "default",
      account: { config: {} },
    });
    expect(result.policy).toBe("pairing");
  });

  it("returns the account dmPolicy when set", () => {
    const result = resolve({
      cfg: cfg("telegram"),
      accountId: "default",
      account: { config: { dmPolicy: "open" } },
    });
    expect(result.policy).toBe("open");
  });

  it("returns allowFrom from account config", () => {
    const result = resolve({
      cfg: cfg("telegram"),
      accountId: "default",
      account: { config: { allowFrom: ["123", "456"] } },
    });
    expect(result.allowFrom).toEqual(["123", "456"]);
  });

  it("uses base path when no account-level config exists", () => {
    const result = resolve({
      cfg: cfg("telegram"),
      accountId: "work",
      account: { config: {} },
    });
    expect(result.allowFromPath).toBe("channels.telegram.");
    expect(result.policyPath).toBe("channels.telegram.dmPolicy");
  });

  it("uses account path when account section exists in config", () => {
    const result = resolve({
      cfg: cfg("telegram", { accounts: { work: { token: "abc" } } }),
      accountId: "work",
      account: { config: {} },
    });
    expect(result.allowFromPath).toBe("channels.telegram.accounts.work.");
    expect(result.policyPath).toBe("channels.telegram.accounts.work.dmPolicy");
  });

  it("falls back to account.accountId when accountId param is null", () => {
    const result = resolve({
      cfg: cfg("telegram", { accounts: { myacc: {} } }),
      accountId: null,
      account: { accountId: "myacc", config: {} },
    });
    expect(result.allowFromPath).toBe("channels.telegram.accounts.myacc.");
  });

  it("falls back to DEFAULT_ACCOUNT_ID when both are missing", () => {
    const result = resolve({
      cfg: cfg("telegram"),
      account: { config: {} },
    });
    expect(result.allowFromPath).toBe("channels.telegram.");
  });

  it("includes normalizeEntry when provided", () => {
    const result = resolve({
      cfg: cfg("telegram"),
      accountId: "default",
      account: { config: {} },
    });
    expect(result.normalizeEntry).toBeDefined();
    expect(result.normalizeEntry!("ABC")).toBe("abc");
  });

  it("includes approveHint", () => {
    const result = resolve({
      cfg: cfg("telegram"),
      accountId: "default",
      account: { config: {} },
    });
    expect(result.approveHint).toContain("pairing");
  });

  describe("allowFromSubpath", () => {
    const resolveWithSubpath = buildResolveDmPolicy({
      channelKey: "discord",
      getPolicy: (acc) => (acc as { config?: { dm?: { policy?: string } } })?.config?.dm?.policy,
      getAllowFrom: (acc) =>
        (acc as { config?: { dm?: { allowFrom?: string[] } } })?.config?.dm?.allowFrom ?? [],
      allowFromSubpath: "dm.",
    });

    it("appends subpath to allowFromPath", () => {
      const result = resolveWithSubpath({
        cfg: cfg("discord"),
        accountId: "default",
        account: { config: {} },
      });
      expect(result.allowFromPath).toBe("channels.discord.dm.");
    });

    it("omits policyPath when allowFromSubpath is set", () => {
      const result = resolveWithSubpath({
        cfg: cfg("discord"),
        accountId: "default",
        account: { config: {} },
      });
      expect(result.policyPath).toBeUndefined();
    });

    it("appends subpath after account path", () => {
      const result = resolveWithSubpath({
        cfg: cfg("discord", { accounts: { work: {} } }),
        accountId: "work",
        account: { config: {} },
      });
      expect(result.allowFromPath).toBe("channels.discord.accounts.work.dm.");
    });
  });

  describe("without normalizeEntry", () => {
    const resolveNoNormalize = buildResolveDmPolicy({
      channelKey: "imessage",
      getPolicy: (acc) => (acc as { config?: { dmPolicy?: string } })?.config?.dmPolicy,
      getAllowFrom: (acc) =>
        (acc as { config?: { allowFrom?: string[] } })?.config?.allowFrom ?? [],
    });

    it("does not include normalizeEntry", () => {
      const result = resolveNoNormalize({
        cfg: cfg("imessage"),
        accountId: "default",
        account: { config: {} },
      });
      expect(result.normalizeEntry).toBeUndefined();
    });
  });
});

// ---------------------------------------------------------------------------
// buildCollectWarnings
// ---------------------------------------------------------------------------

describe("buildCollectWarnings", () => {
  const collectOpen = buildCollectWarnings({
    channelKey: "telegram",
    policyResolver: "open",
    getGroupAllowlist: (acc) =>
      (acc as { config?: { groups?: Record<string, unknown> } })?.config?.groups,
    warningWithAllowlist: "Groups are open with allowlist",
    warningWithoutAllowlist: "Groups are open without allowlist",
  });

  const collectAllowlist = buildCollectWarnings({
    channelKey: "slack",
    policyResolver: "allowlist",
    getGroupAllowlist: (acc) =>
      (acc as { config?: { channels?: Record<string, unknown> } })?.config?.channels,
    warningWithAllowlist: "Channels present",
    warningWithoutAllowlist: "No channels configured",
  });

  it("returns empty when groupPolicy resolves to non-open", () => {
    const result = collectOpen({
      cfg: cfg("telegram"),
      account: { config: { groupPolicy: "allowlist" } },
    });
    expect(result).toEqual([]);
  });

  it("returns empty when groupPolicy is disabled", () => {
    const result = collectOpen({
      cfg: cfg("telegram"),
      account: { config: { groupPolicy: "disabled" } },
    });
    expect(result).toEqual([]);
  });

  it("returns warningWithAllowlist when open and allowlist exists", () => {
    const result = collectOpen({
      cfg: cfg("telegram"),
      account: {
        config: { groupPolicy: "open", groups: { "123": {} } },
      },
    });
    expect(result).toEqual(["Groups are open with allowlist"]);
  });

  it("returns warningWithoutAllowlist when open and no allowlist", () => {
    const result = collectOpen({
      cfg: cfg("telegram"),
      account: { config: { groupPolicy: "open" } },
    });
    expect(result).toEqual(["Groups are open without allowlist"]);
  });

  it("returns warningWithoutAllowlist when allowlist is empty object", () => {
    const result = collectOpen({
      cfg: cfg("telegram"),
      account: { config: { groupPolicy: "open", groups: {} } },
    });
    expect(result).toEqual(["Groups are open without allowlist"]);
  });

  it("reads groupPolicy from account.groupPolicy when config is missing", () => {
    const result = collectOpen({
      cfg: cfg("telegram"),
      account: { groupPolicy: "open" },
    });
    expect(result).toEqual(["Groups are open without allowlist"]);
  });

  it("prefers account.config.groupPolicy over account.groupPolicy", () => {
    const result = collectOpen({
      cfg: cfg("telegram"),
      account: {
        groupPolicy: "open",
        config: { groupPolicy: "allowlist" },
      },
    });
    expect(result).toEqual([]);
  });

  it("works with allowlist resolver", () => {
    // With allowlist resolver, configured fallback is "allowlist"
    // so missing groupPolicy on a configured provider => allowlist (not open)
    const result = collectAllowlist({
      cfg: cfg("slack"),
      account: { config: {} },
    });
    expect(result).toEqual([]);
  });

  it("returns warnings with allowlist resolver when explicit open", () => {
    const result = collectAllowlist({
      cfg: cfg("slack"),
      account: {
        config: {
          groupPolicy: "open",
          channels: { general: {} },
        },
      },
    });
    expect(result).toEqual(["Channels present"]);
  });

  it("uses default group policy from config", () => {
    const cfgWithDefaults = {
      channels: {
        defaults: { groupPolicy: "open" },
        telegram: {},
      },
    } as unknown as OrchidConfig;
    const result = collectOpen({
      cfg: cfgWithDefaults,
      account: { config: {} },
    });
    expect(result).toEqual(["Groups are open without allowlist"]);
  });

  it("returns empty when provider config is missing (fail-closed)", () => {
    // When provider config is missing, both resolvers default to "allowlist"
    const result = collectOpen({
      cfg: cfg("telegram", null),
      account: { config: {} },
    });
    expect(result).toEqual([]);
  });
});

// ---------------------------------------------------------------------------
// buildSetupDefaults
// ---------------------------------------------------------------------------

describe("buildSetupDefaults", () => {
  const setup = buildSetupDefaults("telegram");

  it("returns an object with resolveAccountId and applyAccountName", () => {
    expect(setup).toHaveProperty("resolveAccountId");
    expect(setup).toHaveProperty("applyAccountName");
    expect(typeof setup.resolveAccountId).toBe("function");
    expect(typeof setup.applyAccountName).toBe("function");
  });

  describe("resolveAccountId", () => {
    it("returns 'default' for empty accountId", () => {
      expect(setup.resolveAccountId({ accountId: "" })).toBe("default");
    });

    it("returns 'default' for undefined accountId", () => {
      expect(setup.resolveAccountId({})).toBe("default");
    });

    it("normalizes the accountId", () => {
      expect(setup.resolveAccountId({ accountId: "  Work  " })).toBe("work");
    });

    it("passes through valid accountId", () => {
      expect(setup.resolveAccountId({ accountId: "personal" })).toBe("personal");
    });
  });

  describe("applyAccountName", () => {
    it("applies name to channel config", () => {
      const base = cfg("telegram");
      const result = setup.applyAccountName({
        cfg: base,
        accountId: "default",
        name: "My Bot",
      });
      const channels = result.channels as Record<string, unknown>;
      const section = channels.telegram as Record<string, unknown>;
      expect(section.name).toBe("My Bot");
    });

    it("returns unchanged config for empty name", () => {
      const base = cfg("telegram");
      const result = setup.applyAccountName({
        cfg: base,
        accountId: "default",
        name: "",
      });
      expect(result).toBe(base);
    });

    it("returns unchanged config for undefined name", () => {
      const base = cfg("telegram");
      const result = setup.applyAccountName({
        cfg: base,
        accountId: "default",
      });
      expect(result).toBe(base);
    });
  });
});
