#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_NAME="${ORCHID_IMAGE:-${ORCHID_IMAGE:-orchid:local}}"
CONFIG_DIR="${ORCHID_CONFIG_DIR:-${ORCHID_CONFIG_DIR:-$HOME/.orchid}}"
WORKSPACE_DIR="${ORCHID_WORKSPACE_DIR:-${ORCHID_WORKSPACE_DIR:-$HOME/.orchid/workspace}}"
PROFILE_FILE="${ORCHID_PROFILE_FILE:-${ORCHID_PROFILE_FILE:-$HOME/.profile}}"

PROFILE_MOUNT=()
if [[ -f "$PROFILE_FILE" ]]; then
  PROFILE_MOUNT=(-v "$PROFILE_FILE":/home/node/.profile:ro)
fi

echo "==> Build image: $IMAGE_NAME"
docker build -t "$IMAGE_NAME" -f "$ROOT_DIR/Dockerfile" "$ROOT_DIR"

echo "==> Run live model tests (profile keys)"
docker run --rm -t \
  --entrypoint bash \
  -e COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
  -e HOME=/home/node \
  -e NODE_OPTIONS=--disable-warning=ExperimentalWarning \
  -e ORCHID_LIVE_TEST=1 \
  -e ORCHID_LIVE_MODELS="${ORCHID_LIVE_MODELS:-${ORCHID_LIVE_MODELS:-all}}" \
  -e ORCHID_LIVE_PROVIDERS="${ORCHID_LIVE_PROVIDERS:-${ORCHID_LIVE_PROVIDERS:-}}" \
  -e ORCHID_LIVE_MODEL_TIMEOUT_MS="${ORCHID_LIVE_MODEL_TIMEOUT_MS:-${ORCHID_LIVE_MODEL_TIMEOUT_MS:-}}" \
  -e ORCHID_LIVE_REQUIRE_PROFILE_KEYS="${ORCHID_LIVE_REQUIRE_PROFILE_KEYS:-${ORCHID_LIVE_REQUIRE_PROFILE_KEYS:-}}" \
  -v "$CONFIG_DIR":/home/node/.orchid \
  -v "$WORKSPACE_DIR":/home/node/.orchid/workspace \
  "${PROFILE_MOUNT[@]}" \
  "$IMAGE_NAME" \
  -lc "set -euo pipefail; [ -f \"$HOME/.profile\" ] && source \"$HOME/.profile\" || true; cd /app && pnpm test:live"
