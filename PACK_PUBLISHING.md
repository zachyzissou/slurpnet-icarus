# Pack Publishing

This repo publishes one launcher-managed Icarus client pack:

- `api/SlurpNet_Icarus_Mods.zip`
- `api/SlurpNet_Icarus_Mods-manifest.json`
- a merged Icarus entry in `api/launcher-servers.json`
- a public-safe Icarus entry in `api/servers.json`

## Contract

`pak/SlurpNet.pak` is the only input artifact. It must be the JimK72 Icarus Mod
Manager merge output for the six Comfortable-tier mods.

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
python3 scripts/build-client-pack.py
```

The script writes the zip, manifest, blob file, and feed metadata under
`/mnt/cache/appdata/7dtd-downloads/api` by default.

Set `ICARUS_DOWNLOADS_DIR` to override the publish root for local dry runs.

