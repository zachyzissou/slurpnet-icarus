# SlurpNet Icarus

Source of truth for the SlurpNet Icarus dedicated server baseline and
launcher-managed client pak.

Current stable baseline:

- container: `Icarus`
- image: `ich777/steamcmd:icarus`
- server name: `SlurpNet Icarus`
- mode: Open World, persistent
- world: Prometheus
- max players: 8
- appdata: `/mnt/cache/appdata/icarus/`
- Steam server app: `2089300`
- Steam client app: `1149460`

`ich777/icarus-server` was the preferred image in the deployment plan, but the
tag did not resolve during scaffolding. The current ich777 Unraid template uses
`ghcr.io/ich777/steamcmd:icarus`, and Docker Hub exposes
`ich777/steamcmd:icarus`, so this repo uses the verified fallback.

## What this repo owns

- `docker/docker-compose.yml` - Unraid compose stack for the Icarus container
- `config/ServerSettings.ini` - public-safe server settings template
- `Mods/` - source mod folders before merge
- `Mods/MODS.md` - approved Comfortable-tier mod list and source URL ledger
- `pack.json` - launcher pack and publishing contract
- `launcher/servers-entry.json` - rendered private launcher entry for review
- `pak/` - local output directory for the merged `SlurpNet.pak` (gitignored)
- `scripts/merge-pak.sh` - documented JimK72 Icarus Mod Manager handoff
- `scripts/build-client-pack.py` - publishes the launcher zip, manifest, blobs, and feed metadata
- `scripts/deploy.sh` - rsync config/pak to Unraid and restart `Icarus`
- `.github/workflows/` - validation, Unraid-runner deploy, repo health, and secret scan
- `docs/runner-persistence.md` - Unraid self-hosted runner contract and recovery

## Ports

| Purpose | Host port | Protocol |
|---|---:|---|
| Game | `17787` | UDP |
| Query | `27017` | UDP |

Icarus defaults are `17777/UDP` and `27015/UDP`; SlurpNet remaps them because
`17777/UDP` is already Arma Reforger A2S and live Unraid currently binds
`27015/UDP` for 7 Days to Die.

## Mod pak compatibility

Icarus mod compatibility is strict: the server and every client must use the
identical single merged `.pak`.

Do not ship the six source mods as six separate paks. Merge the Comfortable tier
into one `SlurpNet.pak` with JimK72's Icarus Mod Manager, deploy that same file
to the server, and publish that same file through the SlurpNet Launcher pack.

Weekly Icarus updates frequently break mods. After every Icarus update, assume
the merged pak is suspect until the operator rebuilds it, verifies the server
boots, and verifies a client can join with the launcher-installed pak.

Comfortable tier:

- Icarus Plus
- laanp-PetesBeaconTeleport
- ItemFinder
- CaveMaster
- KeepTheTrees
- Food Buff 5x

## Server browser

Install the SlurpNet Icarus pack through the launcher, start Icarus from Steam,
choose Open World > Join, and search the server browser for `SlurpNet`.

The server is password protected. The public repo never stores the live server
password or admin password.

## UniFi / firewall

Forward these UDP ports to the Unraid host `192.168.225.196`:

- `17787/UDP`
- `27017/UDP`

Do not reuse Icarus defaults on the router.

## Local setup

```bash
cp .env.example .env
```

Set `SERVER_PASSWORD` and generate a fresh `ADMIN_PASSWORD` in `.env`. The admin
password is production-only and must never be committed.

## Validate

```bash
scripts/validate-icarus-release.sh
```

The validation checks the public-safe config, env example, compose ports, and
the required pak filename contract.

## Deploy summary

Deployment runs through the repo-scoped self-hosted GitHub runner on Unraid:
`slurpnet-icarus-unraid` with labels `self-hosted`, `Linux`, `X64`, `unraid`,
`lan`, and `icarus-prod`.

1. Merge the six source mods into `pak/SlurpNet.pak`.
2. Commit to `main`.
3. Let `deploy-icarus.yml` run on the Unraid runner.
4. The workflow validates runner readiness, renders production
   `ServerSettings.ini` from GitHub Actions secrets, syncs `config/` and
   `pak/SlurpNet.pak` to `/mnt/cache/appdata/icarus/`, restarts `Icarus`, then
   publishes the launcher client zip/manifest and patches both launcher feeds.
5. Verify the server appears in the browser and a launcher-installed client can
   join.

The deploy sync is additive and does not delete runtime saves or generated
server state.

Runner recovery: see [docs/runner-persistence.md](./docs/runner-persistence.md).

## Links

- [Support](./SUPPORT.md)
- [Changelog](./CHANGELOG.md)
- [Code of Conduct](./CODE_OF_CONDUCT.md)
