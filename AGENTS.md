# Chatwoot Development Guidelines

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

## Current Focus — Calendar module (Google Calendar integration)

_Estado: branch `feat/panel-ai-admin-sso` con trabajo del módulo Calendar sin commitear (28 archivos nuevos, 5 migraciones)._

### Archivos del módulo

**Backend (nuevo):**
- Modelos: `app/models/calendar_connection.rb`, `app/models/calendar_connection_calendar.rb`, `app/models/calendar_event.rb`, `app/models/calendar_event_activity.rb`
- Controladores: `app/controllers/api/v1/accounts/integrations/calendar_controller.rb`, `app/controllers/api/v1/accounts/conversations/calendar_events_controller.rb`, `app/controllers/google_calendar/`
- OAuth/helpers: `lib/integrations/google_calendar/`, `app/helpers/google_calendar/`

**Frontend (nuevo):**
- Vista principal: `app/javascript/dashboard/routes/dashboard/calendars/` (`CalendarView.vue`, `WeekGrid.vue`, `AgendaSidebar.vue`, `EventBlock.vue`, `EventModal.vue`, `routes.js`)
- Settings: `app/javascript/dashboard/routes/dashboard/settings/integrations/Calendars.vue`
- En conversación: `app/javascript/dashboard/components/widgets/conversation/CalendarEventsList.vue`
- API client: `app/javascript/dashboard/api/integrations/calendar.js`
- Helpers: `app/javascript/dashboard/helper/calendarTime.js`, `app/javascript/dashboard/helper/calendarLabels.js`, `app/javascript/dashboard/helper/useCalendarCancelledVisibility.js`

**Assets:** `public/dashboard/images/integrations/google-calendar.svg`, `google.svg`, `microsoft-outlook.svg`, `microsoft.svg` (untracked; servidos por Rails en `/dashboard/images/integrations/...` — ver matriz de rebuild abajo).

### Migraciones pendientes (corren con `.\scripts\dev-migrate.ps1`)

```
20260818120000_create_calendar_connections.rb
20260818130000_create_calendar_connection_calendars_and_events.rb
20260818140000_add_soft_delete_and_activities_to_calendar_events.rb
20260818150000_add_display_name_to_calendar_connections.rb
20260818160000_add_hours_to_calendar_connection_calendars.rb
```

### Feature flag, ruta, scope

- Flag: `calendar_integration` (config `config/features.yml:411`, exposed en `app/javascript/dashboard/featureFlags.js:59` como `FEATURE_FLAGS.CALENDAR`, registrado en `app/models/integrations/app.rb:68`).
- Sidebar item: `app/javascript/dashboard/components-next/sidebar/Sidebar.vue:439-442` → `accounts/:accountId/calendars`.
- Ruta FE: `app/javascript/dashboard/routes/dashboard/calendars/routes.js` (vue-router) → `calendars_dashboard_index`.
- Rutas BE: `config/routes.rb:213` (`calendar_events` bajo conversation), `config/routes.rb:461-474` (`calendar_connections` con `oauth`, `events`, `lock`, `unlock`), `config/routes.rb:739` (`google_calendar/callback`).
- Settings sub-ruta: `settings_integrations_calendars` (`integrations.routes.js:93-95`).
- localStorage key para "mostrar cancelados": `LOCAL_STORAGE_KEYS.CALENDAR_SHOW_CANCELLED` (`constants/localStorage.js:11`).

### i18n

- Todas las keys `SIDEBAR.CALENDAR_PAGE.*` y `MODAL.*` están en `app/javascript/dashboard/i18n/locale/en/settings.json:321-397`.
- Para cambios de producto solo editar `en.json` (Crowdin sync el resto).

### Probar end-to-end

1. Activar el flag: Super Admin → Feature Flags → `calendar_integration` → habilitar cuenta.
2. Super Admin → Installation Config → `GOOGLE_OAUTH_CLIENT_ID` / `GOOGLE_OAUTH_CLIENT_SECRET` / `GOOGLE_OAUTH_REDIRECT_URI` (Redirect: `FRONTEND_URL/google_calendar/callback`).
3. `Settings → Integrations → Calendars` (admin) → conectar Google.
4. Sidebar → `Calendars` → elegir cuenta/calendario → click en slot o sobre evento.
5. API client: `CalendarAPI.startOAuth()` → `/api/v1/accounts/:id/integrations/calendar_connections/oauth` (GET).

### Cuando SÍ necesitas rebuild (vs solo restart / HMR)

| Cambio | Acción |
|--------|--------|
| `.vue`, `.js`, `.scss` en `app/` | HMR de Vite — refrescar navegador basta |
| `.rb` en `app/`, `lib/`, `db/migrate/`, `config/` | `docker restart chatwoot-chatwoot-rails-1` |
| Nuevos SVG/asset en `app/javascript/.../assets/images/` | HMR los sirve; verificar consola |
| Nuevos SVG/asset en `public/dashboard/images/` | **requiere `up -d --build`** (montaje excluye `./public/vite` y assets de `public/` se bakean en imagen) |
| Nuevos iconos `i-lucide-*` / `i-ri-*` referenciados en templates | HMR alcanza si ya están en `tailwind.config.js`; si agregás familia nueva, `pnpm exec vite build` + restart |
| `Gemfile`, `package.json`, `Dockerfile`, `docker/entrypoints/*` | **requiere `up -d --build`** |
| Nuevas migraciones | `.\scripts\dev-migrate.ps1` (sin restart) |

Si dudas: `pnpm exec vite build && docker compose -f docker-compose.dokploy.yml -f docker-compose.dokploy.fork.yml restart chatwoot-rails` (lo que hace `.\scripts\dev-vite-build.ps1`).

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

- Prefer the smallest production-ready change that solves the current problem.
- Build for the expected production path first. Do not add speculative guards, fallbacks, retries, or edge-case handling unless the caller can actually hit that case or production has proven it necessary.
- Enforce eligibility and exclusivity rules at the earliest shared entry point. Do not repeat backup guards across downstream jobs, callbacks, services, or writes unless a proven independent path bypasses that point.
- When an impossible or misconfigured state would indicate a setup/deployment bug, let it fail loudly instead of silently skipping behavior.
- For locked/internal configs that must exist in production, prefer direct reads (`find`, `find_by!`, required hash keys) over silent fallbacks.
- Do not add validation or response checks unless the code uses the result or the check changes behavior meaningfully.
- Prefer existing repo dependencies/client libraries over hand-rolled protocol code for auth, signing, parsing, or API plumbing.
- Avoid one-use private helpers unless they hide real complexity or make the main flow meaningfully easier to read.
- Prefer minimal, readable code over elaborate abstractions; clarity beats cleverness
- Break down complex tasks into small, testable units
- Iterate after confirmation
- Avoid writing specs unless explicitly asked
- In specs, avoid custom helper methods for setup/data. Prefer `let` values and direct per-example setup; only add a helper when it removes meaningful repeated complexity.
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

## PR Description Format

- Start with a short, user-facing paragraph describing the product change.
- Add a `Closes` section with relevant issue links (GitHub, Linear, etc.).
- For feature PRs, add `How to test` from a product/UX standpoint.
- For bugfix PRs, use `How to reproduce` when helpful.
- Optionally add a `What changed` section for implementation highlights.
- Do not add a `How this was tested` section listing specs/commands.

## Project-Specific

- **Translations**:
  - For product and source-string changes, only update `en.yml` and `en.json`; other languages are handled through Crowdin and the community
  - Crowdin-generated translation sync PRs may update non-English locale files; do not flag those changes solely for modifying translated locale files
  - Preserve product and brand names, OAuth scopes, API values, and other machine-readable identifiers unless an official localized form exists
  - When reviewing Crowdin syncs, verify protected terms remain unchanged. Add newly introduced product names, brand names, and machine-readable identifiers to the Crowdin glossary as non-translatable, and keep the glossary current
  - Backend i18n → `en.yml`, Frontend i18n → `en.json`
- **Frontend**:
  - Use `components-next/` for message bubbles (the rest is being deprecated)

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

## PaluHub — audio alerts & ActionCable (ops)

Full change brief for AI/human review of the Tasks + alerts PR: [`docs/INTERNAL_TASKS_AND_ALERTS.md`](docs/INTERNAL_TASKS_AND_ALERTS.md).

- Dashboard ding is **not** browser push sound. Agents must enable **Profile → Audio notifications** (`assigned` / `unassigned` / etc.). Default remains `none`.
- Tone `ding` now initializes `Audio` on first `set()` (previously stayed `null` until tone changed).
- Incoming contact messages on **pending** (bot) conversations can alert; other pending traffic stays quiet.
- Presence: client ping **60s**, server `PRESENCE_DURATION` default **90** (set in `.env` / Dokploy). If agents look offline after switching tabs, raise `PRESENCE_DURATION` further.
- Background tab “disconnect”: ActionCable stale monitor (~6s) + browser timer throttling. On tab visible again we `reopen()` + `ReconnectService` refetch. Infra: ensure Traefik/Cloudflare WS idle ≥ 60–120s; cuts at ~100s → proxy; cuts at ~5–15s → client stale/freeze.

## PaluHub fork — local Docker workflow

Fork PaluHub (InboxHub). Documentación cruzada: `panel-ai/AGENTS.md`, `panel-ai/docs/ENVIRONMENTS.md`.

### URLs

| Entorno | Chatwoot | Panel AI |
|---------|----------|----------|
| Local | http://localhost:3000 | http://localhost:3010 |
| Producción | https://inbox.paluhub.com | https://ainbox.paluhub.com |

Red Docker compartida local: `main-chatwoot-local` (external).

### Levantar / rebuild Chatwoot local

```powershell
cd d:\DOCUMENTOS\GITHUB\chatwoot\chatwoot
.\scripts\dev-up.ps1
# o manual:
docker network create main-chatwoot-local
docker compose -f docker-compose.dokploy.yml -f docker-compose.dokploy.fork.yml up -d --build chatwoot-rails chatwoot-sidekiq
```

**No usar** `docker-compose.local.yml` del fork — tira GHCR `develop` e ignora cambios locales.

**Compose canónico fork:** `docker-compose.dokploy.yml` + `docker-compose.dokploy.fork.yml`

### Volúmenes montados (fork)

`app/`, `enterprise/`, `lib/`, `config/`, `db/` → cambios Ruby/Vue se ven **sin rebuild** (restart Rails basta).

**No montar** `./public/vite` — assets stale del host pisan el build de la imagen.

Assets empaquetados en imagen (precompile Vite) → requieren `up -d --build`.

### Restart vs rebuild (Chatwoot)

| Acción | `app/` montado | Assets en imagen |
|--------|----------------|------------------|
| `docker restart chatwoot-chatwoot-rails-1` | Sí | No |
| `up -d --build` | Sí | Sí |

### Producción Chatwoot

- **URL**: https://inbox.paluhub.com
- **Deploy**: branch `develop` vía GHCR (Dokploy)
- Super Admin: `FB_APP_ID`, `FB_APP_SECRET`, `INSTAGRAM_APP_ID`, `INSTAGRAM_APP_SECRET`

---

## PaluHub — fixes y features en este fork

### WhatsApp menús interactivos (branch `fix/whatsapp-interactive-menu`)

**Problema:** Meta Cloud API rechaza `action` como string JSON; botones salían como texto numerado.

**Fix** (commit `293007b4f`):

- `app/services/whatsapp/providers/base_service.rb` — pasar hash en `action` (button/list)
- Specs: `whatsapp_cloud_service_spec.rb`, `whatsapp360_dialog_service_spec.rb`

**Panel AI complementario** (repo hermano, `103ae01`): detectar canal WhatsApp en webhook.

**Estado:** branch ahead 1, pendiente merge a `develop` + redeploy GHCR.

### Contactos — UI y asignación

Branch actual incluye (commit `f29c3ee79`):

- `ContactAssigneeSelector.vue` — fetch agents vía watch `immediate`
- `ContactDetails.vue` — watch `selectedContact`
- `ContactInfo.vue` — `aria-label`, sin `capitalize` en nombres
- `contact.json` / `contactFilters.json` — typo "Identificador"
- `document_number` en contactos (branch `feat/contact-assigned-agent`, merged)

### Instagram OAuth (pendiente)

**Problema:** `instagram_concern.rb` usa `HTTParty.get` en `ig_exchange_token`; Meta requiere POST.

**Archivos:**

- `app/controllers/concerns/instagram_concern.rb` (`exchange_for_long_lived_token`, `make_api_request`)
- `app/services/instagram/refresh_oauth_token_service.rb`

**Workaround:** Instagram Tester en Meta Developers.

### Facebook / Messenger (configuración, no código PaluHub)

Flujo Chatwoot: Add Inbox → **Facebook** → `FB.login` → `me/accounts` → elegir Fan Page.

**Archivos:** `Facebook.vue`, `useFacebookPageConnect.js`, `callbacks_controller.rb`, `facebookScopes.js`

**Scopes:** `pages_messaging`, `pages_show_list`, `pages_manage_metadata`, `business_management`, `pages_read_engagement`

**Cliente externo falla si:** app en Development sin rol Tester, o no es admin de Fan Page.

**Instagram Tester ≠ Facebook Tester.**

### Webhook Messenger

- Ruta: `/bot` (`config/initializers/facebook_messenger.rb`)
- Verify token: `FB_VERIFY_TOKEN` en Super Admin

---

## Meta Developers — checklist PaluHub

### App Facebook (Messenger)

- [ ] Modo **Live** o cliente como **Tester** (Roles → Testers)
- [ ] Permisos Advanced Access: `pages_messaging`, `pages_manage_metadata`, `pages_show_list`, etc.
- [ ] App Domains: `inbox.paluhub.com`
- [ ] JSSDK Allowed Domains: `inbox.paluhub.com`
- [ ] Webhook → `https://inbox.paluhub.com/bot`

### App Instagram (DM directo)

- [ ] `INSTAGRAM_APP_ID` / `INSTAGRAM_APP_SECRET` en Super Admin
- [ ] Redirect: `https://inbox.paluhub.com/instagram/callback`
- [ ] Instagram Testers para cuentas no-Live
- [ ] Cuenta IG **Business/Creator** con mensajes activados

---

## Estado Git PaluHub (snapshot)

_Última actualización: 2026-07-12_  
**InboxHub version:** `1.0.0` — ver [`PALUHUB_VERSION`](PALUHUB_VERSION), [`docs/VERSIONING.md`](docs/VERSIONING.md), [`docs/CHANGELOG_PALUHUB.md`](docs/CHANGELOG_PALUHUB.md), [`docs/RELEASE_INBOXHUB_1.0.0.md`](docs/RELEASE_INBOXHUB_1.0.0.md).

### chatwoot (este repo) — rama `feat/internal-tasks` → release 1.0.0

| Campo | Valor |
|-------|-------|
| **vs origin** | push + merge a `develop` pendientes de este release |
| **HEAD (local)** | commits UI polish + team RR encima de `214fc8bed` |
| **Working tree** | docs de versionado / release (commit docs) |
| **Tag objetivo** | `inboxhub-v1.0.0` en `develop` tras merge |

**Incluye (vs develop):** Internal Tasks + migraciones, ACL/privacy, WA interactive, contact UX, reply/template fixes, UI compacta, split assignee, team→round-robin.

**Historial reciente (feature):**

| Commit (tema) | Descripción |
|---------------|-------------|
| team RR | `feat(conversations): auto-assign agent when assigning a team` |
| UI polish | `fix(ui): compact reply box, tasks polish, and split assignee control` |
| `214fc8bed` | ACL/privacy tasks + contact agent UX |
| `edadfc9b6` | private-note reply + WA template buttons |
| `42b82557d` | Internal Tasks inbox + kanban |

**Migraciones obligatorias en prod:** `20260709120000` … `20260709130000` (ver RELEASE doc).

### panel-ai (repo hermano)

| Campo | Valor |
|-------|-------|
| **Rama** | `develop` |
| Detalle | `panel-ai/AGENTS.md` |

---

## Pendiente deploy / merge (stack completo)

| Item | Repo | Acción |
|------|------|--------|
| **B-NEW-11** (automation replies attended) | chatwoot | commit + merge `feat/internal-tasks` → `develop`, GHCR redeploy, **no requiere `db:migrate`**, smoke en conversación con automation |
| **InboxHub 1.0.0** | chatwoot | merge `feat/internal-tasks` → `develop`, tag `inboxhub-v1.0.0`, GHCR redeploy, **`db:migrate`**, smoke RELEASE |
| WhatsApp channel + menús | panel-ai | verificar prod / merge `master` si falta |
| Refactor UI asistentes | panel-ai | commit + merge cuando estable |
| Instagram POST fix | chatwoot | implementar en `instagram_concern.rb` |
| Meta Live / testers clientes | Meta | operativo |

---

## Fixes recientes (trazabilidad)

Sesiones de revisión dejan bitácora en [`docs/BUGS.md`](docs/BUGS.md).
Cada fix tiene ID, archivo tocado, descripción y cómo probar.

- **`feat/internal-tasks`** — auditoría de 2026-07-11 en dos pasadas:
  - Primera: P0/P1 cerrados (`TASK-001..005`, `CABLE-TASK-01`, `TASK-DESTROY-01`,
    `TASK-CLAIM-01`, `TASK-SCOPE-01`, `NOTE-PRIV-01`, `UX-001/002`).
  - Segunda: 6 adicionales encontrados y cerrados (`B-NEW-01..05`, `B-NEW-09`,
    `B-NEW-10`). Ver `docs/BUGS.md` §2.1 para el detalle.
  - **2026-07-20:** `B-NEW-11` — automation replies now mark conversation as attended.
    Fix en `Message#human_response?` + off-by-one en `Message#valid_first_reply?`. Sin migración.
- Verificar contra [`docs/INTERNAL_TASKS_AND_ALERTS.md`](docs/INTERNAL_TASKS_AND_ALERTS.md)
  antes de mergear — ese doc lista fixes ya aplicados que **no** se deben revertir.

**Tarea pre-merge obligatoria:**
- Correr `db:migrate` en cada entorno (local, staging, prod) por la
  migración `20260711120000_add_assigned_agent_id_to_contacts.rb`
  (`B-NEW-09`). Sin esto, deploys fresh crashean.

**Convención al aplicar fixes nuevos:**
1. Agregar entrada en `docs/BUGS.md` con ID `B-NEW-NNN` o `TASK-NNN` + archivo + descripción + test.
2. Si el fix toca arquitectura, considerar actualizar `docs/INTERNAL_TASKS_AND_ALERTS.md`
   o `docs/REFACTOR_STRUCTURAL.md` (panel-ai).
3. Si el fix es crítico (privacidad, datos, deploy), agregar a la tabla de **"Pendiente deploy / merge"**
   arriba hasta que se promoted a `develop`.
4. Si tocás `db/schema.rb` a mano, **siempre** crear la migración correspondiente.
