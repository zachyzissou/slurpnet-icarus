#!/usr/bin/env bash
set -euo pipefail

APPDATA="${ICARUS_APPDATA:-/mnt/cache/appdata/icarus}"
STEAMCMD_ROOT="${ICARUS_STEAMCMD_ROOT:-/mnt/user/appdata/steamcmd}"
CONTAINER="${ICARUS_CONTAINER:-Icarus}"
MIN_FREE_KB="${ICARUS_MIN_FREE_KB:-4194304}"

fail() {
  echo "ERROR runner preflight: $*" >&2
  exit 1
}

warn() {
  echo "WARN runner preflight: $*" >&2
}

require_writable_dir() {
  local label="$1"
  local path="$2"
  if [ ! -d "$path" ]; then
    fail "$label is not mounted or available: $path"
  fi
  local canary="$path/.slurpnet-icarus-preflight.$$"
  if ! : > "$canary" 2>/dev/null; then
    fail "$label is not writable: $path"
  fi
  rm -f "$canary"
}

require_min_free_space() {
  local label="$1"
  local path="$2"
  local available
  available="$(df -Pk "$path" | awk 'NR == 2 {print $4}')"
  if [ -z "$available" ]; then
    fail "could not determine free space for $label: $path"
  fi
  if [ "$available" -lt "$MIN_FREE_KB" ]; then
    fail "$label has only ${available} KiB free; need at least ${MIN_FREE_KB} KiB"
  fi
}

if [ ! -f docker/docker-compose.yml ] || [ ! -f config/ServerSettings.ini ] || [ ! -f Mods/MODS.md ]; then
  fail "run from the checked-out slurpnet-icarus workspace"
fi

require_writable_dir "Icarus appdata root" "$APPDATA"
require_writable_dir "SteamCMD root" "$STEAMCMD_ROOT"
require_min_free_space "Icarus appdata root" "$APPDATA"
require_min_free_space "SteamCMD root" "$STEAMCMD_ROOT"

if ! command -v docker >/dev/null 2>&1; then
  fail "docker CLI is unavailable on this runner"
fi
if ! docker info >/dev/null 2>&1; then
  fail "docker daemon is unavailable; Unraid Docker may be stopped"
fi
container_state="missing"
if docker inspect "$CONTAINER" >/dev/null 2>&1; then
  container_state="$(docker inspect "$CONTAINER" --format '{{.State.Status}}')"
  restart_policy="$(docker inspect "$CONTAINER" --format '{{.HostConfig.RestartPolicy.Name}}')"
  if [ "$restart_policy" != "unless-stopped" ]; then
    warn "Icarus container restart policy is '$restart_policy'; expected 'unless-stopped'"
  fi
else
  warn "Icarus container not found yet: $CONTAINER. First deploy will create it from docker/docker-compose.yml."
fi

echo "Runner preflight passed: appdata=$APPDATA steamcmd=$STEAMCMD_ROOT container=$CONTAINER state=$container_state"
