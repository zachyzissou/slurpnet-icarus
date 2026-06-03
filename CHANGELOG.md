# Changelog

All notable changes to SlurpNet Icarus are documented here.

## [Unreleased]

### Added

- Initial Icarus dedicated server scaffold for the SlurpNet Unraid stack.
- Comfortable-tier mod ledger and single merged pak contract.
- Launcher feed entry for `SlurpNet Icarus`.
- Combined_QOL non-production preflight artifact with source SHAs, path
  collisions, and candidate pak SHA.
- Icarus admin/query surface proof documenting why TCP Source RCON is not
  exposed and how ops-backend currently derives Icarus status.

### Changed

- Reconciled repo metadata with the live Week 234 merged pak
  (`2026.06.02a`, SHA256 `832e0d7ba155939424b9be3b174b39da864371e15ba790596f5857bfc77c3378`).
- Hardened deploy reconciliation so container recreation is explicit and
  Docker fallback ports stay symmetric at `20008/20009`.
- Made production deploys manual-only.
- Retired Icarus Plus and Food Buff 5x from the next approved public rebuild
  path, with laanp Combined_QOL recorded as the replacement candidate.
