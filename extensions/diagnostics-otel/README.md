# Diagnostics OpenTelemetry (Orchid plugin)

Export diagnostics events to an OpenTelemetry collector.

## Enable

```bash
orchid plugins enable diagnostics-otel
```

## Config

No additional configuration required. The plugin exports events to the default OTEL endpoint. Configure the OTEL collector via standard environment variables (`OTEL_EXPORTER_OTLP_ENDPOINT`, etc.).
