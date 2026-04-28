# SlurpNet Icarus Mods

All source mods listed here must be merged into a single `SlurpNet.pak` before
server deploy or launcher publish.

Do not deploy these as separate `.pak` files. The server and every client must
use the identical merged pak.

| Mod | Tier | Source URL | Notes |
|---|---|---|---|
| Icarus Plus | Comfortable | TODO operator verify source URL | Core quality-of-life baseline |
| laanp-PetesBeaconTeleport | Comfortable | TODO operator verify source URL | Beacon teleport |
| ItemFinder | Comfortable | TODO operator verify source URL | Find dropped/stored items |
| CaveMaster | Comfortable | TODO operator verify source URL | Cave quality-of-life |
| KeepTheTrees | Comfortable | TODO operator verify source URL | Prevents tree-loss grind |
| Food Buff 5x | Comfortable | TODO operator verify source URL | Longer food buff duration |

## Merge Contract

1. Put source mod folders under `Mods/`.
2. Use JimK72's Icarus Mod Manager to merge the six mods into one pak.
3. Name the output exactly `SlurpNet.pak`.
4. Place it at `pak/SlurpNet.pak`.
5. Run `scripts/validate-icarus-release.sh`.
6. Deploy the same pak to the server and publish the same pak through the
   SlurpNet Launcher.

Weekly Icarus updates can break the merged pak. Rebuild and revalidate after
every Icarus update.

