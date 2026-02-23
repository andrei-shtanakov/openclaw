import type { OrchidConfig } from "../../config/config.js";
import {
  resolveAllowlistProviderRuntimeGroupPolicy,
  resolveDefaultGroupPolicy,
  resolveOpenProviderRuntimeGroupPolicy,
} from "../../config/runtime-group-policy.js";
import { DEFAULT_ACCOUNT_ID, normalizeAccountId } from "../../routing/session-key.js";
import { formatPairingApproveHint } from "./helpers.js";
import { applyAccountNameToChannelSection } from "./setup-helpers.js";
import type { ChannelSecurityDmPolicy } from "./types.core.js";

// ---------------------------------------------------------------------------
// buildResolveDmPolicy
// ---------------------------------------------------------------------------

export type BuildResolveDmPolicyOpts = {
  channelKey: string;
  getPolicy: (account: unknown) => string | undefined;
  getAllowFrom: (account: unknown) => Array<string | number>;
  /** Subpath appended after basePath for allowFromPath (e.g. "dm." for Slack/Discord). */
  allowFromSubpath?: string;
  normalizeEntry?: (raw: string) => string;
};

export function buildResolveDmPolicy(opts: BuildResolveDmPolicyOpts) {
  return (ctx: {
    cfg: OrchidConfig;
    accountId?: string | null;
    account: unknown;
  }): ChannelSecurityDmPolicy => {
    const resolvedAccountId =
      ctx.accountId ??
      (ctx.account as { accountId?: string } | null)?.accountId ??
      DEFAULT_ACCOUNT_ID;

    const channels = ctx.cfg.channels as Record<string, unknown> | undefined;
    const section = channels?.[opts.channelKey] as
      | { accounts?: Record<string, unknown> }
      | undefined;
    const useAccountPath = Boolean(section?.accounts?.[resolvedAccountId]);

    const basePath = useAccountPath
      ? `channels.${opts.channelKey}.accounts.${resolvedAccountId}.`
      : `channels.${opts.channelKey}.`;

    const allowFromPath = opts.allowFromSubpath ? `${basePath}${opts.allowFromSubpath}` : basePath;

    const result: ChannelSecurityDmPolicy = {
      policy: opts.getPolicy(ctx.account) ?? "pairing",
      allowFrom: opts.getAllowFrom(ctx.account) ?? [],
      allowFromPath,
      approveHint: formatPairingApproveHint(opts.channelKey),
    };

    // Only include policyPath when there is no allowFromSubpath.
    // Channels like Slack/Discord that nest DM config under a subpath omit it.
    if (!opts.allowFromSubpath) {
      result.policyPath = `${basePath}dmPolicy`;
    }

    if (opts.normalizeEntry) {
      result.normalizeEntry = opts.normalizeEntry;
    }

    return result;
  };
}

// ---------------------------------------------------------------------------
// buildCollectWarnings
// ---------------------------------------------------------------------------

export type BuildCollectWarningsOpts = {
  channelKey: string;
  policyResolver: "allowlist" | "open";
  getGroupAllowlist: (account: unknown) => Record<string, unknown> | undefined;
  warningWithAllowlist: string;
  warningWithoutAllowlist: string;
};

export function buildCollectWarnings(opts: BuildCollectWarningsOpts) {
  return (ctx: { cfg: OrchidConfig; accountId?: string | null; account: unknown }): string[] => {
    const defaultGroupPolicy = resolveDefaultGroupPolicy(ctx.cfg);
    const acc = ctx.account as
      | {
          config?: { groupPolicy?: string };
          groupPolicy?: string;
        }
      | null
      | undefined;
    const groupPolicyRaw = acc?.config?.groupPolicy ?? acc?.groupPolicy;

    const resolver =
      opts.policyResolver === "allowlist"
        ? resolveAllowlistProviderRuntimeGroupPolicy
        : resolveOpenProviderRuntimeGroupPolicy;

    const channels = ctx.cfg.channels as Record<string, unknown> | undefined;
    const { groupPolicy } = resolver({
      providerConfigPresent: channels?.[opts.channelKey] !== undefined,
      groupPolicy: groupPolicyRaw as "open" | "allowlist" | "disabled" | undefined,
      defaultGroupPolicy,
    });

    if (groupPolicy !== "open") {
      return [];
    }

    const allowlist = opts.getGroupAllowlist(ctx.account);
    const hasAllowlist = allowlist !== undefined && Object.keys(allowlist).length > 0;

    return [hasAllowlist ? opts.warningWithAllowlist : opts.warningWithoutAllowlist];
  };
}

// ---------------------------------------------------------------------------
// buildSetupDefaults
// ---------------------------------------------------------------------------

export function buildSetupDefaults(channelKey: string) {
  return {
    resolveAccountId: (params: { accountId?: string }) => normalizeAccountId(params.accountId),
    applyAccountName: (params: { cfg: OrchidConfig; accountId: string; name?: string }) =>
      applyAccountNameToChannelSection({
        cfg: params.cfg,
        channelKey,
        accountId: params.accountId,
        name: params.name,
      }),
  };
}
