import type { OrchidPluginApi } from "orchid/plugin-sdk";
import { emptyPluginConfigSchema } from "orchid/plugin-sdk";
import { createDiagnosticsOtelService } from "./src/service.js";

const plugin = {
  id: "diagnostics-otel",
  name: "Diagnostics OpenTelemetry",
  description: "Export diagnostics events to OpenTelemetry",
  configSchema: emptyPluginConfigSchema(),
  register(api: OrchidPluginApi) {
    api.registerService(createDiagnosticsOtelService());
  },
};

export default plugin;
