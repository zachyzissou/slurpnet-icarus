#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${1:-.env}"
OUT_FILE="${2:-config/ServerSettings.rendered.ini}"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: missing env file: $ENV_FILE" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

: "${SERVER_NAME:=SlurpNet Icarus}"
: "${SERVER_PASSWORD:?SERVER_PASSWORD is required}"
: "${ADMIN_PASSWORD:?ADMIN_PASSWORD is required}"
: "${MAX_PLAYERS:=8}"

cat > "$OUT_FILE" <<EOF
[/Script/Icarus.DedicatedServerSettings]
SessionName=${SERVER_NAME}
JoinPassword=${SERVER_PASSWORD}
MaxPlayers=${MAX_PLAYERS}
AdminPassword=${ADMIN_PASSWORD}
ShutdownIfNotJoinedFor=-1
ShutdownIfEmptyFor=-1
AllowNonAdminsToLaunchProspects=False
AllowNonAdminsToDeleteProspects=False
ResumeProspect=True
LoadProspect=
CreateProspect=
LastProspectName=

[/Script/Icarus.CustomWorldSettings]
GlobalExperienceMultiplier=2.0
EOF

echo "$OUT_FILE"

