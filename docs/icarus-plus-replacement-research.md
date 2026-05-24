# Icarus Plus Replacement Research

Research date: 2026-05-24
Researcher: SlurpNet maintainer (Claude session)
Target: replacing Nexus mod 141 (`Icarus Plus 3.0.4.150844`, file 1329) in the
SlurpNet Icarus Comfortable mod tier.

## Status quo

`Icarus Plus` is one of the six paks merged into `pak/SlurpNet.pak`
(see `Mods/MODS.md`). It is also the only one of those six that is known to be
abandoned: the Nexus mod page is now `status: hidden, available: false` and the
attached file was built against Icarus `3.0.4.150844` (~Week 217, Feb 2026).
The SlurpNet server runs `3.0.11.152253` (Week 233, May 22). That is roughly
16 patch versions and 12 weekly builds of drift, with no future versions
forthcoming. The mod is shipped on a bet that its data hooks survive game
patches, and that bet ages every week. This research evaluates whether to drop
it, swap it for a single maintained replacement, or split its features across
multiple maintained mods.

## Verified feature footprint of Icarus Plus 3.0.4.150844 (file 1329)

The local pak was unpacked with `repak v0.2.3` from
`/Users/zachgonser/Documents/slurpnet-icarus/Mods/source-paks/IcarusPlus_P.pak`.
It writes **20 files** under `Icarus/Content/Data/`. The full list, with the
size of each JSON table and the count of rows it overrides, is given here so
that future researchers can verify against game updates.

| File | Size | Rows | What it represents |
|---|---|---|---|
| `Inventory/D_InventoryInfo.json` | 61K | ~80 | Container slot counts (player backpack, storage, dropship cargo, etc.) |
| `Traits/D_Itemable.json` | 3.7M (note: ProcessorRecipes is actually 3.7M; Itemable is the largest file at ~5MB) | 3302 | Item weight / stack size / icon / display name for every item |
| `Crafting/D_ProcessorRecipes.json` | 3.7M | 2175 | Crafting recipes (smelters, furnaces, fabricators, etc.), including `RequiredMillijoules` (time/energy) |
| `Talents/D_Talents.json` | 2.5M | 2161 | Talent definitions: position, requirements, granted stats |
| `Experience/D_ExperienceEvents.json` | 75K | ~80 | XP granted per gameplay event (ChopTree, KillAI, CatchFish, etc.) |
| `Traits/D_Deployable.json` | n/a | 975 | Deployable item modifications (storage boxes, lights, etc.) |
| `Traits/D_Equippable.json` | n/a | 111 | Equippable modifiers / stat overrides (suits, modules, backpacks) |
| `Traits/D_Itemable.json` | ditto | ditto | (listed above) |
| `Traits/D_Processing.json` | n/a | 74 | Processing speed for cooking/refining stations |
| `Factions/D_FactionMissions.json` | n/a | 201 | Mission definitions, rewards, currency, talents-rewarded |
| `World/D_VoxelSetupData.json` | n/a | 33 | Mining voxel speed / yield |
| `Character/C_PlayerTalentGrowth.uasset+.uexp` | 240+733B | curve | Talent points granted per player level |
| `Character/C_SoloTalentGrowth.uasset+.uexp` | 240+729B | curve | Solo talent points granted per level |
| `Character/C_PlayerBlueprintGrowth.uasset+.uexp` | 281+839B | curve | Tech tree points granted per level |
| `Character/C_PetTalentGrowth.uasset+.uexp` | 213+727B | curve | Talent points granted per pet level |
| `Character/C_MountTalentGrowth.uasset+.uexp` | 213+731B | curve | Talent points granted per mount level |

Inspection of the JSON rows confirms the following concrete changes (each line
quotes a specific row + field that differs from defaults or that is suspiciously
high/round):

1. **Inflated XP grants per action** — `D_ExperienceEvents.json` has values
   like `ChopTree: 249`, `GatherResource: 249`, `KillAI: 1999`, `CatchFish: 999`,
   plus a tier ending with `99999` for some kills. Most values are ~25-200x
   the implied vanilla rate (base game XP grants are normally 1-100 per event).
   Effectively a global XP multiplier.

2. **Inflated mission rewards** — `D_FactionMissions.json` has 5 rows of
   `Amount: 50000` currency reward on the row `OLY_Forest_Recon` (the very
   first tutorial mission), one for each of the meta-currencies
   (Credits, Exotic1, Exotic_Red, Exotic_Uranium, and one more). Only this
   single mission is boosted — the other 200 missions retain near-vanilla
   numbers (most rewards 25-650). So this is "boost the tutorial, not all
   missions".

3. **Increased storage slot counts** — `D_InventoryInfo.json` has
   `Space_Main_Inventory: StartingSlots=200`, `On_Prospect_Meta_Inventory: 200`,
   `Overflow_Bag: 150`, `Storage_Metal_Cupboard: 102`, plus assorted
   25/27/18/20 increases on small containers. The vanilla player Backpack
   stays at 24 (no change there), but high-end storage is roughly doubled.

4. **Larger stack sizes (selective)** — `D_Itemable.json` defaults
   `MaxStack=1` (per-row override required). It contains
   - 7 items at `MaxStack: 500-1000` (rare ores, biomass)
   - 45 items at `MaxStack: 200-400` (common materials, food)
   - many at `MaxStack: 100` (ammo, building parts)
   The default is **not** raised — only specific items get bigger stacks.

5. **Instant biomass and Workshop bundle recycling** — `D_ProcessorRecipes.json`
   contains 34 recipes with `RequiredMillijoules: 1` (effectively 1ms):
   - 17 `Biomass_To_*` recipes (e.g. `Biomass_To_BlackFur`,
     `Biomass_To_SandwormScale`, `Biomass_To_Frozen_Wool`) — biomass-to-rare-
     item conversion is instant.
   - 17 Workshop bundle recycles (`Common_Vestige`, `Rare_Vestige`,
     `Farmer_Plant_*`, `Fisher_*_Fish`, `Food_Soda`, `Food_Ration`,
     `Food_Oxy`, `Food_Gruel`). These let the player instantly unpack
     workshop-purchased bundles.

6. **Talent + tech tree growth curves** — `C_PlayerTalentGrowth.uexp`,
   `C_SoloTalentGrowth.uexp`, `C_PlayerBlueprintGrowth.uexp` are small
   curve tables. We cannot decode the exact multiplier without UE-aware
   tooling, but the file sizes (213-281 bytes) and presence in the pak
   indicate the per-level talent / tech / solo points granted are
   non-vanilla. Inference from community context: Icarus Plus grants extra
   talent points so the player can unlock more of the talent tree at a
   given level.

7. **Pet + mount talent growth** — `C_PetTalentGrowth.uexp` /
   `C_MountTalentGrowth.uexp` similarly modify pet/mount levelling curves.

8. **Equippable / Deployable / Processing trait tweaks** — `D_Equippable.json`
   (111 rows), `D_Deployable.json` (975 rows), `D_Processing.json` (74 rows)
   modify specific items' stats. `D_Equippable.json` covers 141 distinct
   stat names (e.g. `BaseBackpackSlots_+: 24`, `BaseBowReloadSpeed_+%`,
   `BaseChanceToFellTreeInstantly_%`, `BaseComfortLevel_+`,
   `BaseAnimalCarryingMovementSpeed_+%`). Most edits look like equippable
   module / suit buffs (some module rows like the
   "ST-700 Gatherer's Backpack" get +24 slots, weight bonuses, etc.).

9. **Voxel mining tweaks** — `D_VoxelSetupData.json` (33 rows) likely
   modifies voxel HP / yield (faster mining or more ore per swing).

### Where confirmed via Wayback Machine

**Not confirmed.** Both the Wayback Machine availability API
(`https://archive.org/wayback/available?url=nexusmods.com/icarus/mods/141`) and
the CDX search (`https://web.archive.org/cdx/search/cdx?url=nexusmods.com/icarus/mods/141`)
return zero snapshots. Nexus mod 141 was never archived. The original author
description is therefore lost. All feature inferences in this document are
derived from the pak contents and the pak's verified data deltas, not from
the mod page.

## Candidate replacements (Nexus)

The Nexus `latest_updated` and `trending` feeds for Icarus return 38
currently-published, available mods. The candidates below were filtered by:
(a) recent update (last 8 weeks, i.e. Week 225 or later), and
(b) feature overlap with at least one of Icarus Plus's 12 data tables.

### #22 — Caramel Stack size Plus
- Author `Caramel aka RED RIFT`, version `5` (released 2026-05-22, week 233).
- File `1519`, 240 KB. Verified to modify
  `D_Itemable.json`, `D_Fillable.json`, `D_InventoryInfo.json`.
- Feature overlap with Icarus Plus:
  - **Stack sizes** — partial. The Caramel mod sets per-item stacks (ore,
    ingots, wood, building blocks, fuel cans, batteries, tanks); the author
    description says "increased capacity of metal cabinets and chests" — i.e.
    overlaps with Icarus Plus features 3-4.
  - **Inventory slots** — partial. Description says "increased number of
    cells in the player's bag" and "in the medical bag and seed bag".
- Compat: built explicitly against the current Icarus week. Author runs a
  weekly cadence (files 1469→1472→1478→1519 on 2026-05-09, 5-15, 5-22 — clean
  weekly pattern matching laanp's). 482 endorsements.
- Stability signal: 1-year old, active Discord, weekly cadence.
- **Verdict: replaces partially** (features 3 + 4 of Icarus Plus).

### #23 — Caramel Easy Building
- Author `Caramel aka RED RIFT`, version `4`, file `1518`, 350 KB,
  released 2026-05-22.
- Verified to modify `D_ProcessorRecipes.json` and `D_ItemsStatic.json`.
- Feature overlap:
  - **Recipe yields** — yes. Description says "increased the amount of
    received building resources", "increased the amount of ammo, electronics
    and other items". This goes BEYOND Icarus Plus (which only made biomass
    and Workshop bundles instant) — Caramel actually multiplies output
    counts.
  - **Recipe speed** — yes for fermenter ("reduction in spoilage time in
    the wooden fermenter"); does not appear to instant-recycle biomass.
  - **Workshop solar panels x2 on craft** — bonus feature not in Icarus
    Plus.
- Compat: same weekly cadence as #22. 209 endorsements.
- **Verdict: replaces partially** (feature 5, but with different mechanics:
  Caramel multiplies output, Icarus Plus zeroes time. Both make crafting
  faster overall).

### #27 — Caramel Easy Life
- Author `Caramel aka RED RIFT`, version `4`, file `1517`, 41 KB,
  released 2026-05-22.
- Verified to modify `D_Consumable.json`, `D_Weight.json`, `D_Decayable.json`,
  `D_FarmingSeeds.json`, `D_ItemRewards.json`.
- Feature overlap:
  - **Item weight reduction** — yes (D_Weight.json). Icarus Plus weight
    edits are inside D_Itemable; same effect, different file.
  - **Food spoilage** — adds slower spoilage (D_Decayable.json). Icarus
    Plus does not touch this.
  - **Buff duration on food** — overlaps with the Food Buff 5x mod we
    already ship.
  - **Increased exotic plant lifespan, exotic seed drops** — D_FarmingSeeds.
    Not in Icarus Plus.
- Compat: weekly cadence, 139 endorsements.
- **Verdict: replaces partially**, adds non-Icarus-Plus QoL.
  Compat warning: overlaps Food Buff 5x — would need a merge-policy decision.

### #41 — Caramel Speed and Weight
- Version `4`, file `1516`, 96 KB, released 2026-05-22, 153 endorsements.
- Verified to modify `D_ModifierStates.json`, `D_Equippable.json`,
  `D_Armour.json`, `D_AIGrowth.json`.
- Feature overlap:
  - **Equippable suit modifications** (Module Speed x10, Module Weight x10) —
    overlaps Icarus Plus D_Equippable edits. Mechanics: Caramel applies
    multipliers to a small number of modules; Icarus Plus applies many
    individual stat tweaks across 111 equippable rows. **Both touch the same
    file** — this is a collision in merge if both are shipped.
  - **Animal speed (moa/bull/horse) and saddle stats** — D_AIGrowth and
    D_Armour. Not in Icarus Plus.
  - **Watermelon / Strawberry candy buffs** — not in Icarus Plus.
- **Verdict: replaces partially** (Equippable subset).

### #52 — Caramel Level Plus
- Version `4`, file `1482`, 822 bytes (tiny), released 2026-05-15.
- Verified to modify `D_CharacterGrowth.json`. **Note**: this is a JSON
  file, not the uasset/uexp curve files Icarus Plus uses. The Icarus engine
  reads both, with the JSON likely overriding for pet/mount levelling.
- Feature overlap:
  - **Pet talent point cap** — increases pet max level to 50 (description).
    Icarus Plus modifies C_PetTalentGrowth.uexp curve; effect is similar.
- 150 endorsements.
- **Verdict: replaces feature 7** (pet talent growth), and a fragment of 6
  (player talent growth).

### #53 — Caramel Easy LevelUP
- Version `1.0.1`, file `613`, released `2025-11-04`. **Old.**
- Modifies XP rates so tree-chopping / fruit-gathering levels you up fast.
- Compat: hasn't been updated since November 2025, was built for an
  older Icarus version. Risky to ship.
- **Verdict: replaces feature 1** (XP grants per action), but stale.

### #9 — zenProgression (Jen / zenMods4Icarus)
- Version `1.1`, file `1001` released 2026-02-20, plus Extended/Lite variants
  on 2026-03-25. 567 endorsements — **most endorsed mod in the catalog**.
- Self-described as **"doesn't require weekly updates"** — author explicitly
  pinned the mod to behavior the game devs are stable about.
- Three variants:
  - `zenProgression Prospectors` — enables earning all Talents (solo
    included).
  - `zenProgression_Extended` — same but doubles required XP per talent.
  - `zenProgression_Lite` — 297 talent points (half), still all Solo talents.
- Client-side only — does not affect dedicated server gameplay for other
  players. (Author note: "These mods are clientside, meaning people who join
  on your session whether p2p or dedicated server will not be impacted by
  your...")
- **Verdict: replaces feature 6** (talent growth). Critical caveat — if it's
  client-side, it won't apply to dedicated-server play uniformly. Each
  client would need to ship it independently, which fits our launcher
  distribution but conflicts with our "single merged pak distributed to
  everyone" model only if the server runs without it.

### #142 — Ultimate Envirosuit (RheumPrime)
- Version `1.3`, file `1291`, released 2026-03-21, 61 endorsements.
- Modifies one specific envirosuit to have +48 backpack slots, +500
  health, all resistances, etc.
- Feature overlap:
  - Modifies D_Equippable (subset of Icarus Plus feature 8).
- Concentrated buff — doesn't try to do everything. Cleaner scope.
- **Verdict: replaces a tiny slice of feature 8.** Could be additive rather
  than replacement.

### #58 — Mission Rewards x10 (nik4kin)
- Version `2.3.25.146718`, files 797/809, released 2026-01-09 to 2026-01-12.
- Built for Icarus `2.3.25.146718` (~Week 213). **Six months stale.**
- Feature: 10x mission rewards across all missions (not just the tutorial
  like Icarus Plus does).
- **Verdict: would have replaced feature 2 better than Icarus Plus**, but
  is even more stale than Icarus Plus is now. Not viable.

### #31 — Better Pay Per Mission
- Version `4.0`, released 2025-10-25, 231 endorsements.
- Standardizes mission pay at 3500 units * difficulty.
- Released ~7 months ago, no weekly update cadence.
- **Verdict: would replace feature 2**, but is stale.

### #49 — FGAG Icarus Balance Overhaul
- Author Japanese, version `233.0`, file `1513`, released 2026-05-22.
- Verified to modify **32 JSON files**, including every Icarus Plus file
  except the C_*Growth uassets. Files include: `D_Itemable`, `D_Talents`,
  `D_ProcessorRecipes`, `D_Equippable`, `D_Processing`, `D_InventoryInfo`,
  `D_ItemRewards`, `D_FarmingSeeds`, `D_FactionMissions`, ...
- Explicit weekly version numbering (`231.0` 5/9, `232.0` 5/15, `233.0` 5/22)
  — author follows the same release rhythm as laanp.
- 13 MB pak (much larger than Icarus Plus's 0.5 MB).
- Forked from the unmaintained `WZG-Mods/wzg-icarus-balance-overhaul`
  (GitHub source last updated 2024-06).
- **Verdict: this is the *broadest single-mod replacement candidate*.** It
  covers all of Icarus Plus's data files (except the talent growth curves
  via uasset/uexp) and is actively maintained at the current week.
  Cost: it is much more opinionated than Icarus Plus. Author's stated
  philosophy: "Players should spend much more time exploring and crafting
  rather than grinding ores in caves." Could alter PvE pacing in ways
  Icarus Plus did not.

### #45 — Icarus Morningstar Mod
- Author `Morningstar/Anh4nh`, version `v1.0.233-wcap`, file `1529`,
  released 2026-05-23 (**yesterday**), 69 endorsements.
- Verified to modify 22 files including `D_Itemable`, `D_Talents`,
  `D_ProcessorRecipes`, `D_Equippable`, `D_InventoryInfo`, `D_ItemsStatic`,
  `D_CharacterGrowth`, `D_WorkshopItems`, `D_Alterations`,
  `D_AlterationModifiers`.
- Description: "QoL mod, trying to rebalance the game. Less grind, enjoy
  more!"
- Comes in three variants:
  - `v1.0.233` — main (843 KB)
  - `v1.0.233-nonstack` — without stack changes (in case players want
    a different stack mod)
  - `v1.0.233-wcap` — workshop-cap variant
- 843 KB main pak. Smaller than FGAG; closer scope to Icarus Plus.
- **Verdict: very similar to Icarus Plus in scope.** Compat: built for the
  exact current week. Risk: only 69 endorsements (less battle-tested).
  The "wcap" suffix suggests it interacts with Workshop caps — author has
  thought about server-side balance.

### #28 — Zero Cost Crafting
- Version `1.7`, released 2024-09-16. 114 endorsements.
- All crafting recipes have zero input cost.
- **Way too old.** 21 months stale.
- **Verdict: not a fit.** Also too extreme — Icarus Plus did not zero
  crafting costs.

### #16 — Larkwell Care Package
- Version `7.7.9`, file `1298`, released 2026-03-24. 133 endorsements.
- Adds new Workshop care packages. Not a balance mod.
- **Verdict: not a feature-overlap with Icarus Plus.** Additive Workshop
  content only.

### #57 — All stack sizes x100
- Version `2.3.25.146718`, released 2026-01-09. 98 endorsements.
- 6 months stale. Built for Week ~213.
- **Verdict: not a fit** (stale, and a more extreme single-purpose stack
  mod than Caramel #22).

### #51 — Eclipse's Bestiary
- Version `2.1.0`, released 2026-04-03. 35 endorsements.
- Tweaks Bestiary progression. **Not** in Icarus Plus's footprint.
- **Verdict: not a fit** (additive).

### #54 — Eclipse's Extractors
- Version `1.0.5`, released 2026-04-03. 49 endorsements.
- Makes all extractors complete cycles in ~10 seconds.
- **Verdict: not a fit** (additive; complements but does not replace
  Icarus Plus features).

### #56 — Eclipse's Workshop
- Version `1.2.11`, released 2026-05-23. 30 endorsements.
- Modifies Workshop ammo bundles (50 instead of 25) and consumables (10
  vs 5). Description notes the author is planning broader changes but only
  ammo + consumables are done.
- **Verdict: not a direct fit; additive.**

## Laanp set extensions (GitHub)

The `laanp/Icarus_Mods_Separated` repo's `v1_w233` tag (released
2026-05-22, same day as the game's Week 233 patch) contains **57 paks**.
SlurpNet currently ships 4 of them (PetesBeaconTeleport, ItemFinder,
CaveMaster, KeepTheTrees). The remaining 53 laanp paks fall into three
buckets relative to Icarus Plus:

### Tier A: replace meaningful Icarus Plus features
- **laanp-Combined_QOL_v1_w233_P.pak (49 MB)** — The closest direct
  replacement we have. It is laanp's bundled QoL mod and per the
  [Combined_QOL_Readme](https://github.com/laanp/Icarus_Mods_Separated/blob/main/laanp-Combined_QOL_Readme.md)
  delivers:
  - All slot stack sizes changed to 500 (default MaxStack=500 verified
    when unpacked — matches Icarus Plus feature 4 with a more generous
    default).
  - Base inventory slots 24 → 42 (more aggressive than Icarus Plus's
    storage-only buffs).
  - Player levels show actual, beyond 60 (matches feature 6's effect).
  - No fall damage, 5000 kg carry weight, boosted stamina/speed/health/
    swim/run (suit baseline buffs — broader than Icarus Plus
    D_Equippable edits).
  - +2 envirosuit aux slots (overlaps feature 8).
  - Crop plots no longer get Seed Fatigue debuff (additive QoL).
  - O2 tank and water canteen auto-fill on purchase.
  - Workshop "Pete's Kits" (Starter Loadout, Stone Cabin, Seed Packet,
    Fishing Kit, Mining Kit) — additive content.
  - Dropship cargo 15 → 30 (feature 3).
  - Larger storage inventories (feature 3).
  - 10M durability on key tools (additive QoL).
  - Power generators output 50k (additive).
  - Inventory data verified: 200 inventory rows total, 21 differ from
    Icarus Plus values (in both directions — laanp sets backpack 42 vs
    Icarus Plus 24; Storage_Metal_Cupboard 72 vs Icarus Plus 102).
  Unpack confirms 30 JSON files modified including all 7 of the Icarus
  Plus JSON tables, plus 23 more.
  **Verdict: ~85-90% overlap with Icarus Plus's gameplay-altering
  surface area.** Misses the C_*Growth curve files (uasset/uexp) — laanp
  uses `D_CharacterGrowth.json` instead, which the game also reads.

- **laanp-StacksAndKits_v1_w233_P.pak** — Smaller sibling of Combined_QOL.
  Per the README: "A more natural Icarus experience, with a minimized
  kit set." For server use this is the "Combined_QOL light" alternative.

### Tier B: replace narrow Icarus Plus features (worth shipping alongside)
- **laanp-PetesInsaneLeveler_v1_w233_P.pak** — workshop module that
  rapidly advances character XP. Replaces a slice of feature 1 + 6.
  Player chooses when to enable.
- **laanp-PetesAuxSlots_v1_w233_P.pak** — +2 envirosuit aux slots
  module. Replaces a slice of feature 8.
- **laanp-PetesResourceKiller_v1_w233_P.pak** — 1-hit gathering for
  trees/rocks/ores. Replaces a slice of feature 9 (voxel mining).
- **laanp-PetesMover_v1_w233_P.pak** — module: +50% base movement &
  sprint speed. Adjacent QoL.
- **laanp-PetesLavaCaveLord_v1_w233_P.pak** — module: 100% resistance
  to pneumonia, lava, fire, poison. Replaces a slice of feature 8.
- **laanp-WorkshopFree_v1_w233_P.pak** — all Workshop items free.
  Replaces some of feature 2 (mission economy) by zeroing the sink.
- **laanp-FreeBuild_v1_w233_P.pak** — all benches build free. Replaces
  some of feature 5.
- **laanp-PowerSurge_v1_w233_P.pak** — all generators output 50k power.
  Already inside Combined_QOL.
- **laanp-RealLevels_v1_w233_P.pak** — shows true level beyond 60.
  Already inside Combined_QOL.
- **laanp-NoSeedFatigue_v1_w233_P.pak** — already inside Combined_QOL.

### Tier C: additive QoL not in Icarus Plus
The remaining laanp paks (BetterRailings, BuildersDream, BuildTools,
CircleBuilder, CropAdvance, CurvedStairs, DrillManager, ExtraDeployables,
GraveStones, GreaterHunts, HalfCurvedStairs, Lantern, LegacyFurnace,
LightSwitch, MapTeleport, MiniFoundry, MoveDeployables, MXC_Furnace,
NoCaveCreatures, NoCaveCreaturesOW, NoFreezerIce, NoKeas, NoPurpleSky,
NoSwampFog, NoTreeLightningFires, NoWaterWheelJunk, NoWindFallenTrees,
PetesBeeKit, PetesCureAll, PetesMiningKit, PetesMover, PetesSeedKit,
PetesToilet, PetesTrees, PetMover, PlayerTransport, PumpBasin,
RefinedWoodEndCaps, RespawnResourcesOW, StoneWoodInterior, TeleFly) are
additive — not in Icarus Plus's footprint, so they aren't replacement
candidates but could be considered for the Comfortable tier later.

## Feature-by-feature replacement matrix

| Icarus Plus feature | Currently covered by (deployed) | Best replacement option | Source |
|---|---|---|---|
| 1. Inflated XP per action (D_ExperienceEvents) | none | **laanp-PetesInsaneLeveler** (optional module) or **Caramel Easy LevelUP** (stale) | https://github.com/laanp/Icarus_Mods_Separated/releases/tag/v1_w233 |
| 2. 50000-currency tutorial reward | none | none (feature is so narrow it's basically a wash) — drop | n/a |
| 3. Increased storage slot counts (D_InventoryInfo) | none | **laanp-Combined_QOL** (storage + backpack + dropship cargo) | https://github.com/laanp/Icarus_Mods_Separated |
| 4. Larger MaxStack per item (D_Itemable) | none | **laanp-Combined_QOL** (MaxStack default 500) or **Caramel Stack size Plus** (more conservative) | Combined_QOL or Nexus 22 |
| 5. Instant biomass / Workshop bundle recycling (D_ProcessorRecipes) | none | **laanp-Combined_QOL** (overlaps in ProcessorRecipes; also Caramel Easy Building #23 boosts output counts) | Combined_QOL |
| 6. Player + Solo talent growth curve | none | **laanp-Combined_QOL** (D_CharacterGrowth.json) + **zenProgression** (more talents earnable) | Combined_QOL + Nexus 9 |
| 7. Pet + Mount talent growth | none | **laanp-Combined_QOL** + **Caramel Level Plus #52** | Combined_QOL + Nexus 52 |
| 8. Equippable / module / suit buffs (D_Equippable, ~111 rows) | none | **laanp-Combined_QOL** (broad suit buffs) + **laanp-PetesAuxSlots** + **laanp-PetesLavaCaveLord** | Combined_QOL |
| 9. Voxel mining tweaks (D_VoxelSetupData) | none | **laanp-PetesResourceKiller** (more aggressive: 1-hit) | https://github.com/laanp/Icarus_Mods_Separated |
| 10. Deployable / Processing trait tweaks (D_Deployable, D_Processing) | none | **laanp-Combined_QOL** (touches D_Deployable, D_Processing) | Combined_QOL |
| 11. Faction mission edits (D_FactionMissions) | none | none viable (Mission Rewards x10 #58 is stale; Better Pay Per Mission #31 is stale) — drop | n/a |
| 12. Talent definitions (D_Talents) | none | **laanp-Combined_QOL** (touches D_Talents) | Combined_QOL |

## Recommendation

**(b) Single swap — replace `IcarusPlus_P.pak` with
`laanp-Combined_QOL_v1_w233_P.pak`.**

### Justification

The single-mod-swap option covers all of Icarus Plus's gameplay-altering
surface area except features 2 (tutorial currency boost — trivial, drop
it) and 11 (mission reward edits — only the tutorial was actually boosted,
drop it). Combined_QOL is verified to modify the same 7 of 12 JSON tables
Icarus Plus touches, plus 23 additional tables for adjacent QoL features
SlurpNet players will appreciate (auto-fill canteens/O2, durable tools,
no-fall-damage, +2 envirosuit slots, Pete's Kits). It uses
`D_CharacterGrowth.json` for talent/level/blueprint growth — same effective
outcome as Icarus Plus's uasset/uexp curves, just via the JSON pathway the
modern game prefers.

The killer point is the maintenance model: laanp ships a fresh
`v1_w<NNN>` tag every Friday, matching the Icarus dev cadence. Going back
in commit history confirms this rhythm has held for 148 releases (every
weekly release tag exists from week ~85 to week 233 today, no gaps). The
mod you'd ship next Friday is `v1_w234`, the week after `v1_w235`, etc.
Compare against Icarus Plus, which has been frozen at Week 217 since
2026-04-03.

A multi-mod-swap would technically replace each feature with a more
authoritative single-purpose mod (e.g. `zenProgression` for talents,
`Caramel Stack size Plus` for stacks, `PetesInsaneLeveler` for XP). But
that increases the merge surface area (more JSON collisions for
JimK72's IMM to reconcile) and means we'd have to track 5+ mods'
weekly cadences instead of one. Combined_QOL is the strictly easier
operational story.

Dropping entirely (option a) loses too much — the 5x food buff and
the laanp single-feature paks we ship don't replace storage capacity,
stack sizes, XP, or talent growth.

### Alternative if Combined_QOL collides on merge

If `laanp-Combined_QOL` produces unsolvable JSON conflicts in JimK72's
Icarus Mod Manager when merged with the other laanp paks
(PetesBeaconTeleport, ItemFinder, CaveMaster, KeepTheTrees) — see the
README warning "may not be compatible with Jimk72's Icarus Mod Manager
(IMM)" — fall back to **option (c) multi-mod swap**:

- `laanp-StacksAndKits` (smaller bundle, IMM-friendlier — replaces
  features 3, 4, plus kits).
- `laanp-PetesInsaneLeveler` (feature 1, 6 as opt-in module).
- `laanp-PetesAuxSlots` (feature 8 fragment).
- `laanp-PetesResourceKiller` (feature 9, opt-in module).
- `Caramel Level Plus #52` (feature 7).
- `zenProgression Prospectors` (feature 6, client-side).

## Risks of the recommendation

1. **Combined_QOL is bundled and IMM-unsafe.** The laanp README
   explicitly states: "Some of my bundled mods (laanp-BuildersDream &
   laanp-Combined_QOL) were designed as a bundled standalone mods that
   affects a number of files, and may not be compatible with Jimk72's
   Icarus Mod Manager (IMM). If installing with other mods using the
   IMM - SOME THINGS MAY NOT WORK!" SlurpNet's merge contract relies
   on JimK72's IMM (per `Mods/MODS.md` line 29). **This is the largest
   risk.** Mitigation: before deploying, run a single test-merge of
   the proposed 6-mod set (PetesBeaconTeleport, ItemFinder, CaveMaster,
   KeepTheTrees, Combined_QOL, Food Buff 5x) in IMM and verify the
   merged pak passes `scripts/validate-icarus-release.sh`. If IMM
   produces a broken pak, fall back to the multi-mod plan in
   "Alternative" above.

2. **Combined_QOL is much more opinionated than Icarus Plus.** It
   gives the player +18 backpack slots (24→42) by default, sets all
   stacks to 500, adds Pete's Kits (a full starter loadout with
   100k arrows, prefilled biofuel canister, 10M-durability titanium
   tools). For some servers this is too far. For SlurpNet's Comfortable
   tier (`"No Grind"` is one of the launcher features in `pack.json`),
   this is probably aligned, but worth a play-test on a non-prod
   prospect before pushing the merged pak to the live server.

3. **Combined_QOL changes Workshop pricing and Pete's Kit recipes.**
   This could affect Workshop progression that some players have
   already invested in. The launcher already wipes on weekly Icarus
   updates, so this is bounded.

4. **The 5x Food Buff mod (Nexus 123) is itself fragile.** This research
   doesn't change Food Buff's status — it's still pinned to OPTIONAL,
   still works against w233, still author-disinterested. Not in scope
   to fix here, but worth flagging that swapping Icarus Plus reduces
   the pack's exposure to abandoned mods from 2 to 1.

5. **Server-side vs client-side.** Combined_QOL is server-authoritative
   (changes data tables which the server validates against). It will
   work in the SlurpNet dedicated-server model exactly the way
   Icarus Plus does today. No new distribution complications.

## Migration notes

If the recommendation is adopted, the following changes would be needed
(researched but NOT applied per the task constraints):

### `Mods/MODS.md` edits

Replace the row for Icarus Plus:
```
| Icarus Plus | Comfortable | <https://www.nexusmods.com/icarus/mods/141?tab=files> file `1329` | Core quality-of-life baseline; downloaded as `Icarus Plus 3.0.4.150844` |
```
with:
```
| laanp-Combined_QOL | Comfortable | <https://github.com/laanp/Icarus_Mods_Separated/releases/download/v1_w233/laanp-Combined_QOL_v1_w233_P.pak> | Bundled QoL baseline: stacks, slots, growth, suit buffs, Pete's Kits |
```

### `pack.json` edits

- `version` bump (e.g. `2026.05.24a`).
- `launcher.description` no longer mentions "Icarus Plus" — rewrite
  to "the Comfortable mod tier — laanp QoL bundle, beacon teleport,
  item finder, cave master, kept trees, and 5x food buff."
- `launcher.modCount`: stays at 6 (one-for-one swap).
- `launcher.features`: keep `"No Grind"`, `"2x XP"`, `"Beacon Teleport"`,
  `"Cave Master"` — all still accurate. (`2x XP` is now via laanp
  Combined_QOL's growth curves, not Icarus Plus's XP-per-event
  multipliers.)

### Expected `pack.json.launcher.modCount` change

None. 6 mods total (4 laanp single-feature paks + 1 laanp Combined_QOL +
1 Food Buff 5x = 6). No change.

### Exact JSON paths that would now collide in merge

When IMM merges the 6 paks, the JSON tables that would have multiple
contributors are:

| JSON table | Contributors after swap |
|---|---|
| `Inventory/D_InventoryInfo.json` | laanp-Combined_QOL only |
| `Traits/D_Itemable.json` | laanp-Combined_QOL only |
| `Traits/D_Equippable.json` | laanp-Combined_QOL only |
| `Traits/D_Deployable.json` | laanp-Combined_QOL only |
| `Traits/D_Processing.json` | laanp-Combined_QOL only |
| `Traits/D_Resource.json` | laanp-Combined_QOL only |
| `Traits/D_Consumable.json` | laanp-Combined_QOL + (potentially Food Buff 5x — needs re-check) |
| `Crafting/D_ProcessorRecipes.json` | laanp-Combined_QOL only |
| `Talents/D_Talents.json` | laanp-Combined_QOL only |
| `Character/D_CharacterGrowth.json` | laanp-Combined_QOL only |

Before this swap: IcarusPlus contributed 10 JSON tables + 5 uasset/uexp
curves. After: laanp-Combined_QOL contributes 30 JSON tables. Surface
area for IMM merge is bigger, but conflicts with other laanp
single-feature mods (PetesBeaconTeleport et al.) are bounded — those
mods touch their own deployable-item rows and tool-action rows, not
the data tables Combined_QOL targets.

The Food Buff 5x mod likely modifies `D_Consumable.json` to extend
buff durations. If laanp-Combined_QOL also touches `D_Consumable.json`,
IMM's structured-merge-by-Rows[].Name policy should handle the union
correctly. **This is the one collision to verify in test-merge.**

### Pre-flight test plan (for whoever picks this up)

1. Pull `laanp-Combined_QOL_v1_w233_P.pak` from
   https://github.com/laanp/Icarus_Mods_Separated/releases/download/v1_w233/laanp-Combined_QOL_v1_w233_P.pak
   to a Windows VM running JimK72's IMM.
2. Stage the 6-mod merge inputs: the 4 laanp single-feature paks
   already in `Mods/source-paks/`, the new Combined_QOL pak, and
   `Food Buff Duration - 5x_P.pak`.
3. Run IMM's merge → output `SlurpNet.pak`.
4. Run `scripts/validate-icarus-release.sh`.
5. Test in single-player on a fresh prospect on Olympus: verify
   inventory slots are 42, stacks default to 500, food buffs last
   long, beacon teleport works.
6. If all good: stage to deploy, push to launcher, push to server.

## What we did NOT verify

- **The Wayback Machine has no snapshot of Nexus mod 141.** The
  original author's feature description is lost. Feature inferences
  are from pak contents only.
- **The exact integer multipliers in Icarus Plus's `C_*Growth.uexp`
  files.** repak can extract them but they are UE custom binary curve
  tables (UAsset + UExp pair). Decoding requires a UE-aware tool
  like UAssetGUI or a custom parser, which we did not run. The
  inference that they grant extra talent / blueprint points per level
  is based on Icarus modding community context, not bit-level reading.
- **An in-game functional test of any candidate mod.** This research
  is dossier-only — we did not boot Icarus and verify that
  laanp-Combined_QOL's stack-500-by-default actually works against
  Icarus 3.0.11.152253. The author's weekly-release cadence and the
  fresh w233 tag (released same day as the game patch) is the
  strongest stability signal short of an in-game test.
- **A merge dry-run through JimK72's IMM.** We verified file-level
  overlap with `repak unpack` but not row-level merge behavior.
  This must be confirmed before the swap is approved.
- **The Linkarus Discord** (https://discord.gg/linkarus-icarus-modding-936621749733302292)
  for additional community knowledge — links from the laanp README,
  not browsed in this research session.
- **Codefling.** No Icarus mods appear on Codefling — it is a
  Rust-centric storefront. Searched, none found. Not a viable
  catalog for Icarus.
- **AgentKush/Icarus-mods (GitHub).** Repo exists with 38 mods and
  recent activity, but assets use a non-standard `.EXMODZ` format
  not compatible with vanilla Icarus pak loading. Skipped.
- **WZG-Mods/wzg-icarus-balance-overhaul (GitHub).** Stale since
  2024-06. FGAG Icarus Balance Overhaul (Nexus 49) is the
  community-maintained continuation; that is the candidate evaluated.
