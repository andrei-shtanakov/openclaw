---
summary: "Run Orchid in a rootless Podman container"
read_when:
  - You want a containerized gateway with Podman instead of Docker
title: "Podman"
---

# Podman

Run the Orchid gateway in a **rootless** Podman container. Uses the same image as Docker (build from the repo [Dockerfile](https://github.com/orchid/orchid/blob/main/Dockerfile)).

## Requirements

- Podman (rootless)
- Sudo for one-time setup (create user, build image)

## Quick start

**1. One-time setup** (from repo root; creates user, builds image, installs launch script):

```bash
./setup-podman.sh
```

This also creates a minimal `~orchid/.orchid/orchid.json` (sets `gateway.mode="local"`) so the gateway can start without running the wizard.

By default the container is **not** installed as a systemd service, you start it manually (see below). For a production-style setup with auto-start and restarts, install it as a systemd Quadlet user service instead:

```bash
./setup-podman.sh --quadlet
```

(Or set `ORCHID_PODMAN_QUADLET=1`; use `--container` to install only the container and launch script.)

**2. Start gateway** (manual, for quick smoke testing):

```bash
./scripts/run-orchid-podman.sh launch
```

**3. Onboarding wizard** (e.g. to add channels or providers):

```bash
./scripts/run-orchid-podman.sh launch setup
```

Then open `http://127.0.0.1:18789/` and use the token from `~orchid/.orchid/.env` (or the value printed by setup).

## Systemd (Quadlet, optional)

If you ran `./setup-podman.sh --quadlet` (or `ORCHID_PODMAN_QUADLET=1`), a [Podman Quadlet](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html) unit is installed so the gateway runs as a systemd user service for the orchid user. The service is enabled and started at the end of setup.

- **Start:** `sudo systemctl --machine orchid@ --user start orchid.service`
- **Stop:** `sudo systemctl --machine orchid@ --user stop orchid.service`
- **Status:** `sudo systemctl --machine orchid@ --user status orchid.service`
- **Logs:** `sudo journalctl --machine orchid@ --user -u orchid.service -f`

The quadlet file lives at `~orchid/.config/containers/systemd/orchid.container`. To change ports or env, edit that file (or the `.env` it sources), then `sudo systemctl --machine orchid@ --user daemon-reload` and restart the service. On boot, the service starts automatically if lingering is enabled for orchid (setup does this when loginctl is available).

To add quadlet **after** an initial setup that did not use it, re-run: `./setup-podman.sh --quadlet`.

## The orchid user (non-login)

`setup-podman.sh` creates a dedicated system user `orchid`:

- **Shell:** `nologin` — no interactive login; reduces attack surface.
- **Home:** e.g. `/home/orchid` — holds `~/.orchid` (config, workspace) and the launch script `run-orchid-podman.sh`.
- **Rootless Podman:** The user must have a **subuid** and **subgid** range. Many distros assign these automatically when the user is created. If setup prints a warning, add lines to `/etc/subuid` and `/etc/subgid`:

  ```text
  orchid:100000:65536
  ```

  Then start the gateway as that user (e.g. from cron or systemd):

  ```bash
  sudo -u orchid /home/orchid/run-orchid-podman.sh
  sudo -u orchid /home/orchid/run-orchid-podman.sh setup
  ```

- **Config:** Only `orchid` and root can access `/home/orchid/.orchid`. To edit config: use the Control UI once the gateway is running, or `sudo -u orchid $EDITOR /home/orchid/.orchid/orchid.json`.

## Environment and config

- **Token:** Stored in `~orchid/.orchid/.env` as `ORCHID_GATEWAY_TOKEN`. `setup-podman.sh` and `run-orchid-podman.sh` generate it if missing (uses `openssl`, `python3`, or `od`).
- **Optional:** In that `.env` you can set provider keys (e.g. `GROQ_API_KEY`, `OLLAMA_API_KEY`) and other Orchid env vars.
- **Host ports:** By default the script maps `18789` (gateway) and `18790` (bridge). Override the **host** port mapping with `ORCHID_PODMAN_GATEWAY_HOST_PORT` and `ORCHID_PODMAN_BRIDGE_HOST_PORT` when launching.
- **Paths:** Host config and workspace default to `~orchid/.orchid` and `~orchid/.orchid/workspace`. Override the host paths used by the launch script with `ORCHID_CONFIG_DIR` and `ORCHID_WORKSPACE_DIR`.

## Useful commands

- **Logs:** With quadlet: `sudo journalctl --machine orchid@ --user -u orchid.service -f`. With script: `sudo -u orchid podman logs -f orchid`
- **Stop:** With quadlet: `sudo systemctl --machine orchid@ --user stop orchid.service`. With script: `sudo -u orchid podman stop orchid`
- **Start again:** With quadlet: `sudo systemctl --machine orchid@ --user start orchid.service`. With script: re-run the launch script or `podman start orchid`
- **Remove container:** `sudo -u orchid podman rm -f orchid` — config and workspace on the host are kept

## Troubleshooting

- **Permission denied (EACCES) on config or auth-profiles:** The container defaults to `--userns=keep-id` and runs as the same uid/gid as the host user running the script. Ensure your host `ORCHID_CONFIG_DIR` and `ORCHID_WORKSPACE_DIR` are owned by that user.
- **Gateway start blocked (missing `gateway.mode=local`):** Ensure `~orchid/.orchid/orchid.json` exists and sets `gateway.mode="local"`. `setup-podman.sh` creates this file if missing.
- **Rootless Podman fails for user orchid:** Check `/etc/subuid` and `/etc/subgid` contain a line for `orchid` (e.g. `orchid:100000:65536`). Add it if missing and restart.
- **Container name in use:** The launch script uses `podman run --replace`, so the existing container is replaced when you start again. To clean up manually: `podman rm -f orchid`.
- **Script not found when running as orchid:** Ensure `setup-podman.sh` was run so that `run-orchid-podman.sh` is copied to orchid’s home (e.g. `/home/orchid/run-orchid-podman.sh`).
- **Quadlet service not found or fails to start:** Run `sudo systemctl --machine orchid@ --user daemon-reload` after editing the `.container` file. Quadlet requires cgroups v2: `podman info --format '{{.Host.CgroupsVersion}}'` should show `2`.

## Optional: run as your own user

To run the gateway as your normal user (no dedicated orchid user): build the image, create `~/.orchid/.env` with `ORCHID_GATEWAY_TOKEN`, and run the container with `--userns=keep-id` and mounts to your `~/.orchid`. The launch script is designed for the orchid-user flow; for a single-user setup you can instead run the `podman run` command from the script manually, pointing config and workspace to your home. Recommended for most users: use `setup-podman.sh` and run as the orchid user so config and process are isolated.
