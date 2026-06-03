# SlurpNet Icarus Mod Redistribution Ledger

This file records whether each source mod can be redistributed through the
SlurpNet launcher as part of the merged `SlurpNet.pak`. It is a release gate,
not a legal opinion.

| Mod | Source | Current redistribution status | Release action |
|---|---|---|---|
| Icarus Plus | Nexus mod 141, legacy pak file 1329 | Legacy live-only artifact. Current public files have moved away from pak-only distribution and are not approved for a new SlurpNet public rebuild. | Retire from the next approved pack. Replacement candidate is `laanp-Combined_QOL_v1_w234_P.pak`; see `docs/combined-qol-preflight-2026-06-03.md`. |
| laanp-Combined_QOL | `laanp/Icarus_Mods_Separated` `v1_w234` | Approved for SlurpNet redistribution with upstream README attribution, disclaimer, and credits retained in repo docs. | Candidate IcarusPlus replacement for the next approved pack. Do not merge the bundled `NoWeather` asset from `laanp/Icarus_Mods`. |
| laanp-PetesBeaconTeleport | `laanp/Icarus_Mods_Separated` `v1_w234` | Approved for SlurpNet redistribution with upstream README attribution, disclaimer, and credits retained in repo docs. | Keep in current and next approved pack. |
| ItemFinder | `laanp/Icarus_Mods_Separated` `v1_w234` | Approved for SlurpNet redistribution with upstream README attribution, disclaimer, and credits retained in repo docs. | Keep in current and next approved pack. |
| CaveMaster | `laanp/Icarus_Mods_Separated` `v1_w234` | Approved for SlurpNet redistribution with upstream README attribution, disclaimer, and credits retained in repo docs. | Keep in current and next approved pack. |
| KeepTheTrees | `laanp/Icarus_Mods_Separated` `v1_w234` | Approved for SlurpNet redistribution with upstream README attribution, disclaimer, and credits retained in repo docs. | Keep in current and next approved pack. |
| Food Buff 5x | Nexus mod 123 file 1417 | Not approved for new SlurpNet public redistribution. Nexus permissions observed on 2026-06-03 disallow uploading this file to other sites and require permission for modification. | Retire from the next approved pack unless explicit redistribution permission is recorded here. The current `2026.06.02a` live pak remains documented as a legacy inherited artifact, not a cleared future source. |

## laanp Attribution

The laanp Week 234 paks used by SlurpNet come from these upstream repositories:

- <https://github.com/laanp/Icarus_Mods_Separated>
- <https://github.com/laanp/Icarus_Mods>

Retain links to the upstream README, disclaimer, and credits in release notes and
operator docs when publishing a SlurpNet rebuild that includes laanp content.
