# Self-Hosted Runner Persistence

This repo deploys through a repo-scoped GitHub Actions runner on the SlurpNet
Unraid host, matching the current SlurpNet game-server pattern.

## Runner Contract

- Workflow: `.github/workflows/deploy-icarus.yml`
- Repository: `zachyzissou/slurpnet-icarus`
- Runner container: `slurpnet-icarus-runner`
- Runner name: `slurpnet-icarus-unraid`
- Labels: `self-hosted`, `Linux`, `X64`, `unraid`, `lan`, `icarus-prod`
- Supervisor: Docker restart policy `unless-stopped`
- Persistent config dir: `/mnt/user/appdata/slurpnet-icarus-runner-config`
- Persistent work dir: `/mnt/user/appdata/slurpnet-icarus-runner-work`
- Required binds:
  - `/var/run/docker.sock`
  - `/mnt/user/appdata/slurpnet-icarus-runner-config`
  - `/mnt/user/appdata/slurpnet-icarus-runner-work`
  - `/mnt/cache/appdata/icarus`
  - `/mnt/user/appdata/steamcmd`
  - `/mnt/cache/appdata/7dtd-downloads`

The workflow checks out the repo on the Unraid runner, validates the runner can
see the live appdata and Docker daemon, renders production `ServerSettings.ini`
from GitHub Actions secrets, syncs repo-owned config and `pak/SlurpNet.pak`,
then restarts the `Icarus` container locally through the Docker socket.

## Recovery

Run from a local machine with `gh` authenticated for
`zachyzissou/slurpnet-icarus` and SSH access to Unraid:

```bash
bash scripts/reprovision-runner.sh
```

The script deletes stale runner registration, requests a fresh registration
token, and recreates the runner container with persistent `/runner-config` so
ordinary Unraid/container restarts do not require another token.

## Verify

```bash
docker logs slurpnet-icarus-runner --tail 40
docker inspect slurpnet-icarus-runner --format '{{.HostConfig.RestartPolicy.Name}}'
docker inspect slurpnet-icarus-runner --format '{{range .Mounts}}{{println .Source " -> " .Destination " rw=" .RW}}{{end}}'
gh api /repos/zachyzissou/slurpnet-icarus/actions/runners --jq '.runners[] | {name, status, busy, labels: [.labels[].name]}'
```

Expected:

- runner logs show `Listening for Jobs`
- restart policy is `unless-stopped`
- mounts include `/mnt/user/appdata/slurpnet-icarus-runner-config -> /runner-config`
- `slurpnet-icarus-unraid` is `online` and includes `icarus-prod`
