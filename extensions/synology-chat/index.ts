import type { OrchidPluginApi } from "orchid/plugin-sdk";
import { emptyPluginConfigSchema } from "orchid/plugin-sdk";
import { createSynologyChatPlugin } from "./src/channel.js";
import { setSynologyRuntime } from "./src/runtime.js";

const plugin = {
  id: "synology-chat",
  name: "Synology Chat",
  description: "Native Synology Chat channel plugin for Orchid",
  configSchema: emptyPluginConfigSchema(),
  register(api: OrchidPluginApi) {
    setSynologyRuntime(api.runtime);
    api.registerChannel({ plugin: createSynologyChatPlugin() });
  },
};

export default plugin;
