#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${1:-$(pwd)}"
APPDATA="${ICARUS_APPDATA:-/mnt/cache/appdata/icarus}"
CONTAINER="${ICARUS_CONTAINER:-Icarus}"
SERVER_CONFIG_DIR="$APPDATA/Icarus/Saved/Config/WindowsServer"
SERVER_MOD_DIR="$APPDATA/Icarus/Content/Paks/mods"

cd "$WORKSPACE"

if [ ! -f "pak/SlurpNet.pak" ]; then
  echo "ERROR: pak/SlurpNet.pak missing. Merge the Comfortable tier first." >&2
  exit 1
fi

scripts/validate-icarus-release.sh

echo "Deploy from $WORKSPACE -> $APPDATA"
mkdir -p "$SERVER_CONFIG_DIR" "$SERVER_MOD_DIR"

echo "Syncing config/ServerSettings.ini -> $SERVER_CONFIG_DIR/ServerSettings.ini"
rsync -a config/ServerSettings.ini "$SERVER_CONFIG_DIR/ServerSettings.ini"

echo "Syncing pak/SlurpNet.pak -> $SERVER_MOD_DIR/SlurpNet.pak"
rsync -a pak/SlurpNet.pak "$SERVER_MOD_DIR/SlurpNet.pak"

echo "Restarting $CONTAINER..."
docker restart "$CONTAINER"

echo "Verifying container is running..."
docker inspect -f '{{.State.Running}}' "$CONTAINER" | grep -q '^true$'

echo "Deploy complete. Check logs with:"
echo "docker logs --tail 80 $CONTAINER 2>&1"
