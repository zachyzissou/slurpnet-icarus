#!/usr/bin/env bash
# Recreate the Icarus self-hosted GitHub runner on Unraid.
# Requires local gh auth with runner-management permission and SSH access to Unraid.
set -euo pipefail

REPO="${ICARUS_RUNNER_REPO:-zachyzissou/slurpnet-icarus}"
SSH_TARGET="${ICARUS_RUNNER_SSH_TARGET:-root@192.168.225.196}"
SSH_PORT="${ICARUS_RUNNER_SSH_PORT:-40222}"
CONTAINER="${ICARUS_RUNNER_CONTAINER:-slurpnet-icarus-runner}"
RUNNER_NAME="${ICARUS_RUNNER_NAME:-slurpnet-icarus-unraid}"
LABELS="${ICARUS_RUNNER_LABELS:-unraid,lan,icarus-prod}"
CONFIG_DIR="${ICARUS_RUNNER_CONFIG_DIR:-/mnt/user/appdata/slurpnet-icarus-runner-config}"
WORK_DIR="${ICARUS_RUNNER_WORK_DIR:-/mnt/user/appdata/slurpnet-icarus-runner-work}"
IMAGE="${ICARUS_RUNNER_IMAGE:-myoung34/github-runner:latest}"
APPDATA="${ICARUS_APPDATA:-/mnt/cache/appdata/icarus}"
STEAMCMD_ROOT="${ICARUS_STEAMCMD_ROOT:-/mnt/user/appdata/steamcmd}"
DOWNLOADS_ROOT="${ICARUS_DOWNLOADS_ROOT:-/mnt/cache/appdata/7dtd-downloads}"

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI is required" >&2
  exit 1
fi

repo_url="https://github.com/${REPO}"
runner_id="$(gh api "repos/${REPO}/actions/runners" --jq ".runners[] | select(.name==\"${RUNNER_NAME}\") | .id" || true)"

ssh -p "$SSH_PORT" -o BatchMode=yes -o ConnectTimeout=8 "$SSH_TARGET" \
  "docker rm -f '$CONTAINER' '${CONTAINER}-bootstrap' >/dev/null 2>&1 || true"

if [ -n "$runner_id" ]; then
  echo "Deleting stale runner registration id=$runner_id"
  gh api -X DELETE "repos/${REPO}/actions/runners/${runner_id}" >/dev/null
fi

registration_token="$(gh api -X POST "repos/${REPO}/actions/runners/registration-token" --jq .token)"

ssh -p "$SSH_PORT" -o BatchMode=yes -o ConnectTimeout=8 "$SSH_TARGET" 'bash -s' <<EOF_REMOTE
set -euo pipefail
container='$CONTAINER'
config_dir='$CONFIG_DIR'
work_dir='$WORK_DIR'
image='$IMAGE'
appdata='$APPDATA'
steamcmd_root='$STEAMCMD_ROOT'
downloads_root='$DOWNLOADS_ROOT'
repo_url='$repo_url'
runner_name='$RUNNER_NAME'
labels='$LABELS'
env_file="/tmp/\${container}.env"

mkdir -p "\$config_dir" "\$work_dir" "\$appdata" "\$steamcmd_root" "\$downloads_root"
cat > "\$env_file" <<ENV
RUNNER_WORKDIR=/tmp/runner/work
REPO_URL=\$repo_url
RUNNER_NAME=\$runner_name
LABELS=\$labels
RUN_AS_ROOT=true
DISABLE_AUTO_UPDATE=true
DISABLE_AUTOMATIC_DEREGISTRATION=true
CONFIGURED_ACTIONS_RUNNER_FILES_DIR=/runner-config
RUNNER_TOKEN=$registration_token
ENV
chmod 600 "\$env_file"
docker run -d --name "\$container" --restart unless-stopped \
  --env-file "\$env_file" \
  -v "\$work_dir":/tmp/runner/work \
  -v "\$config_dir":/runner-config \
  -v "\$appdata":"\$appdata" \
  -v "\$steamcmd_root":"\$steamcmd_root" \
  -v "\$downloads_root":"\$downloads_root" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  "\$image" >/dev/null
rm -f "\$env_file"
docker inspect -f "runner={{.Name}} status={{.State.Status}} running={{.State.Running}} restart={{.RestartCount}} started={{.State.StartedAt}}" "\$container"
EOF_REMOTE

for _ in $(seq 1 30); do
  status="$(gh api "repos/${REPO}/actions/runners" --jq ".runners[] | select(.name==\"${RUNNER_NAME}\") | .status" || true)"
  if [ "$status" = "online" ]; then
    echo "runner_status=online"
    exit 0
  fi
  sleep 2
done

echo "ERROR: runner did not become online" >&2
gh api "repos/${REPO}/actions/runners" --jq ".runners[] | select(.name==\"${RUNNER_NAME}\") | {id,name,status,busy}" >&2 || true
exit 1
