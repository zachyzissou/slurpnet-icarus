# SlurpNet Icarus Agent Notes

This repo manages the SlurpNet Icarus dedicated server scaffold and launcher
pack contract.

Rules:

- Do not commit `.env`, passwords, SSH keys, or generated production config.
- Do not commit `pak/*.pak`.
- Keep `pak/SlurpNet.pak` as the only deployable pak filename.
- Keep the launcher archive path at `Icarus/Content/Paks/mods/SlurpNet.pak`.
- Keep Icarus host-side ports at `20008/UDP` (game) and `20009/UDP` (query);
  the container binds Icarus defaults `17777`/`27015` internally.
- Do not deploy separate Icarus paks. Server and clients require one identical
  merged pak.
- Do not deploy or push without explicit operator approval.
