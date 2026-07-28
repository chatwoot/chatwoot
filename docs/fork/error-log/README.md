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

- [2026-07-27 — "Chatwoot never opens": Vite dev mode serves ~1600 unbundled modules through the tunnel (~2 min blank page)](./2026-07-27-vite-dev-mode-unusably-slow-behind-tunnel.md)
- [2026-07-27 — Chatwoot returns 200 but renders a BLANK screen: Vite ≥6 `allowedHosts` 403s the Rails asset proxy](./2026-07-27-vite-allowed-hosts-blocks-rails-proxy-blank-spa.md)
- [2026-07-27 — Every page 500s: rails probes Vite on its own localhost (`VITE_RUBY_HOST` unset), autoBuilds, and OOMs](./2026-07-27-rails-missing-vite-ruby-host-oom-autobuild.md)
- [2026-07-27 — db/schema.rb churns after db tasks against Neon (PostgreSQL 18 vs 16)](./2026-07-27-schema-rb-churn-from-neon-postgres-18.md)
- [2026-07-27 — Full Neon connection URL pasted into POSTGRES_DATABASE (and sslmode left at `disable`)](./2026-07-27-neon-url-pasted-into-postgres-database-var.md)
- [2026-07-27 — REDIS_URL pointed at a compose service the fork had deleted](./2026-07-27-redis-service-missing-from-compose.md)
- [2026-07-20 — rspec `test` service loses installed gems on every `run --rm` (BUNDLE_PATH not mounted)](./2026-07-20-rspec-test-service-loses-installed-gems.md)
- [2026-07-16 — Rails 500s on PendingMigrationError after the upstream merge; migrating churns schema.rb](./2026-07-16-pending-migrations-500-and-schema-churn.md)
- [2026-07-16 — FACEBOOK_API_VERSION ships expired (v18.0) and `.env` cannot change it](./2026-07-16-facebook-api-version-shipped-expired-and-ignores-env.md)
- [2026-07-10 — Vite dev server bound to container-localhost — assets 404 in the browser](./2026-07-10-vite-dev-server-bound-to-container-localhost.md)
- [2026-07-10 — rails db:migrate auto-annotates models and dirties OSS/enterprise files](./2026-07-10-db-migrate-annotation-spill-into-oss-files.md)
- [2026-07-10 — rails/sidekiq containers dead with "404 / No such image" after image re-tag](./2026-07-10-stale-containers-404-after-image-retag.md)
- [2026-07-10 — Sparse custom_attributes PATCH wiped Chatwoot-owned account state](./2026-07-10-sparse-custom-attributes-patch-wiped-account-state.md)
- [2026-07-10 — SSO-only lockdown leaked from dev .env into specs (and blank values counted as ON)](./2026-07-10-sso-flag-leaked-from-dev-env-into-specs.md)
- [2026-07-03 — agentic_ai limit key rejected by the limits JSON schema](./2026-07-03-agentic-ai-limit-key-rejected-by-schema.md)
- [2026-07-03 — SSO-only lockdown bypassable via Google OAuth / SAML](./2026-07-03-sso-only-login-bypassable-via-oauth-saml.md)
- [2026-07-03 — EXTERNAL_LOGIN_URL not exposed to the frontend](./2026-07-03-external-login-url-not-exposed-to-frontend.md)
- [2026-07-02 — Model quota guards broke specs that strictly mock GlobalConfig](./2026-07-02-model-guards-broke-globalconfig-mocked-specs.md)
- [2026-07-02 — Limits endpoint override polluted the cloud response shape](./2026-07-02-limits-endpoint-cloud-shape-pollution.md)
- [2026-07-02 — Seeded test DB broke installation_config specs](./2026-07-02-seeded-test-db-broke-installation-config-specs.md)
- [2026-07-02 — RAILS_ENV=test would have hit the live Neon dev DB](./2026-07-02-test-env-pointed-at-neon-dev-db.md)
