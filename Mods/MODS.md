# SlurpNet Icarus Mods

All source mods listed here must be merged into a single `SlurpNet.pak` before
server deploy or launcher publish.

Do not deploy these as separate `.pak` files. The server and every client must
use the identical merged pak.

| Mod | Tier | Source URL | Notes |
|---|---|---|---|
| Icarus Plus | Comfortable | <https://www.nexusmods.com/icarus/mods/141?tab=files> file `1329` | Core quality-of-life baseline; downloaded as `Icarus Plus 3.0.4.150844` |
| laanp-PetesBeaconTeleport | Comfortable | <https://github.com/laanp/Icarus_Mods_Separated/releases/download/v1_w229/laanp-PetesBeaconTeleport_v1_w229_P.pak> | Beacon teleport |
| ItemFinder | Comfortable | <https://github.com/laanp/Icarus_Mods_Separated/releases/download/v1_w229/laanp-ItemFinder_v1_w229_P.pak> | Find dropped/stored items |
| CaveMaster | Comfortable | <https://github.com/laanp/Icarus_Mods_Separated/releases/download/v1_w229/laanp-CaveMaster_v1_w229_P.pak> | Cave quality-of-life |
| KeepTheTrees | Comfortable | <https://github.com/laanp/Icarus_Mods_Separated/releases/download/v1_w229/laanp-KeepTheTrees_v1_w229_P.pak> | Prevents tree-loss grind |
| Food Buff 5x | Comfortable | <https://www.nexusmods.com/icarus/mods/123?tab=files> file `1417` | Longer food buff duration; downloaded as `Food Buff Duration 5x` |

## Current Build

- Output: `pak/SlurpNet.pak`
- SHA256: `e7fab780fdcbb51ea824426e687fcdc8846b30f43876418cd1ecc67f9da2e8b5`
- Build host/tool: `repak v0.2.3` on SlurpNet Unraid
- Merge policy: unpack all six paks, structured-merge duplicate JSON data
  tables by `Rows[].Name`, then repack as one pak.

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
