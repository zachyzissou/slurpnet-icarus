# Security Policy

## Reporting a Vulnerability

Do not open a public issue for suspected vulnerabilities or leaked credentials.

**Preferred:** file a private report via GitHub Security Advisories:
<https://github.com/zachyzissou/slurpnet-icarus/security/advisories/new>

**Fallback:** email the repository owner at `zachgonser@gmail.com` with
`[slurpnet-icarus security]` in the subject line.

Please include:

- affected path or feature
- impact summary
- reproduction steps if safe
- whether server credentials, private feed credentials, SSH keys, webhooks, API
  keys, or production-only config may be exposed

## Security-Sensitive Areas

- `.env` on Unraid
- GitHub Actions secrets
- `docker/docker-compose.yml`
- `config/ServerSettings.ini`
- `pak/SlurpNet.pak`
- `.github/workflows/**`
- `scripts/**`

## Secrets

Never commit live passwords, private keys, webhooks, API tokens, or
production-only config.

| Secret | Where it lives | Rotation |
|---|---|---|
| `SERVER_PASSWORD` | Unraid `.env`, GitHub Actions secret | Update `.env`, update GitHub secret, restart `Icarus`, update private launcher feed if needed |
| `ADMIN_PASSWORD` | Unraid `.env`, GitHub Actions secret | Generate a new random value, update `.env`, update GitHub secret, restart `Icarus` |

The checked-in `config/ServerSettings.ini` must keep passwords blank. The live
deploy writes secrets from environment variables at runtime.
