import type { OrchidConfig } from "./config.js";

export function ensurePluginAllowlisted(cfg: OrchidConfig, pluginId: string): OrchidConfig {
  const allow = cfg.plugins?.allow;
  if (!Array.isArray(allow) || allow.includes(pluginId)) {
    return cfg;
  }
  return {
    ...cfg,
    plugins: {
      ...cfg.plugins,
      allow: [...allow, pluginId],
    },
  };
}
