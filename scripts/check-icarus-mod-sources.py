#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODS_LEDGER = ROOT / "Mods" / "MODS.md"
LICENSE_LEDGER = ROOT / "Mods" / "MOD_LICENSES.md"
LAANP_RELEASE_URL = "https://api.github.com/repos/laanp/Icarus_Mods_Separated/releases/latest"
LAANP_ASSET_NAMES = [
    "laanp-Combined_QOL_{tag}_P.pak",
    "laanp-PetesBeaconTeleport_{tag}_P.pak",
    "laanp-ItemFinder_{tag}_P.pak",
    "laanp-CaveMaster_{tag}_P.pak",
    "laanp-KeepTheTrees_{tag}_P.pak",
]


def fetch_json(url: str) -> dict:
    result = subprocess.run(
        ["curl", "-fsSL", url],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or f"curl failed for {url}")
    return json.loads(result.stdout)


def main() -> int:
    errors: list[str] = []
    mods_text = MODS_LEDGER.read_text(encoding="utf-8")

    release = fetch_json(LAANP_RELEASE_URL)
    tag = release.get("tag_name")
    if not tag:
        errors.append("laanp latest release has no tag_name")
    asset_names = {asset.get("name") for asset in release.get("assets", [])}

    for template in LAANP_ASSET_NAMES:
        asset = template.format(tag=tag)
        url = f"https://github.com/laanp/Icarus_Mods_Separated/releases/download/{tag}/{asset}"
        if asset not in asset_names:
            errors.append(f"latest laanp release {tag} missing required asset {asset}")
        if url not in mods_text:
            errors.append(f"Mods/MODS.md does not reference latest laanp asset: {url}")

    if not LICENSE_LEDGER.is_file():
        errors.append("missing Mods/MOD_LICENSES.md redistribution ledger")

    if LICENSE_LEDGER.is_file():
        license_text = LICENSE_LEDGER.read_text(encoding="utf-8")
        if "operator decision required" in license_text.lower():
            errors.append("Mods/MOD_LICENSES.md contains unresolved operator decision required status")
        if "Food Buff 5x" in mods_text and "Retire from the next approved pack" not in license_text:
            errors.append("Food Buff 5x must remain retired unless explicit permission is recorded")

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print(f"Icarus mod source check passed: laanp latest={tag}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
