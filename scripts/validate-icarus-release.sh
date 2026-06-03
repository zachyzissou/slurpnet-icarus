#!/usr/bin/env bash
# shellcheck disable=SC2016
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
require_file Mods/MOD_LICENSES.md
require_file scripts/merge-pak.sh
require_file scripts/deploy.sh
require_file scripts/build-client-pack.py
require_file scripts/check-icarus-mod-sources.py
require_file scripts/check-source-rcon.py
require_file scripts/validate-unraid-runner-ready.sh
require_file scripts/reprovision-runner.sh
require_file docs/combined-qol-preflight-2026-06-03.md
require_file docs/runner-persistence.md

if [ "$missing" -ne 0 ]; then
  exit 1
fi

grep -q '^GAME_PORT=20008$' .env.example || { echo "ERROR: .env.example missing GAME_PORT=20008" >&2; exit 1; }
grep -q '^QUERY_PORT=20009$' .env.example || { echo "ERROR: .env.example missing QUERY_PORT=20009" >&2; exit 1; }
grep -q '^RCON_PORT=27037$' .env.example || { echo "ERROR: .env.example missing RCON_PORT=27037" >&2; exit 1; }
grep -q '^RCON_PASSWORD=$' .env.example || { echo "ERROR: .env.example must keep RCON_PASSWORD blank" >&2; exit 1; }
grep -q '^SERVER_PASSWORD=$' .env.example || { echo "ERROR: .env.example must keep SERVER_PASSWORD blank" >&2; exit 1; }
grep -q '^ADMIN_PASSWORD=$' .env.example || { echo "ERROR: .env.example must keep ADMIN_PASSWORD blank" >&2; exit 1; }
grep -q 'SERVER_NAME="SlurpNet Icarus"' .env.example || { echo "ERROR: .env.example missing server name" >&2; exit 1; }

grep -q 'image: ich777/steamcmd:icarus' docker/docker-compose.yml || { echo "ERROR: compose image must use verified fallback" >&2; exit 1; }
grep -q '\${GAME_PORT:-20008}:\${GAME_PORT:-20008}/udp' docker/docker-compose.yml || { echo "ERROR: compose missing symmetric game UDP port mapping (host:container both \${GAME_PORT:-20008})" >&2; exit 1; }
grep -q '\${QUERY_PORT:-20009}:\${QUERY_PORT:-20009}/udp' docker/docker-compose.yml || { echo "ERROR: compose missing symmetric query UDP port mapping (host:container both \${QUERY_PORT:-20009})" >&2; exit 1; }
grep -q '\${RCON_PORT:-27037}:\${RCON_PORT:-27037}/tcp' docker/docker-compose.yml || { echo "ERROR: compose missing RCON TCP port mapping" >&2; exit 1; }
grep -q 'cpuset: "32-47,96-111"' docker/docker-compose.yml || { echo "ERROR: compose missing SlurpNet CPU pinning" >&2; exit 1; }
grep -q 'mem_limit: 24g' docker/docker-compose.yml || { echo "ERROR: compose missing 24g memory ceiling" >&2; exit 1; }
grep -q '\${STEAMCMD_ROOT:-/mnt/user/appdata/steamcmd}:/serverdata/steamcmd' docker/docker-compose.yml || { echo "ERROR: compose must honor STEAMCMD_ROOT" >&2; exit 1; }
grep -q '\${APPDATA_ROOT:-/mnt/cache/appdata/icarus}:/serverdata/serverfiles' docker/docker-compose.yml || { echo "ERROR: compose must honor APPDATA_ROOT" >&2; exit 1; }
grep -q 'ICARUS_RECONCILE_CONTAINER=1' scripts/deploy.sh || { echo "ERROR: deploy script must keep container reconciliation explicit" >&2; exit 1; }
grep -q 'docker run' scripts/deploy.sh || { echo "ERROR: deploy script must support Unraid hosts without docker compose" >&2; exit 1; }
grep -q -- '-p "${GAME_PORT}:${GAME_PORT}/udp"' scripts/deploy.sh || { echo "ERROR: docker run fallback must use symmetric game port" >&2; exit 1; }
grep -q -- '-p "${QUERY_PORT}:${QUERY_PORT}/udp"' scripts/deploy.sh || { echo "ERROR: docker run fallback must use symmetric query port" >&2; exit 1; }
grep -q -- '-p "${RCON_PORT}:${RCON_PORT}/tcp"' scripts/deploy.sh || { echo "ERROR: docker run fallback must publish RCON tcp port" >&2; exit 1; }
! grep -q 'MultiHome' scripts/deploy.sh || { echo "ERROR: deploy fallback must not use MultiHome on Docker bridge" >&2; exit 1; }

grep -q '^JoinPassword=$' config/ServerSettings.ini || { echo "ERROR: public config must blank JoinPassword" >&2; exit 1; }
grep -q '^AdminPassword=$' config/ServerSettings.ini || { echo "ERROR: public config must blank AdminPassword" >&2; exit 1; }
grep -q '^GlobalExperienceMultiplier=2.0$' config/ServerSettings.ini || { echo "ERROR: config missing 2x XP" >&2; exit 1; }
grep -q '^ResumeProspect=True$' config/ServerSettings.ini || { echo "ERROR: config missing persistent resume" >&2; exit 1; }
! grep -qi 'operator decision required' Mods/MOD_LICENSES.md || { echo "ERROR: Mods/MOD_LICENSES.md has unresolved redistribution decisions" >&2; exit 1; }
grep -q 'Retire from the next approved pack' Mods/MOD_LICENSES.md || { echo "ERROR: Mods/MOD_LICENSES.md must record the Food Buff retirement decision" >&2; exit 1; }
grep -q 'cf58be81ce382e4bf9c115a3430b917c6b9c302f534ddef459783fc048f98ce9' docs/combined-qol-preflight-2026-06-03.md || { echo "ERROR: Combined_QOL preflight doc missing candidate SHA" >&2; exit 1; }
grep -q 'RCON_PASSWORD' .github/workflows/deploy-icarus.yml || { echo "ERROR: deploy workflow must render RCON_PASSWORD secret" >&2; exit 1; }
grep -q 'workflow_dispatch:' .github/workflows/deploy-icarus.yml || { echo "ERROR: deploy workflow must be manually dispatched" >&2; exit 1; }
! grep -q '^  push:' .github/workflows/deploy-icarus.yml || { echo "ERROR: deploy workflow must not auto-deploy on push" >&2; exit 1; }
grep -q 'RconEnabled=true' scripts/render-server-settings.sh || { echo "ERROR: render script missing RCON enable block" >&2; exit 1; }
grep -q 'check-source-rcon.py' .github/workflows/icarus-live-check.yml || { echo "ERROR: live-check workflow must run Source RCON smoke" >&2; exit 1; }

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
if entry.get("modpack", {}).get("version") != pack.get("version"):
    errors.append("launcher entry modpack.version must match pack.json version")
if entry.get("serverPort") != pack.get("launcher", {}).get("serverPort"):
    errors.append("launcher entry serverPort must match pack.json launcher.serverPort")
if entry.get("queryPort") != pack.get("launcher", {}).get("queryPort"):
    errors.append("launcher entry queryPort must match pack.json launcher.queryPort")
pak = Path("pak/SlurpNet.pak")
mods_text = Path("Mods/MODS.md").read_text(encoding="utf-8")
if pak.exists():
    import hashlib
    actual = hashlib.sha256(pak.read_bytes()).hexdigest()
    if actual not in mods_text:
        errors.append(f"Mods/MODS.md SHA256 does not match pak/SlurpNet.pak: {actual}")
if errors:
    for error in errors:
        print(f"ERROR: {error}")
    raise SystemExit(1)
PY

if find pak -maxdepth 1 -type f -name '*.pak' ! -name 'SlurpNet.pak' | grep -q .; then
  echo "ERROR: only pak/SlurpNet.pak may exist as a pak output" >&2
  exit 1
fi

if [ "${ICARUS_SKIP_MOD_SOURCE_CHECK:-0}" != "1" ]; then
  scripts/check-icarus-mod-sources.py
fi

echo "Icarus release validation passed."
