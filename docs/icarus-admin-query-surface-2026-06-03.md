# Icarus Admin / Query Surface - 2026-06-03

Purpose: resolve the repo-side contract for
`Expose admin/query data for ops-backend collector`.

## Decision

Do not expose a TCP Source RCON port for Icarus production.

RocketWerkz documentation uses the term "RCON" for commands entered through
the in-game chat or command window, authenticated by `AdminPassword`. The
official `ServerSettings.ini` sample contains `AdminPassword`, but does not
contain `RconEnabled`, `RconPort`, or `RconPassword`.

Current ops-backend Icarus state should come from:

- Docker fleet status for the `Icarus` container.
- The existing ops-backend generic log-tail collector for Icarus.
- Steam query registration at `47.186.229.92:20009`, with game port `20008`.
- Launcher feed and manifest metadata under `mods.slurpgg.net/api/`.

## Official Config Evidence

The official RocketWerkz sample config contains only the admin password field:

```ini
[/Script/Icarus.DedicatedServerSettings]
SessionName=
JoinPassword=
MaxPlayers=
AdminPassword=
ShutdownIfNotJoinedFor=300.000000
ShutdownIfEmptyFor=300.000000
AllowNonAdminsToLaunchProspects=True
AllowNonAdminsToDeleteProspects=False
LoadProspect=
CreateProspect=
ResumeProspect=True
LastProspectName=
```

The RocketWerkz server config wiki says `AdminPassword` is the password required
for admin RCON commands, but its command examples are in-game commands such as
`/AdminLogin password12345`, not Source TCP RCON packets.

## TCP Source RCON Preflight

A non-production preflight was run on the Unraid host on 2026-06-03 with a
temporary appdata copy and temporary container `IcarusPreflightRCON`.

Temporary config included:

```ini
RconEnabled=true
RconPort=27037
RconPassword=preflight-rcon-password-not-secret
```

Isolation:

- temporary appdata: `/mnt/cache/appdata/icarus-preflight-rcon-20260603`
- container: `IcarusPreflightRCON`
- local-only game/query ports: `127.0.0.1:20118/udp` and
  `127.0.0.1:20119/udp`
- local-only TCP port: `127.0.0.1:27037/tcp`

Boot evidence:

```text
boot_signal=ok iteration=19
20118/udp -> 127.0.0.1:20118
20119/udp -> 127.0.0.1:20119
27037/tcp -> 127.0.0.1:27037
LogIcarusGameStateRecording: Display: ReadFromProspectSaveState complete
LogIcarusGameModeSurvival: Verbose: NativeRaiseTheCurtain
```

Source RCON auth reset the connection:

```text
rcon_check_failed=[Errno 104] Connection reset by peer
```

Cleanup and production safety:

```text
preflight_exists=0
prod_ports
20008/udp -> 0.0.0.0:20008
20008/udp -> [::]:20008
20009/udp -> 0.0.0.0:20009
20009/udp -> [::]:20009
```

## Live Query Evidence

As of 2026-06-03:

- Docker publishes only `20008/UDP` and `20009/UDP` for production `Icarus`.
- The live pak SHA is
  `832e0d7ba155939424b9be3b174b39da864371e15ba790596f5857bfc77c3378`.
- Public feed row `icarus` advertises `serverPort=20008`, `queryPort=20009`,
  version `2026.06.02a`, and launch args `["-dx12"]`.
- Public manifest `SlurpNet_Icarus_Mods-manifest.json` records the same version
  and pak SHA.
- Steam API lists `47.186.229.92:20009` with `gameport=20008`.

## Closure Rule

Do not add `RCON_PORT`, `RCON_PASSWORD`, `RconEnabled`, `RconPort`, or
`RconPassword` to production deployment unless a future Icarus build documents
and passes a real TCP admin protocol preflight.
