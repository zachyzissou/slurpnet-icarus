# SlurpNet Icarus Mods

All source mods listed here must be merged into a single `SlurpNet.pak` before
server deploy or launcher publish.

Do not deploy these as separate `.pak` files. The server and every client must
use the identical merged pak.

| Mod | Tier | Source URL | Notes |
|---|---|---|---|
| Icarus Plus | Comfortable legacy live-only | <https://www.nexusmods.com/icarus/mods/141?tab=files> file `1329` | Retired from the next approved rebuild; current live `2026.06.02a` still contains the inherited legacy pak. |
| laanp-PetesBeaconTeleport | Comfortable | <https://github.com/laanp/Icarus_Mods_Separated/releases/download/v1_w234/laanp-PetesBeaconTeleport_v1_w234_P.pak> | Beacon teleport |
| ItemFinder | Comfortable | <https://github.com/laanp/Icarus_Mods_Separated/releases/download/v1_w234/laanp-ItemFinder_v1_w234_P.pak> | Find dropped/stored items |
| CaveMaster | Comfortable | <https://github.com/laanp/Icarus_Mods_Separated/releases/download/v1_w234/laanp-CaveMaster_v1_w234_P.pak> | Cave quality-of-life |
| KeepTheTrees | Comfortable | <https://github.com/laanp/Icarus_Mods_Separated/releases/download/v1_w234/laanp-KeepTheTrees_v1_w234_P.pak> | Prevents tree-loss grind |
| Food Buff 5x | Comfortable legacy live-only | <https://www.nexusmods.com/icarus/mods/123?tab=files> file `1417` | Retired from the next approved rebuild unless explicit redistribution permission is recorded. |

## Current Live Build

- Output: `pak/SlurpNet.pak`
- SHA256: `832e0d7ba155939424b9be3b174b39da864371e15ba790596f5857bfc77c3378`
- Build host/tool: `repak v0.2.3` on SlurpNet Unraid
- Merge policy: unpack all six paks, canonicalize `Icarus/Content/data/` → `Icarus/Content/Data/`,
  structured-merge duplicate JSON data tables by `Rows[].Name`, last-wins on binary
  conflicts (priority order: IcarusPlus -> laanp set -> Food Buff 5x), then repack as V11.

This is the live legacy build, not the approved source set for the next public
rebuild. It still contains Icarus Plus and Food Buff 5x, which are retired from
the next approved pack.

## Next Approved Candidate

The next approved rebuild path is public-source-only laanp Week 234 content:

| Mod | Source URL | Role |
|---|---|---|
| laanp-Combined_QOL | <https://github.com/laanp/Icarus_Mods_Separated/releases/download/v1_w234/laanp-Combined_QOL_v1_w234_P.pak> | IcarusPlus replacement candidate |
| laanp-PetesBeaconTeleport | <https://github.com/laanp/Icarus_Mods_Separated/releases/download/v1_w234/laanp-PetesBeaconTeleport_v1_w234_P.pak> | Beacon teleport |
| ItemFinder | <https://github.com/laanp/Icarus_Mods_Separated/releases/download/v1_w234/laanp-ItemFinder_v1_w234_P.pak> | Find dropped/stored items |
| CaveMaster | <https://github.com/laanp/Icarus_Mods_Separated/releases/download/v1_w234/laanp-CaveMaster_v1_w234_P.pak> | Cave quality-of-life |
| KeepTheTrees | <https://github.com/laanp/Icarus_Mods_Separated/releases/download/v1_w234/laanp-KeepTheTrees_v1_w234_P.pak> | Prevents tree-loss grind |

Preflight artifact: `docs/combined-qol-preflight-2026-06-03.md`.

## Merge Contract

1. Put source mod folders under `Mods/`.
2. Use JimK72's Icarus Mod Manager or the documented `repak v0.2.3` flow to
   merge the approved source set into one pak.
3. Name the output exactly `SlurpNet.pak`.
4. Place it at `pak/SlurpNet.pak`.
5. Run `scripts/validate-icarus-release.sh`.
6. Deploy the same pak to the server and publish the same pak through the
   SlurpNet Launcher.

Weekly Icarus updates can break the merged pak. Rebuild and revalidate after
every Icarus update.
