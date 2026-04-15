# Nexus Development Guidelines

Nexus is the **omnichannel communication, support, and relationship platform** in the IgaraLead ecosystem, based on Chatwoot Community Edition (MIT). It owns conversations, messages, inboxes (including WhatsApp via Baileys), agents, automations, and macros.

## Tech Stack

- **Backend**: Rails 7.1 / Ruby 3.4.4 + PostgreSQL 16 + Redis 7 + Sidekiq
- **Frontend**: Vue 3 (Composition API) + Vite + Tailwind CSS 3
- **Realtime**: ActionCable (WebSocket)
- **Search**: Searchkick + OpenSearch
- **WhatsApp**: Baileys sidecar (Node.js, via `BAILEYS_SIDECAR_URL`)
- **Storage**: S3/MinIO via ActiveStorage
- **Process manager**: Overmind (`Procfile.dev`: backend + sidekiq + vite)

## Build / Test / Lint

- **Setup**: `bundle install && pnpm install`
- **Run Dev**: `pnpm dev` or `overmind start -f ./Procfile.dev`
- **Seed Local Test Data**: `bundle exec rails db:seed` (quickly populates minimal data for standard feature verification)
- **Seed Search Test Data**: `bundle exec rails search:setup_test_data` (bulk fixture generation for search/performance/manual load scenarios)
- **Seed Account Sample Data (richer test data)**: `Seeders::AccountSeeder` is available as an internal utility and is exposed through Super Admin `Accounts#seed`, but can be used directly in dev workflows too:
  - UI path: Super Admin → Accounts → Seed (enqueues `Internal::SeedAccountJob`).
  - CLI path: `bundle exec rails runner "Internal::SeedAccountJob.perform_now(Account.find(<id>))"` (or call `Seeders::AccountSeeder.new(account: Account.find(<id>)).perform!` directly).
- **Lint JS/Vue**: `pnpm eslint` / `pnpm eslint:fix`
- **Lint Ruby**: `bundle exec rubocop -a`
- **Test JS**: `pnpm test` or `pnpm test:watch`
- **Test Ruby**: `bundle exec rspec spec/path/to/file_spec.rb`
- **Single Test**: `bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`
- **Run Project**: `overmind start -f Procfile.dev`
- **Ruby Version**: Manage Ruby via `rbenv` and install the version listed in `.ruby-version` (e.g., `rbenv install $(cat .ruby-version)`)
- **rbenv setup**: Before running any `bundle` or `rspec` commands, init rbenv in your shell (`eval "$(rbenv init -)"`) so the correct Ruby/Bundler versions are used
- Always prefer `bundle exec` for Ruby CLI tasks (rspec, rake, rubocop, etc.)

## Code Style

- **Ruby**: Follow RuboCop rules (150 character max line length)
- **Vue/JS**: Use ESLint (Airbnb base + Vue 3 recommended)
- **Vue Components**: Use PascalCase
- **Events**: Use camelCase
- **I18n**: No bare strings in templates; use i18n
- **Error Handling**: Use custom exceptions (`lib/custom_exceptions/`)
- **Models**: Validate presence/uniqueness, add proper indexes
- **Type Safety**: Use PropTypes in Vue, strong params in Rails
- **Naming**: Use clear, descriptive names with consistent casing
- **Vue API**: Always use Composition API with `<script setup>` at the top

## Styling

- **Tailwind Only**:  
  - Do not write custom CSS  
  - Do not use scoped CSS  
  - Do not use inline styles  
  - Always use Tailwind utility classes  
- **Colors**: Refer to `tailwind.config.js` for color definitions

## General Guidelines

- MVP focus: Least code change, happy-path only
- No unnecessary defensive programming
- Ship the happy path first: limit guards/fallbacks to what production has proven necessary, then iterate
- Prefer minimal, readable code over elaborate abstractions; clarity beats cleverness
- Break down complex tasks into small, testable units
- Iterate after confirmation
- Avoid writing specs unless explicitly asked
- Remove dead/unreachable/unused code
- Don’t write multiple versions or backups for the same logic — pick the best approach and implement it
- Prefer `with_modified_env` (from spec helpers) over stubbing `ENV` directly in specs
- Specs in parallel/reloading environments: prefer comparing `error.class.name` over constant class equality when asserting raised errors

## Codex Worktree Workflow

- Use a separate git worktree + branch per task to keep changes isolated.
- Keep Codex-specific local setup under `.codex/` and use `Procfile.worktree` for worktree process orchestration.
- The setup workflow in `.codex/environments/environment.toml` should dynamically generate per-worktree DB/port values (Rails, Vite, Redis DB index) to avoid collisions.
- Start each worktree with its own Overmind socket/title so multiple instances can run at the same time.

## Commit Messages

- Prefer Conventional Commits: `type(scope): subject` (scope optional)
- Example: `feat(auth): add user authentication`
- Don't reference Claude in commit messages

## Project-Specific

- **Translations**:
  - Only update `en.yml` and `en.json`
  - Other languages are handled by the community
  - Backend i18n → `en.yml`, Frontend i18n → `en.json`
- **Frontend**:
  - Use `components-next/` for message bubbles (the rest is being deprecated)

## Ecosystem Alignment

Nexus is the omnichannel communication platform in IgaraLead. Chatwoot fork with IgaraLead customizations:

1. **Hub owns organizations and users** — Nexus syncs users/orgs from Hub via JWT/webhooks. Hub is identity source. Nexus never creates users locally.
2. **Nexus owns conversations, messages, and inboxes** — no product reinvents messaging. Nexus conversations are the single source of truth for all cross-product communication.
3. **Tenant isolation via `client_slug`** — validate JWT `client_slug` against account in URL. All queries scoped to tenant. See ECOSYSTEM.md isolation spec.
4. **No public APIs** — service-to-service only via `X-Api-Key`. Users authenticate via Hub OAuth2. Baileys is internal sidecar (not public).
5. **Data ownership** — Hub: users, orgs, subscriptions. Nexus: conversations, messages, inboxes, agents. Products integrate via ECOSYSTEM.md contracts.
6. **Integration contracts** — Nexus provides: `POST /igaralead/api/conversations/find_or_create` (Amplex), `POST /igaralead/api/contacts/import` (Entity), `GET /igaralead/metrics/{slug}` (Hub). OAuth2 at `/omniauth/igarahub/callback`.
7. **Fork discipline** — all IgaraLead code isolated in `app/igaralead/`, `app/services/igaralead/`, `config/routes/igaralead.rb`, `lib/omniauth/strategies/igarahub.rb`. Avoid diverging from upstream Chatwoot patterns.
8. **When evaluating changes**: check data ownership, verify tenant isolation, confirm no override of Hub auth, flag any fork conflicts with upstream.

## Ruby Best Practices

- Use compact `module/class` definitions; avoid nested styles

## Enterprise Edition Notes

- Chatwoot has an Enterprise overlay under `enterprise/` that extends/overrides OSS code.
- When you add or modify core functionality, always check for corresponding files in `enterprise/` and keep behavior compatible.
- Follow the Enterprise development practices documented here:
  - https://chatwoot.help/hc/handbook/articles/developing-enterprise-edition-features-38

Practical checklist for any change impacting core logic or public APIs
- Search for related files in both trees before editing (e.g., `rg -n "FooService|ControllerName|ModelName" app enterprise`).
- If adding new endpoints, services, or models, consider whether Enterprise needs:
  - An override (e.g., `enterprise/app/...`), or
  - An extension point (e.g., `prepend_mod_with`, hooks, configuration) to avoid hard forks.
- Avoid hardcoding instance- or plan-specific behavior in OSS; prefer configuration, feature flags, or extension points consumed by Enterprise.
- Keep request/response contracts stable across OSS and Enterprise; update both sets of routes/controllers when introducing new APIs.
- When renaming/moving shared code, mirror the change in `enterprise/` to prevent drift.
- Tests: Add Enterprise-specific specs under `spec/enterprise`, mirroring OSS spec layout where applicable.
- When modifying existing OSS features for Enterprise-only behavior, add an Enterprise module (via `prepend_mod_with`/`include_mod_with`) instead of editing OSS files directly—especially for policies, controllers, and services. For Enterprise-exclusive features, place code directly under `enterprise/`.

## Branding / White-labeling note

- For user-facing strings that currently contain "Chatwoot" but should adapt to branded/self-hosted installs, prefer applying `replaceInstallationName` from `shared/composables/useBranding` in the UI layer (for example tooltip and suggestion labels) instead of adding hardcoded brand-specific copy.

## IgaraLead Integration

Nexus is customized as the IgaraLead omnichannel product. All custom code is isolated under `app/igaralead/`, `app/controllers/concerns/igaralead/`, and `app/services/{igaralead,baileys}/` to minimize upstream merge conflicts.

### Code Isolation Strategy

Custom code is injected via `prepend_mod_with` in `config/initializers/igaralead.rb`:
- `OmniauthCallbacksExtension` — Hub OAuth2 callback handling
- `SessionsExtension` — Hub subscription verification on login
- `DashboardExtension` — Dashboard customization
- `ClientScopable` — `client_slug` validation concern
- `AccountLimitsExtension` — Enforces Hub user/channel limits

### IgaraLead Routes (`config/routes/igaralead.rb`)

**Health & Monitoring:**
- `GET /igaralead/health` — Health check (api, database, redis, sidekiq)
- `GET /igaralead/metrics/:client_slug` — Metrics for Hub dashboard (X-Api-Key)

**Hub Integration:**
- `POST /webhooks/hub` — Receives Hub webhook events (contact/user sync)
- `GET /igaralead/sso` — Cookie-based SSO from Hub

**Cross-Product API (X-Api-Key protected):**
- `POST /igaralead/api/conversations/find_or_create` — Amplex opens conversations
- `POST /igaralead/api/messages` — Amplex sends cross-product messages
- `POST /igaralead/api/contacts/import` — Entity pushes enriched contacts
- `POST /igaralead/api/contacts/enrich` — Entity enriches existing contacts

**Baileys WhatsApp Webhooks (X-Api-Key protected):**
- `POST /webhooks/baileys/{message,status,qr,connection,contact,group}`

**Baileys Session Management (API v1, per inbox):**
- `POST /api/v1/accounts/:id/inboxes/:id/baileys_qr_code`
- `GET /api/v1/accounts/:id/inboxes/:id/baileys_status`
- `POST /api/v1/accounts/:id/inboxes/:id/baileys_disconnect`

### Key Services

- `Igaralead::HubClient` — HTTP client for Hub API (Faraday, X-Api-Key)
- `Igaralead::HubTokenValidator` — JWT/JWKS validation (1h cache)
- `Igaralead::HubSettingsService` — Fetch/cache org settings from Hub
- `Igaralead::ContactSyncService` — Bidirectional contact sync with Hub
- `Igaralead::LimitEnforcementService` — Enforces user/channel limits
- `Baileys::ProviderService` — REST client for Baileys sidecar
- `Baileys::IncomingMessageService` — Processes incoming WhatsApp messages
- `Baileys::SendOnBaileysService` — Sends outgoing WhatsApp messages

### Key Models

- `Channel::BaileysWhatsapp` — WhatsApp channel (session_id, session_status, phone_number)
- User/Contact tables extended with `hub_id`, `hub_synced_at`
- Account table extended with `hub_client_slug`

### OAuth2 Flow

- OmniAuth strategy: `lib/omniauth/strategies/igarahub.rb`
- Redirects to Hub `/oauth/authorize` → callback at `/omniauth/igarahub/callback`
- Scope: `openid profile email`
- Auto-provisions user + AccountUser with role inference from JWT claims
- Direct email/password login blocked when `HUB_OAUTH_CLIENT_ID` is set

### Key Environment Variables

- `HUB_URL`, `HUB_API_URL`, `HUB_API_KEY` — Hub connectivity
- `HUB_OAUTH_CLIENT_ID`, `HUB_OAUTH_CLIENT_SECRET` — OAuth2 credentials
- `HUB_JWKS_URL` — JWKS endpoint for token validation
- `HUB_WEBHOOK_SECRET` — HMAC secret for webhook validation
- `BAILEYS_SIDECAR_URL` — Baileys Node.js sidecar (default: `http://baileys:3500`)
- `BAILEYS_SIDECAR_API_KEY` — Sidecar authentication
- `SHARED_DATABASE_NAME` — Optional: read Hub limits from shared DB instead of HTTP calls

### API Policy

**No public APIs.** All `/igaralead/api/*` endpoints are internal ecosystem use only, protected by `X-Api-Key`. End users access Nexus exclusively via the web UI.

## Post-Change Verification (MANDATORY)

After ANY code modification, run the full verification pipeline before considering the task done. Do not skip steps.

### Backend Verification

```bash
# Lint
bundle exec rubocop -a

# IgaraLead security specs (MANDATORY — covers OWASP Top 10)
bundle exec rspec spec/controllers/igaralead/ spec/services/igaralead/ --format documentation

# Full test suite (or scoped to changed files)
bundle exec rspec spec/path/to/changed_spec.rb
```

### Frontend Verification

```bash
pnpm eslint                                      # Lint
pnpm test                                        # Unit tests
```

### Security Test Coverage (`spec/controllers/igaralead/`, `spec/services/igaralead/`)

The IgaraLead security spec suite covers:
- **Health endpoint** (`health_controller_spec.rb`): public access, no data leakage, JSON content type
- **Integration API** (`integration_controller_spec.rb`): X-Api-Key auth enforcement on all endpoints (find_or_create, messages, contacts/import, contacts/enrich), request rejection without key
- **Baileys webhooks** (`baileys_webhooks_controller_spec.rb`): sidecar API key auth on all webhook types (message, status, qr, connection, contact, group)
- **Hub webhooks** (`webhooks_controller_spec.rb`): HMAC signature validation, missing signature rejection
- **Metrics** (`metrics_controller_spec.rb`): API key auth, tenant scoping, no data leakage in responses
- **Hub token validator** (`hub_token_validator_spec.rb`): nil/empty/malformed token handling, no-raise guarantee
- **Hub client** (`hub_client_spec.rb`): configuration checks, X-Api-Key header injection, timeout/failure handling

### Security Principles

- All `/igaralead/api/*` endpoints require `X-Api-Key` — no public access
- Hub webhook validation via HMAC (`HUB_WEBHOOK_SECRET`)
- Baileys sidecar auth via `BAILEYS_SIDECAR_API_KEY`
- Tenant isolation: `client_slug` from JWT validated against account in URL
- OAuth2 flow: auto-provision users from Hub JWT claims, block direct email/password login when `HUB_OAUTH_CLIENT_ID` is set
- All IgaraLead code isolated from upstream Chatwoot to minimize merge conflicts
- Error responses must not leak internal details
- Security headers enforced via middleware (same as Hub pattern)
