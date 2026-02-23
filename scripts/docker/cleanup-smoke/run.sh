#!/usr/bin/env bash
set -euo pipefail

cd /repo

export ORCHID_STATE_DIR="/tmp/orchid-test"
export ORCHID_CONFIG_PATH="${ORCHID_STATE_DIR}/orchid.json"

echo "==> Build"
pnpm build

echo "==> Seed state"
mkdir -p "${ORCHID_STATE_DIR}/credentials"
mkdir -p "${ORCHID_STATE_DIR}/agents/main/sessions"
echo '{}' >"${ORCHID_CONFIG_PATH}"
echo 'creds' >"${ORCHID_STATE_DIR}/credentials/marker.txt"
echo 'session' >"${ORCHID_STATE_DIR}/agents/main/sessions/sessions.json"

echo "==> Reset (config+creds+sessions)"
pnpm orchid reset --scope config+creds+sessions --yes --non-interactive

test ! -f "${ORCHID_CONFIG_PATH}"
test ! -d "${ORCHID_STATE_DIR}/credentials"
test ! -d "${ORCHID_STATE_DIR}/agents/main/sessions"

echo "==> Recreate minimal config"
mkdir -p "${ORCHID_STATE_DIR}/credentials"
echo '{}' >"${ORCHID_CONFIG_PATH}"

echo "==> Uninstall (state only)"
pnpm orchid uninstall --state --yes --non-interactive

test ! -d "${ORCHID_STATE_DIR}"

echo "OK"
