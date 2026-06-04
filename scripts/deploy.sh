#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${1:-$(pwd)}"
APPDATA="${ICARUS_APPDATA:-${APPDATA_ROOT:-/mnt/cache/appdata/icarus}}"
CONTAINER="${ICARUS_CONTAINER:-Icarus}"
SERVER_CONFIG_DIR="$APPDATA/Icarus/Saved/Config/WindowsServer"
SERVER_MOD_DIR="$APPDATA/Icarus/Content/Paks/mods"
GAME_PORT="${GAME_PORT:-20008}"
QUERY_PORT="${QUERY_PORT:-20009}"
SERVER_NAME="${SERVER_NAME:-SlurpNet Icarus}"
RECONCILE_CONTAINER="${ICARUS_RECONCILE_CONTAINER:-0}"

export APPDATA_ROOT="$APPDATA"
export GAME_PORT QUERY_PORT SERVER_NAME

cd "$WORKSPACE"

if [ ! -f "pak/SlurpNet.pak" ]; then
  echo "ERROR: pak/SlurpNet.pak missing. Merge the Comfortable tier first." >&2
  exit 1
fi

echo "Deploy from $WORKSPACE -> $APPDATA"
mkdir -p "$SERVER_CONFIG_DIR" "$SERVER_MOD_DIR"

echo "Syncing config/ServerSettings.ini -> $SERVER_CONFIG_DIR/ServerSettings.ini"
rsync -a config/ServerSettings.ini "$SERVER_CONFIG_DIR/ServerSettings.ini"

echo "Syncing pak/SlurpNet.pak -> $SERVER_MOD_DIR/SlurpNet.pak"
rsync -a pak/SlurpNet.pak "$SERVER_MOD_DIR/SlurpNet.pak"

run_compose() {
  if docker compose version >/dev/null 2>&1; then
    compose_args=(-f docker/docker-compose.yml)
    if [ -f "$APPDATA/.env" ]; then
      compose_args=(--env-file "$APPDATA/.env" "${compose_args[@]}")
    else
      echo "WARNING: $APPDATA/.env not found; using exported environment only." >&2
    fi
    docker compose "${compose_args[@]}" up -d --force-recreate
    return
  fi

  if command -v docker-compose >/dev/null 2>&1; then
    compose_args=(-f docker/docker-compose.yml)
    if [ -f "$APPDATA/.env" ]; then
      compose_args=(--env-file "$APPDATA/.env" "${compose_args[@]}")
    else
      echo "WARNING: $APPDATA/.env not found; using exported environment only." >&2
    fi
    docker-compose "${compose_args[@]}" up -d --force-recreate
    return
  fi

  echo "docker compose not found; recreating $CONTAINER with docker run."
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  run_args=(
    -d
    --name "$CONTAINER"
    --restart unless-stopped
    --cpuset-cpus "32-47,96-111"
    --memory 24g
    -e GAME_ID="${GAME_ID:-2089300}"
    -e "GAME_PARAMS=-SteamServerName=\"${SERVER_NAME}\" -Port=${GAME_PORT} -QueryPort=${QUERY_PORT} -log"
    -e VALIDATE="${VALIDATE:-}"
    -e UID="${ICARUS_UID:-99}"
    -e GID="${ICARUS_GID:-100}"
    -e GAME_PORT="$GAME_PORT"
    -e QUERY_PORT="$QUERY_PORT"
    -e "SERVER_NAME=${SERVER_NAME}"
    -e MAX_PLAYERS="${MAX_PLAYERS:-8}"
    -e SERVER_PASSWORD
    -e ADMIN_PASSWORD
    -p "${GAME_PORT}:${GAME_PORT}/udp"
    -p "${QUERY_PORT}:${QUERY_PORT}/udp"
    -v "${STEAMCMD_ROOT:-/mnt/user/appdata/steamcmd}:/serverdata/steamcmd"
    -v "$APPDATA:/serverdata/serverfiles"
  )
  if [ -f "$APPDATA/.env" ]; then
    run_args=(--env-file "$APPDATA/.env" "${run_args[@]}")
  fi
  docker run "${run_args[@]}" ich777/steamcmd:icarus
}

if docker inspect "$CONTAINER" >/dev/null 2>&1; then
  if [ "$RECONCILE_CONTAINER" = "1" ]; then
    echo "ICARUS_RECONCILE_CONTAINER=1; recreating $CONTAINER from docker/docker-compose.yml..."
    docker rm -f "$CONTAINER" >/dev/null
    run_compose
  else
    echo "Restarting existing $CONTAINER. Set ICARUS_RECONCILE_CONTAINER=1 to recreate from compose."
    docker restart "$CONTAINER"
  fi
else
  echo "Container $CONTAINER not found; creating it from docker/docker-compose.yml..."
  run_compose
fi

echo "Verifying container is running..."
docker inspect -f '{{.State.Running}}' "$CONTAINER" | grep -q '^true$'

echo "Verifying published UDP ports..."
docker port "$CONTAINER" | tee /tmp/icarus-port-map.txt
grep -E "^${GAME_PORT}/udp -> .*:${GAME_PORT}$" /tmp/icarus-port-map.txt >/dev/null
grep -E "^${QUERY_PORT}/udp -> .*:${QUERY_PORT}$" /tmp/icarus-port-map.txt >/dev/null

echo "Deploy complete. Check logs with:"
echo "docker logs --tail 80 $CONTAINER 2>&1"
