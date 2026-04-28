#!/usr/bin/env bash
set -euo pipefail

missing=0

require_file() {
  if [ ! -f "$1" ]; then
    echo "ERROR: missing $1" >&2
    missing=1
  fi
}

require_file README.md
require_file SECURITY.md
require_file CHANGELOG.md
require_file .env.example
require_file pack.json
require_file PACK_PUBLISHING.md
require_file launcher/servers-entry.json
require_file docker/docker-compose.yml
require_file config/ServerSettings.ini
require_file Mods/MODS.md
require_file scripts/merge-pak.sh
require_file scripts/deploy.sh
require_file scripts/build-client-pack.py
require_file scripts/validate-unraid-runner-ready.sh
require_file scripts/reprovision-runner.sh
require_file docs/runner-persistence.md

if [ "$missing" -ne 0 ]; then
  exit 1
fi

grep -q '^GAME_PORT=17787$' .env.example || { echo "ERROR: .env.example missing GAME_PORT=17787" >&2; exit 1; }
grep -q '^QUERY_PORT=27017$' .env.example || { echo "ERROR: .env.example missing QUERY_PORT=27017" >&2; exit 1; }
grep -q '^SERVER_PASSWORD=$' .env.example || { echo "ERROR: .env.example must keep SERVER_PASSWORD blank" >&2; exit 1; }
grep -q '^ADMIN_PASSWORD=$' .env.example || { echo "ERROR: .env.example must keep ADMIN_PASSWORD blank" >&2; exit 1; }
grep -q 'SERVER_NAME="SlurpNet Icarus"' .env.example || { echo "ERROR: .env.example missing server name" >&2; exit 1; }

grep -q 'image: ich777/steamcmd:icarus' docker/docker-compose.yml || { echo "ERROR: compose image must use verified fallback" >&2; exit 1; }
grep -q '\${GAME_PORT:-17787}:\${GAME_PORT:-17787}/udp' docker/docker-compose.yml || { echo "ERROR: compose missing game UDP port mapping" >&2; exit 1; }
grep -q '\${QUERY_PORT:-27017}:\${QUERY_PORT:-27017}/udp' docker/docker-compose.yml || { echo "ERROR: compose missing query UDP port mapping" >&2; exit 1; }
grep -q 'cpuset: "32-47,96-111"' docker/docker-compose.yml || { echo "ERROR: compose missing SlurpNet CPU pinning" >&2; exit 1; }
grep -q 'mem_limit: 24g' docker/docker-compose.yml || { echo "ERROR: compose missing 24g memory ceiling" >&2; exit 1; }

grep -q '^JoinPassword=$' config/ServerSettings.ini || { echo "ERROR: public config must blank JoinPassword" >&2; exit 1; }
grep -q '^AdminPassword=$' config/ServerSettings.ini || { echo "ERROR: public config must blank AdminPassword" >&2; exit 1; }
grep -q '^GlobalExperienceMultiplier=2.0$' config/ServerSettings.ini || { echo "ERROR: config missing 2x XP" >&2; exit 1; }
grep -q '^ResumeProspect=True$' config/ServerSettings.ini || { echo "ERROR: config missing persistent resume" >&2; exit 1; }

python3 - <<'PY'
import json
from pathlib import Path

pack = json.loads(Path("pack.json").read_text(encoding="utf-8"))
entry = json.loads(Path("launcher/servers-entry.json").read_text(encoding="utf-8"))
errors = []
if pack.get("serverId") != "icarus":
    errors.append("pack.json serverId must be icarus")
if pack.get("distributionMode") != "full_modpack":
    errors.append("pack.json distributionMode must be full_modpack")
if pack.get("clientArchivePath") != "Icarus/Content/Paks/mods/SlurpNet.pak":
    errors.append("clientArchivePath must install SlurpNet.pak under Icarus/Content/Paks/mods")
if entry.get("serverId") != "icarus":
    errors.append("launcher/servers-entry.json serverId must be icarus")
if entry.get("modpack", {}).get("url") != pack.get("liveZipUrl"):
    errors.append("launcher entry modpack.url must match pack liveZipUrl")
if entry.get("modpack", {}).get("manifestUrl") != pack.get("liveManifestUrl"):
    errors.append("launcher entry modpack.manifestUrl must match pack liveManifestUrl")
if errors:
    for error in errors:
        print(f"ERROR: {error}")
    raise SystemExit(1)
PY

if find pak -maxdepth 1 -type f -name '*.pak' ! -name 'SlurpNet.pak' | grep -q .; then
  echo "ERROR: only pak/SlurpNet.pak may exist as a pak output" >&2
  exit 1
fi

echo "Icarus release validation passed."
