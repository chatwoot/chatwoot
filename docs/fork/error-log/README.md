# Error Log

Running record of every error hit and fixed while implementing the fork spec,
so the same problem is never debugged twice.

## Rules

1. One file per fixed error: `YYYY-MM-DD-<short-slug>.md` (e.g.
   `2026-07-02-custom-overlay-not-autoloaded.md`).
2. Write the entry **when the fix lands**, not later. A fix without an entry
   is an unfinished fix.
3. Copy `TEMPLATE.md` as the starting point; keep entries short but include
   the exact error text (so it's greppable) and the verification command.
4. Never paste secrets (tokens, DB URLs from `.env`) into entries — redact.
5. Before debugging anything, `rg -i "<error snippet>" docs/fork/error-log/`
   to check whether it's already solved.

## Index

Add a line here per entry, newest first:

- [2026-07-10 — SSO-only lockdown leaked from dev .env into specs (and blank values counted as ON)](./2026-07-10-sso-flag-leaked-from-dev-env-into-specs.md)
- [2026-07-03 — agentic_ai limit key rejected by the limits JSON schema](./2026-07-03-agentic-ai-limit-key-rejected-by-schema.md)
- [2026-07-03 — SSO-only lockdown bypassable via Google OAuth / SAML](./2026-07-03-sso-only-login-bypassable-via-oauth-saml.md)
- [2026-07-03 — EXTERNAL_LOGIN_URL not exposed to the frontend](./2026-07-03-external-login-url-not-exposed-to-frontend.md)
- [2026-07-02 — Model quota guards broke specs that strictly mock GlobalConfig](./2026-07-02-model-guards-broke-globalconfig-mocked-specs.md)
- [2026-07-02 — Limits endpoint override polluted the cloud response shape](./2026-07-02-limits-endpoint-cloud-shape-pollution.md)
- [2026-07-02 — Seeded test DB broke installation_config specs](./2026-07-02-seeded-test-db-broke-installation-config-specs.md)
- [2026-07-02 — RAILS_ENV=test would have hit the live Neon dev DB](./2026-07-02-test-env-pointed-at-neon-dev-db.md)
