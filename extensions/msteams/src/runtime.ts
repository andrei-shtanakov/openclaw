import type { PluginRuntime } from "orchid/plugin-sdk";

let runtime: PluginRuntime | null = null;

export function setMSTeamsRuntime(next: PluginRuntime) {
  runtime = next;
}

export function getMSTeamsRuntime(): PluginRuntime {
  if (!runtime) {
    throw new Error("MSTeams runtime not initialized");
  }
  return runtime;
}
