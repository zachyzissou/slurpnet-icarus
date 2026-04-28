#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import os
import shutil
import zipfile
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PACK_PATH = ROOT / "pack.json"
PAK_PATH = ROOT / "pak" / "SlurpNet.pak"
DEFAULT_DOWNLOADS_DIR = Path("/mnt/cache/appdata/7dtd-downloads")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_pack() -> dict:
    return json.loads(PACK_PATH.read_text(encoding="utf-8"))


def build_entry(pack: dict, zip_size: int, private: bool) -> dict:
    launcher = dict(pack["launcher"])
    entry = {
        "serverId": pack["serverId"],
        "game": pack["game"],
        "name": launcher["name"],
        "description": launcher["description"],
        "modCount": launcher["modCount"],
        "worldName": launcher["worldName"],
        "maxPlayers": launcher["maxPlayers"],
        "features": launcher["features"],
        "steamAppId": launcher["steamAppId"],
        "connectInstructions": launcher["connectInstructions"],
        "serverPort": launcher["serverPort"],
        "queryPort": launcher["queryPort"],
        "sourceRepository": launcher["sourceRepository"],
        "modpack": {
            "version": pack["version"],
            "size": zip_size,
        },
    }
    if private:
        entry.update(
            {
                "password": os.environ.get("SLURPNET_LAUNCHER_PASSWORD", ""),
                "launchArgs": launcher.get("launchArgs", []),
                "steamInstallDir": launcher["steamInstallDir"],
                "serverSideOnly": launcher["serverSideOnly"],
            }
        )
        entry["modpack"].update(
            {
                "url": pack["liveZipUrl"],
                "manifestUrl": pack["liveManifestUrl"],
            }
        )
    return entry


def merge_feed(feed_path: Path, entry: dict) -> bool:
    if not feed_path.exists():
        print(f"Skipping missing launcher feed: {feed_path}")
        return False
    data = json.loads(feed_path.read_text(encoding="utf-8"))
    servers = data.setdefault("servers", [])
    for index, server in enumerate(servers):
        if server.get("serverId") == entry["serverId"] or server.get("game") == entry["game"]:
            servers[index] = entry
            break
    else:
        servers.append(entry)
    tmp = feed_path.with_suffix(feed_path.suffix + ".tmp")
    tmp.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    tmp.replace(feed_path)
    feed_path.chmod(0o644)
    return True


def main() -> int:
    pack = load_pack()
    if not PAK_PATH.is_file():
        raise SystemExit("ERROR: pak/SlurpNet.pak missing. Run scripts/merge-pak.sh first.")

    downloads_dir = Path(os.environ.get("ICARUS_DOWNLOADS_DIR", DEFAULT_DOWNLOADS_DIR))
    artifact_dir = downloads_dir / pack["artifactRoot"]
    blob_dir = downloads_dir / "blobs" / pack["blobPrefix"]
    artifact_dir.mkdir(parents=True, exist_ok=True)
    blob_dir.mkdir(parents=True, exist_ok=True)

    zip_path = artifact_dir / pack["zipName"]
    manifest_path = artifact_dir / pack["manifestName"]
    tmp_zip = zip_path.with_suffix(zip_path.suffix + ".tmp")
    tmp_manifest = manifest_path.with_suffix(manifest_path.suffix + ".tmp")

    digest = sha256_file(PAK_PATH)
    size = PAK_PATH.stat().st_size
    archive_path = pack["clientArchivePath"]

    with zipfile.ZipFile(tmp_zip, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        archive.write(PAK_PATH, archive_path)
    with zipfile.ZipFile(tmp_zip) as archive:
        bad_file = archive.testzip()
        if bad_file:
            raise SystemExit(f"ERROR: built zip failed integrity check at {bad_file}")

    blob_path = blob_dir / digest[:2] / digest
    blob_path.parent.mkdir(parents=True, exist_ok=True)
    if not blob_path.exists():
        shutil.copy2(PAK_PATH, blob_path)
        blob_path.chmod(0o644)

    manifest = {
        "version": pack["version"],
        "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "totalFiles": 1,
        "storage": {
            "type": "content-addressed",
            "baseUrl": f"https://mods.slurpgg.net/blobs/{pack['blobPrefix']}/",
        },
        "deployment": pack["deployment"],
        "files": {
            archive_path: {
                "sha256": digest,
                "size": size,
            }
        },
    }
    tmp_manifest.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    tmp_zip.replace(zip_path)
    tmp_manifest.replace(manifest_path)
    zip_size = zip_path.stat().st_size

    private_entry = build_entry(pack, zip_size, private=True)
    public_entry = build_entry(pack, zip_size, private=False)
    launcher_entry_path = ROOT / "launcher" / "servers-entry.json"
    launcher_entry_path.write_text(json.dumps(private_entry, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    updated = []
    if merge_feed(artifact_dir / "launcher-servers.json", private_entry):
        updated.append("launcher-servers.json")
    if merge_feed(artifact_dir / "servers.json", public_entry):
        updated.append("servers.json")

    feed_note = f" | updated {', '.join(updated)}" if updated else " | no live feeds present"
    print(f"Published {pack['version']} | 1 client file | {zip_size / 1024 / 1024:.2f}MB{feed_note}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
