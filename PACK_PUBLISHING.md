# Pack Publishing

This repo publishes one launcher-managed Icarus client pack:

- `api/SlurpNet_Icarus_Mods.zip`
- `api/SlurpNet_Icarus_Mods-manifest.json`
- a merged Icarus entry in `api/launcher-servers.json`
- a public-safe Icarus entry in `api/servers.json`

## Contract

`pak/SlurpNet.pak` is the only input artifact. It must be the JimK72 Icarus Mod
Manager or `repak v0.2.3` merge output for the approved source set recorded in
`Mods/MODS.md`.

The client archive installs the pak at:

```text
Icarus/Content/Paks/mods/SlurpNet.pak
```

The server deploy installs the same pak at:

```text
/mnt/cache/appdata/icarus/Icarus/Content/Paks/mods/SlurpNet.pak
```

Do not publish multiple Icarus paks. Server and clients must use the identical
single merged pak.

## Build

On the Unraid runner:

```bash
scripts/check-icarus-mod-sources.py
python3 scripts/build-client-pack.py
```

The script writes the zip, manifest, blob file, and feed metadata under
`/mnt/cache/appdata/slurpnet-content-origin/api` by default.

Set `ICARUS_DOWNLOADS_DIR` to override the publish root for local dry runs.

## Source and Redistribution Gates

Before publishing, `scripts/validate-icarus-release.sh` checks that the laanp
mods in `Mods/MODS.md` match the latest GitHub release assets. Nexus-sourced
mods are tracked in `Mods/MOD_LICENSES.md`; unresolved redistribution rows are a
release failure. Food Buff 5x and Icarus Plus are legacy live-only content and
must not be included in the next approved public rebuild unless explicit
permission is recorded in `Mods/MOD_LICENSES.md`.
