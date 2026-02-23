import type {
  AnyAgentTool,
  OrchidPluginApi,
  OrchidPluginToolFactory,
} from "../../src/plugins/types.js";
import { createLobsterTool } from "./src/lobster-tool.js";

export default function register(api: OrchidPluginApi) {
  api.registerTool(
    ((ctx) => {
      if (ctx.sandboxed) {
        return null;
      }
      return createLobsterTool(api) as AnyAgentTool;
    }) as OrchidPluginToolFactory,
    { optional: true },
  );
}
