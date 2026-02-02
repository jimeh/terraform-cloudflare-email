# AGENTS.md

Terraform module for configuring email-related DNS records and services on
Cloudflare. Manages MX, SPF, DMARC, DKIM, TLSRPT, and MTA-STS — including a
Cloudflare Worker + KV to serve the MTA-STS policy file.

## Commands

- `make docs` — regenerate README input/output tables via `terraform-docs`
- `terraform fmt` — format HCL files
- `terraform validate` — validate configuration

Tool versions managed with [mise](https://mise.jdx.dev/) (see `.mise.toml`).

## Architecture

Single flat module — all resources in `main.tf`, organized by section comments:

- **General** — `cloudflare_zone` data source lookup
- **MX** — MX records for root domain + optional subdomains, flattened via
  `locals` into a `for_each` map
- **SPF** — single TXT record built from configurable terms list
- **TLS SMTP** — TLSRPT TXT record
- **MTA-STS** — the most involved piece:
  - Proxied A/AAAA records for `mta-sts.` subdomain (dummy IPs, Cloudflare
    proxies the traffic)
  - `_mta-sts` TXT record with SHA1-based policy version
  - Workers KV namespace + KV entry holding the rendered policy
    (`mta-sts.txt.tpl`)
  - Worker script (`mta-sts.js`) serving the policy from KV
  - Worker route binding `mta-sts.<domain>/*`
- **DMARC** — TXT record assembled from multiple variables with mode
  abbreviation lookup (`relaxed` → `r`, `strict` → `s`)
- **Domain Keys (DKIM)** — `for_each` over a map of DKIM keys, supports both
  TXT and CNAME record types

## Conventions

- All DNS resources use `for_each` (not `count`).
- Extensive variable validation blocks with custom error messages.
- Section comments (`# MX`, `# SPF`, etc.) separate logical groups in all
  `.tf` files.
- Provider constraint: `cloudflare/cloudflare >= 3.0, < 5.0`.

## Releases

Automated via [release-please](https://github.com/googleapis/release-please).
Uses conventional commits — pushes to `main` trigger the release-please GitHub
Action which manages changelog, version bumps, and GitHub releases.
