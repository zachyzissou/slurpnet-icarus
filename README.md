# SlurpNet Icarus

Source of truth for the SlurpNet Icarus dedicated server baseline and
launcher-managed client pak.

Current stable baseline:

- container: `Icarus`
- image: `ich777/steamcmd:icarus`
- server name: `SlurpNet Icarus`
- mode: Open World, persistent
- world: Olympus (prospect: `Slurplympus`, template `Outpost006_Olympus`)
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

| Purpose | Host port | Container port | Protocol |
|---|---:|---:|---|
| Game | `20008` | `20008` | UDP |
| Query | `20009` | `20009` | UDP |

The container and host ports intentionally match. Icarus advertises its
`-Port` and `-QueryPort` values to Steam, so asymmetric Docker mappings can make
Steam query ports that are not reachable from the WAN. The `20008/20009` scheme
avoids two conflicts on this Unraid box: `17777/UDP` is already Arma Reforger
A2S, and `27015/UDP` is bound by 7 Days to Die.

## Mod pak compatibility

Icarus mod compatibility is strict: the server and every client must use the
identical single merged `.pak`.

Do not ship the six source mods as six separate paks. Merge the Comfortable tier
into one `SlurpNet.pak` with JimK72's Icarus Mod Manager, deploy that same file
to the server, and publish that same file through the SlurpNet Launcher pack.

Weekly Icarus updates frequently break mods. After every Icarus update, assume
the merged pak is suspect until the operator rebuilds it, verifies the server
boots, and verifies a client can join with the launcher-installed pak.

Current live Comfortable tier (`2026.06.02a`, legacy six-mod pak):

- Icarus Plus
- laanp-PetesBeaconTeleport
- ItemFinder
- CaveMaster
- KeepTheTrees
- Food Buff 5x

Next approved rebuild path:

- retire Icarus Plus and Food Buff 5x from the public source set
- use `laanp-Combined_QOL_v1_w234_P.pak` plus the four maintained laanp
  separated paks
- keep the single merged `SlurpNet.pak` contract unchanged

See `Mods/MOD_LICENSES.md` and `docs/combined-qol-preflight-2026-06-03.md`.

## Server browser

Install the SlurpNet Icarus pack through the launcher, start Icarus from Steam,
choose Open World > Join, and search the server browser for `SlurpNet`.

The server is password protected. The public repo never stores the live server
password or admin password.

## UniFi / firewall

Forward these UDP ports to the Unraid host `192.168.225.196`:

- `20008/UDP` (game)
- `20009/UDP` (query)

Do not reuse Icarus defaults on the router — `17777/UDP` and `27015/UDP` are
owned by other game servers on this host.

## Operator Console Integration

The ops-backend collector does not use TCP Source RCON for Icarus. RocketWerkz
documents Icarus "RCON" as in-game chat/command-window admin commands backed by
`AdminPassword`; the official `ServerSettings.ini` sample does not define
`RconEnabled`, `RconPort`, or `RconPassword`. A non-production TCP preflight on
2026-06-03 bound `27037/TCP` but Source RCON auth reset the connection, so this
repo intentionally does not publish a TCP RCON port.

Current operator-console truth comes from:

- Docker fleet status for the `Icarus` container
- the ops-backend generic Icarus log-tail collector
- Steam query registration at `47.186.229.92:20009` with game port `20008`
- launcher feed and manifest metadata under `mods.slurpgg.net/api/`

See `docs/icarus-admin-query-surface-2026-06-03.md`.

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

By default `scripts/deploy.sh` restarts the existing `Icarus` container after
syncing config and pak files. To intentionally recreate the container from
`docker/docker-compose.yml`, set `ICARUS_RECONCILE_CONTAINER=1` for that deploy.

Runner recovery: see [docs/runner-persistence.md](./docs/runner-persistence.md).

## Links

- [Support](./SUPPORT.md)
- [Changelog](./CHANGELOG.md)
- [Code of Conduct](./CODE_OF_CONDUCT.md)
