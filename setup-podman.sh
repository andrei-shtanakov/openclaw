#!/usr/bin/env bash
# One-time host setup for rootless Orchid in Podman: creates the orchid
# user, builds the image, loads it into that user's Podman store, and installs
# the launch script. Run from repo root with sudo capability.
#
# Usage: ./setup-podman.sh [--quadlet|--container]
#   --quadlet   Install systemd Quadlet so the container runs as a user service
#   --container Only install user + image + launch script; you start the container manually (default)
#   Or set ORCHID_PODMAN_QUADLET=1 (or 0) to choose without a flag.
#
# After this, start the gateway manually:
#   ./scripts/run-orchid-podman.sh launch
#   ./scripts/run-orchid-podman.sh launch setup   # onboarding wizard
# Or as the orchid user: sudo -u orchid /home/orchid/run-orchid-podman.sh
# If you used --quadlet, you can also: sudo systemctl --machine orchid@ --user start orchid.service
set -euo pipefail

ORCHID_USER="${ORCHID_PODMAN_USER:-orchid}"
REPO_PATH="${ORCHID_REPO_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
RUN_SCRIPT_SRC="$REPO_PATH/scripts/run-orchid-podman.sh"
QUADLET_TEMPLATE="$REPO_PATH/scripts/podman/orchid.container.in"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing dependency: $1" >&2
    exit 1
  fi
}

is_root() { [[ "$(id -u)" -eq 0 ]]; }

run_root() {
  if is_root; then
    "$@"
  else
    sudo "$@"
  fi
}

run_as_user() {
  local user="$1"
  shift
  if command -v sudo >/dev/null 2>&1; then
    sudo -u "$user" "$@"
  elif is_root && command -v runuser >/dev/null 2>&1; then
    runuser -u "$user" -- "$@"
  else
    echo "Need sudo (or root+runuser) to run commands as $user." >&2
    exit 1
  fi
}

run_as_orchid() {
  # Avoid root writes into $ORCHID_HOME (symlink/hardlink/TOCTOU footguns).
  # Anything under the target user's home should be created/modified as that user.
  run_as_user "$ORCHID_USER" env HOME="$ORCHID_HOME" "$@"
}

# Quadlet: opt-in via --quadlet or ORCHID_PODMAN_QUADLET=1
INSTALL_QUADLET=false
for arg in "$@"; do
  case "$arg" in
    --quadlet)   INSTALL_QUADLET=true ;;
    --container) INSTALL_QUADLET=false ;;
  esac
done
if [[ -n "${ORCHID_PODMAN_QUADLET:-}" ]]; then
  case "${ORCHID_PODMAN_QUADLET,,}" in
    1|yes|true)  INSTALL_QUADLET=true ;;
    0|no|false) INSTALL_QUADLET=false ;;
  esac
fi

require_cmd podman
if ! is_root; then
  require_cmd sudo
fi
if [[ ! -f "$REPO_PATH/Dockerfile" ]]; then
  echo "Dockerfile not found at $REPO_PATH. Set ORCHID_REPO_PATH to the repo root." >&2
  exit 1
fi
if [[ ! -f "$RUN_SCRIPT_SRC" ]]; then
  echo "Launch script not found at $RUN_SCRIPT_SRC." >&2
  exit 1
fi

generate_token_hex_32() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 32
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 - <<'PY'
import secrets
print(secrets.token_hex(32))
PY
    return 0
  fi
  if command -v od >/dev/null 2>&1; then
    # 32 random bytes -> 64 lowercase hex chars
    od -An -N32 -tx1 /dev/urandom | tr -d " \n"
    return 0
  fi
  echo "Missing dependency: need openssl or python3 (or od) to generate ORCHID_GATEWAY_TOKEN." >&2
  exit 1
}

user_exists() {
  local user="$1"
  if command -v getent >/dev/null 2>&1; then
    getent passwd "$user" >/dev/null 2>&1 && return 0
  fi
  id -u "$user" >/dev/null 2>&1
}

resolve_user_home() {
  local user="$1"
  local home=""
  if command -v getent >/dev/null 2>&1; then
    home="$(getent passwd "$user" 2>/dev/null | cut -d: -f6 || true)"
  fi
  if [[ -z "$home" && -f /etc/passwd ]]; then
    home="$(awk -F: -v u="$user" '$1==u {print $6}' /etc/passwd 2>/dev/null || true)"
  fi
  if [[ -z "$home" ]]; then
    home="/home/$user"
  fi
  printf '%s' "$home"
}

resolve_nologin_shell() {
  for cand in /usr/sbin/nologin /sbin/nologin /usr/bin/nologin /bin/false; do
    if [[ -x "$cand" ]]; then
      printf '%s' "$cand"
      return 0
    fi
  done
  printf '%s' "/usr/sbin/nologin"
}

# Create orchid user (non-login, with home) if missing
if ! user_exists "$ORCHID_USER"; then
  NOLOGIN_SHELL="$(resolve_nologin_shell)"
  echo "Creating user $ORCHID_USER ($NOLOGIN_SHELL, with home)..."
  if command -v useradd >/dev/null 2>&1; then
    run_root useradd -m -s "$NOLOGIN_SHELL" "$ORCHID_USER"
  elif command -v adduser >/dev/null 2>&1; then
    # Debian/Ubuntu: adduser supports --disabled-password/--gecos. Busybox adduser differs.
    run_root adduser --disabled-password --gecos "" --shell "$NOLOGIN_SHELL" "$ORCHID_USER"
  else
    echo "Neither useradd nor adduser found, cannot create user $ORCHID_USER." >&2
    exit 1
  fi
else
  echo "User $ORCHID_USER already exists."
fi

ORCHID_HOME="$(resolve_user_home "$ORCHID_USER")"
ORCHID_UID="$(id -u "$ORCHID_USER" 2>/dev/null || true)"
ORCHID_CONFIG="$ORCHID_HOME/.orchid"
LAUNCH_SCRIPT_DST="$ORCHID_HOME/run-orchid-podman.sh"

# Prefer systemd user services (Quadlet) for production. Enable lingering early so rootless Podman can run
# without an interactive login.
if command -v loginctl &>/dev/null; then
  run_root loginctl enable-linger "$ORCHID_USER" 2>/dev/null || true
fi
if [[ -n "${ORCHID_UID:-}" && -d /run/user ]] && command -v systemctl &>/dev/null; then
  run_root systemctl start "user@${ORCHID_UID}.service" 2>/dev/null || true
fi

# Rootless Podman needs subuid/subgid for the run user
if ! grep -q "^${ORCHID_USER}:" /etc/subuid 2>/dev/null; then
  echo "Warning: $ORCHID_USER has no subuid range. Rootless Podman may fail." >&2
  echo "  Add a line to /etc/subuid and /etc/subgid, e.g.: $ORCHID_USER:100000:65536" >&2
fi

echo "Creating $ORCHID_CONFIG and workspace..."
run_as_orchid mkdir -p "$ORCHID_CONFIG/workspace"
run_as_orchid chmod 700 "$ORCHID_CONFIG" "$ORCHID_CONFIG/workspace" 2>/dev/null || true

ENV_FILE="$ORCHID_CONFIG/.env"
if run_as_orchid test -f "$ENV_FILE"; then
  if ! run_as_orchid grep -q '^ORCHID_GATEWAY_TOKEN=' "$ENV_FILE" 2>/dev/null; then
    TOKEN="$(generate_token_hex_32)"
    printf 'ORCHID_GATEWAY_TOKEN=%s\n' "$TOKEN" | run_as_orchid tee -a "$ENV_FILE" >/dev/null
    echo "Added ORCHID_GATEWAY_TOKEN to $ENV_FILE."
  fi
  run_as_orchid chmod 600 "$ENV_FILE" 2>/dev/null || true
else
  TOKEN="$(generate_token_hex_32)"
  printf 'ORCHID_GATEWAY_TOKEN=%s\n' "$TOKEN" | run_as_orchid tee "$ENV_FILE" >/dev/null
  run_as_orchid chmod 600 "$ENV_FILE" 2>/dev/null || true
  echo "Created $ENV_FILE with new token."
fi

# The gateway refuses to start unless gateway.mode=local is set in config.
# Make first-run non-interactive; users can run the wizard later to configure channels/providers.
ORCHID_JSON="$ORCHID_CONFIG/orchid.json"
if ! run_as_orchid test -f "$ORCHID_JSON"; then
  printf '%s\n' '{ gateway: { mode: "local" } }' | run_as_orchid tee "$ORCHID_JSON" >/dev/null
  run_as_orchid chmod 600 "$ORCHID_JSON" 2>/dev/null || true
  echo "Created $ORCHID_JSON (minimal gateway.mode=local)."
fi

echo "Building image from $REPO_PATH..."
podman build -t orchid:local -f "$REPO_PATH/Dockerfile" "$REPO_PATH"

echo "Loading image into $ORCHID_USER's Podman store..."
TMP_IMAGE="$(mktemp -p /tmp orchid-image.XXXXXX.tar)"
trap 'rm -f "$TMP_IMAGE"' EXIT
podman save orchid:local -o "$TMP_IMAGE"
chmod 644 "$TMP_IMAGE"
(cd /tmp && run_as_user "$ORCHID_USER" env HOME="$ORCHID_HOME" podman load -i "$TMP_IMAGE")
rm -f "$TMP_IMAGE"
trap - EXIT

echo "Copying launch script to $LAUNCH_SCRIPT_DST..."
run_root cat "$RUN_SCRIPT_SRC" | run_as_orchid tee "$LAUNCH_SCRIPT_DST" >/dev/null
run_as_orchid chmod 755 "$LAUNCH_SCRIPT_DST"

# Optionally install systemd quadlet for orchid user (rootless Podman + systemd)
QUADLET_DIR="$ORCHID_HOME/.config/containers/systemd"
if [[ "$INSTALL_QUADLET" == true && -f "$QUADLET_TEMPLATE" ]]; then
  echo "Installing systemd quadlet for $ORCHID_USER..."
  run_as_orchid mkdir -p "$QUADLET_DIR"
  ORCHID_HOME_SED="$(printf '%s' "$ORCHID_HOME" | sed -e 's/[\\/&|]/\\\\&/g')"
  sed "s|{{ORCHID_HOME}}|$ORCHID_HOME_SED|g" "$QUADLET_TEMPLATE" | run_as_orchid tee "$QUADLET_DIR/orchid.container" >/dev/null
  run_as_orchid chmod 700 "$ORCHID_HOME/.config" "$ORCHID_HOME/.config/containers" "$QUADLET_DIR" 2>/dev/null || true
  run_as_orchid chmod 600 "$QUADLET_DIR/orchid.container" 2>/dev/null || true
  if command -v systemctl &>/dev/null; then
    run_root systemctl --machine "${ORCHID_USER}@" --user daemon-reload 2>/dev/null || true
    run_root systemctl --machine "${ORCHID_USER}@" --user enable orchid.service 2>/dev/null || true
    run_root systemctl --machine "${ORCHID_USER}@" --user start orchid.service 2>/dev/null || true
  fi
fi

echo ""
echo "Setup complete. Start the gateway:"
echo "  $RUN_SCRIPT_SRC launch"
echo "  $RUN_SCRIPT_SRC launch setup   # onboarding wizard"
echo "Or as $ORCHID_USER (e.g. from cron):"
echo "  sudo -u $ORCHID_USER $LAUNCH_SCRIPT_DST"
echo "  sudo -u $ORCHID_USER $LAUNCH_SCRIPT_DST setup"
if [[ "$INSTALL_QUADLET" == true ]]; then
  echo "Or use systemd (quadlet):"
  echo "  sudo systemctl --machine ${ORCHID_USER}@ --user start orchid.service"
  echo "  sudo systemctl --machine ${ORCHID_USER}@ --user status orchid.service"
else
  echo "To install systemd quadlet later: $0 --quadlet"
fi
