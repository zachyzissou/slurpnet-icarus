# Combined_QOL Preflight - 2026-06-03

Scope: preflight `laanp-Combined_QOL_v1_w234_P.pak` as the IcarusPlus
replacement candidate and retire Food Buff 5x from the next approved public
SlurpNet Icarus rebuild.

This artifact does not deploy or publish the candidate pack. The repo rule still
requires explicit operator approval before production deploy or push, and the
final launcher-installed client join remains an operator/client test.

## Decision

- Replace Icarus Plus in the next approved public source set with
  `laanp-Combined_QOL_v1_w234_P.pak`.
- Remove Food Buff 5x from the next approved public source set unless explicit
  redistribution permission is recorded in `Mods/MOD_LICENSES.md`.
- Do not use the `laanp/Icarus_Mods` combined zip as the build input because it
  also includes `laanp-NoWeather_v1_w234_P.pak`. Use the separated direct pak.

## Upstream Evidence

- `laanp/Icarus_Mods_Separated` release: `v1_w234`, published 2026-05-29.
- `laanp/Icarus_Mods` release: `v1_w234`, published 2026-05-29.
- Combined_QOL upstream compatibility: Icarus Week 234 / `3.0.12.152317`,
  single player, hosted multiplayer, and dedicated server.
- Server/client parity remains mandatory: the server and every launcher client
  must use the identical single merged `SlurpNet.pak`.
- laanp README redistribution note permits redistribution when the README,
  disclaimer, and credits are referenced; SlurpNet tracks that in
  `Mods/MOD_LICENSES.md`.

## Source Inputs

Built on the Unraid host under `/tmp/icarus-combined-qol-preflight` with
`repak v0.2.3`.

| SHA256 | Source pak |
|---|---|
| `10a9e60b996506fcc3b51c8a794b1ebc94c068a71a16987660a8afe94fd8fea1` | `laanp-Combined_QOL_v1_w234_P.pak` |
| `95260eed0f3ed9771438a8365cb266c56f548d4e6ce86118df07e162cef9aa4f` | `laanp-PetesBeaconTeleport_v1_w234_P.pak` |
| `34bbaa206598670363cb483626f11b82e0d1c619c6dcfd5f2e5d24ee12eb0aae` | `laanp-ItemFinder_v1_w234_P.pak` |
| `5b19474c9b16671de34fd709d3166953626c48c78c2adae302a063709815a977` | `laanp-CaveMaster_v1_w234_P.pak` |
| `c0239dfd188b942087311b0c212feae31f014c1cb0ef93376f72c6467dfc00da` | `laanp-KeepTheTrees_v1_w234_P.pak` |

## Candidate Merge

Command shape:

```bash
repak unpack -f -q -o unpacked source/laanp-Combined_QOL_v1_w234_P.pak
repak unpack -f -q -o unpacked source/laanp-PetesBeaconTeleport_v1_w234_P.pak
repak unpack -f -q -o unpacked source/laanp-ItemFinder_v1_w234_P.pak
repak unpack -f -q -o unpacked source/laanp-CaveMaster_v1_w234_P.pak
repak unpack -f -q -o unpacked source/laanp-KeepTheTrees_v1_w234_P.pak
repak pack --version V11 -q unpacked candidate/SlurpNet-CombinedQOL-noFoodBuff.pak
```

Result:

- unpacked file count: `263`
- candidate pak: `/tmp/icarus-combined-qol-preflight/candidate/SlurpNet-CombinedQOL-noFoodBuff.pak`
- candidate size: `60810267` bytes
- candidate SHA256:
  `cf58be81ce382e4bf9c115a3430b917c6b9c302f534ddef459783fc048f98ce9`
- pak info: mount point `../../../`, version `V11`, unencrypted index,
  compression `None`, 263 file entries.

## Path Collisions

The raw `repak` preflight uses deterministic last-writer-wins unpack order. It
does not perform the row-aware JSON merge used for the current live
`2026.06.02a` build. These collisions must be reviewed before a production
swap:

| Path | Source paks |
|---|---|
| `Icarus/Content/Banner.png` | CaveMaster, ItemFinder |
| `Icarus/Content/Readme.txt` | CaveMaster, ItemFinder |
| `Icarus/Content/data/Crafting/D_ProcessorRecipes.json` | CaveMaster, Combined_QOL, ItemFinder, PetesBeaconTeleport |
| `Icarus/Content/data/Items/D_ItemTemplate.json` | CaveMaster, Combined_QOL, ItemFinder, PetesBeaconTeleport |
| `Icarus/Content/data/Items/D_ItemsStatic.json` | CaveMaster, Combined_QOL, ItemFinder, PetesBeaconTeleport |
| `Icarus/Content/data/Tools/D_Actions.json` | CaveMaster, Combined_QOL, ItemFinder, PetesBeaconTeleport |
| `Icarus/Content/data/Traits/D_Actionable.json` | CaveMaster, Combined_QOL, ItemFinder, PetesBeaconTeleport |
| `Icarus/Content/data/Traits/D_Itemable.json` | CaveMaster, Combined_QOL, ItemFinder, PetesBeaconTeleport |
| `Icarus/Content/data/Traits/D_Meshable.json` | Combined_QOL, PetesBeaconTeleport |

## Risk Notes

- Combined_QOL is broad and opinionated; it is not a narrow IcarusPlus clone.
- Combined_QOL does not replace Food Buff Duration 5x. It documents extra
  stomach slots, not 5x food buff duration.
- Save/prospect behavior can change if high-stack, storage-slot, or inventory
  mods are later removed.
- The final production candidate should use row-aware JSON merging for duplicate
  data tables or an IMM merge proof, not only the raw last-writer `repak`
  artifact above.

## Remaining Production Gates

- Boot a non-production Icarus server with the candidate pak.
- Verify the launcher-installed client can join with the identical candidate
  pak.
- Only after those gates, rename the approved artifact to `pak/SlurpNet.pak`,
  update `pack.json`/launcher metadata for the new version, and deploy through
  the manual `icarus-deploy` workflow.
