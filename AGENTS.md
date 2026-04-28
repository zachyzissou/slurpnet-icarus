# SlurpNet Icarus Agent Notes

This repo manages the SlurpNet Icarus dedicated server scaffold and launcher
pack contract.

Rules:

- Do not commit `.env`, passwords, SSH keys, or generated production config.
- Do not commit `pak/*.pak`.
- Keep `pak/SlurpNet.pak` as the only deployable pak filename.
- Keep the launcher archive path at `Icarus/Content/Paks/mods/SlurpNet.pak`.
- Keep Icarus default ports remapped to `17787/UDP` and `27017/UDP`.
- Do not deploy separate Icarus paks. Server and clients require one identical
  merged pak.
- Do not deploy or push without explicit operator approval.
