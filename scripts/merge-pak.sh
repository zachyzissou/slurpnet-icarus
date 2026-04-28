#!/usr/bin/env bash
set -euo pipefail

cat <<'MSG'
Icarus mod merge handoff

JimK72's Icarus Mod Manager is GUI-driven in the current SlurpNet workflow.
Use it to merge every source mod under ./Mods into ONE pak:

  ./pak/SlurpNet.pak

Required source mods:
  - Icarus Plus
  - laanp-PetesBeaconTeleport
  - ItemFinder
  - CaveMaster
  - KeepTheTrees
  - Food Buff 5x

After export:
  scripts/validate-icarus-release.sh

Do not deploy separate paks. Server and clients must install the identical
merged SlurpNet.pak.
MSG

