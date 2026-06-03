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
# LoadProspect names a saved prospect under
# Icarus/Saved/PlayerData/DedicatedServer/Prospects/<NAME>.json. Without it
# the server boots into the entry map and the in-game Load/New buttons are
# greyed for non-admin players, so the operator-curated world never starts.
: "${LOAD_PROSPECT:=Slurplympus}"
# Allow any password-authed player to load/create a prospect. With this
# False, players who join without admin rights can only sit in the lobby.
# The server is password-protected at the join step already, so opening up
# prospect launch is appropriate for a small private server.
: "${ALLOW_NON_ADMINS_TO_LAUNCH_PROSPECTS:=True}"
: "${ALLOW_NON_ADMINS_TO_DELETE_PROSPECTS:=False}"
: "${RCON_PORT:=27037}"

rcon_block=""
if [ "${RCON_PASSWORD:-}" != "" ]; then
  rcon_block="RconEnabled=true
RconPort=${RCON_PORT}
RconPassword=${RCON_PASSWORD}"
fi

cat > "$OUT_FILE" <<EOF
[/Script/Icarus.DedicatedServerSettings]
SessionName=${SERVER_NAME}
JoinPassword=${SERVER_PASSWORD}
MaxPlayers=${MAX_PLAYERS}
AdminPassword=${ADMIN_PASSWORD}
ShutdownIfNotJoinedFor=-1
ShutdownIfEmptyFor=-1
AllowNonAdminsToLaunchProspects=${ALLOW_NON_ADMINS_TO_LAUNCH_PROSPECTS}
AllowNonAdminsToDeleteProspects=${ALLOW_NON_ADMINS_TO_DELETE_PROSPECTS}
ResumeProspect=True
LoadProspect=${LOAD_PROSPECT}
CreateProspect=
LastProspectName=
${rcon_block}

[/Script/Icarus.CustomWorldSettings]
GlobalExperienceMultiplier=2.0
EOF

echo "$OUT_FILE"
