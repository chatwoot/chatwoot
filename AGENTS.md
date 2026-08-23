# KIRA.id Development Guidelines

This repository is the **Kira.id** fork of Chatwoot — a customer-support platform
with an embedded AI agent (Captain), WhatsApp channels (official Cloud API **and**
an unofficial QR-login companion), and outbound campaigns (WhatsApp + email).
The upstream Chatwoot *enterprise* edition has been **removed**; in its place we
keep and extend the open-source features (Captain, campaigns, c ontacts/companies).

## Stack & Toolchain

* **Backend**: Ruby on Rails (`ruby` `3.4.4` — see `.ruby-version`), PostgreSQL
  (`pgvector/pgvector:pg16`), Redis, Sidekiq for jobs.
* **Frontend**: Vue 3 + Vite (`vite` `6.x`), Pinia stores, Tailwind. Vuex is removed (`vuex` not in `package.json`); legacy `import from 'vuex'` is shimmed via `app/javascript/dashboard/store/vuexCompat.js` (aliased in `vite.shared.ts`).
* **Package manager**: `pnpm` `10.x` (Node `24.x`). Use `pnpm`, not `npm`/`yarn`.
* **Ruby**: managed via `rbenv`. Before any `bundle`/`rails`/`rspec` command,
  init rbenv (`eval "$(rbenv init -)"`) so the correct Ruby/Bundler are used.
* **Test runners**: `vitest` (JS/Vue) and `rspec` (Ruby).

## Build / Test / Lint

* **Setup**: `bundle install && pnpm install`
* **Run Dev**: `pnpm dev` (overmind running `Procfile.dev`: rails + sidekiq +
  vite). `make run` / `make force_run` are Makefile wrappers around the same.
* **Seed minimal data**: `bundle exec rails db:seed`
* **Seed search fixtures** (bulk): `bundle exec rails search:setup_test_data`
* **Seed a richer account**: `Seeders::AccountSeeder` (Super Admin → Accounts →
  Seed, or `bundle exec rails runner "Seeders::AccountSeeder.new(account: Account.find(<id>)).perform!"`).
* **Lint JS/Vue**: `pnpm eslint` / `pnpm eslint:fix`
* **Lint Ruby**: `bundle exec rubocop -a`
* **Test JS**: `pnpm test` (vitest, `TZ=UTC`) or `pnpm test:watch`
* **Test Ruby**: `bundle exec rspec spec/path/to/file_spec.rb`
* **Single Ruby test**: `bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`
* **Always** prefer `bundle exec` for Ruby CLI tasks (rspec, rake, rubocop, etc.).

## Running with Docker (dev + production)

The repo ships three compose files and a `Makefile` that wraps the common flows.

### Dev stack (`docker-compose.yaml`)
Builds rails + vite dev images straight from `docker/Dockerfile` (no separate
base-image pre-build). Your code is bind-mounted, so editing Ruby/Vue files does
**not** require a rebuild — use `make up` the vast majority of the time.

* `make build-dev` / `docker compose build` — (re)build dev images.
* `make up` — `docker compose up -d` (no rebuild; picks up code changes live).
* `make build-up` — rebuild + up (only when Gemfile/package.json/Dockerfile change).
* `make restart` — recreate containers (picks up compose/env changes).

### Production (`docker-compose.production.yaml`)
Runs the **prebuilt** image from `ghcr.io/kira-id/chatwoot:latest` plus Sidekiq,
Postgres, Redis, and the WhatsApp companion. Secrets/connection params come from
the repo `.env` via `env_file`.

* **Build & push** (linux/amd64): `make build-prod`
  (equivalent: `docker buildx build --platform linux/amd64 \
  --tag ghcr.io/kira-id/chatwoot:latest --push -f docker/Dockerfile .`).
* **Deploy**: `docker compose -f docker-compose.production.yaml up -d`.
* **Verify**: `curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:3000/api`
  (expect `200`; allow ~1–2 min on first boot for `db:prepare`).
* **Redeploy after a push**: `docker compose -f docker-compose.production.yaml
  pull && docker compose -f docker-compose.production.yaml up -d`.

> Notes on the production deploy are documented in `README.deploy.md`
> (nokogiri compile fix, `postcss-import` dep, `theme/colors.js` quoting).
> If a fresh build fails, check that file first.

## Kira-specific modules

* **Captain (AI agent)** — `app/models/captain/*`, `app/javascript/dashboard/
  components-next/captain/`, `app/javascript/dashboard/routes/dashboard/captain/`.
  AI assistants, documents, responses, scenarios, tools. Webhook ingestion from
  [Firecrawl] used for document crawling (`app/jobs/captain/documents/crawl_job.rb`).
* **Campaigns** — `app/javascript/dashboard/routes/dashboard/campaigns/`,
  `app/services/whatsapp/oneoff_campaign_service.rb`,
  `app/services/email/oneoff_campaign_service.rb`. WhatsApp and email one-off
  campaigns.
* **WhatsApp companion (unofficial / QR login)** — `whatsapp-companion/` is a
  standalone Baileys bridge, run as its own container/service (`whatsapp-companion`
  in both compose files). It holds the long-lived WhatsApp WebSocket and proxies
  to/from Chatwoot over HTTP with a shared token. Chatwoot-side code is guarded by
  the `whatsapp_unofficial` provider string (`app/models/channel/whatsapp.rb`,
  `app/controllers/webhooks/whatsapp_unofficial_controller.rb`). See
  `whatsapp-companion/README.md`.
* **Companies** — `app/models/company.rb` + `app/policies/company_policy.rb`,
  `app/controllers/api/v1/accounts/companies/`.
* **CSV import** — `app/services/csv_import/`, `app/controllers/api/v1/accounts/
  csv_import_controller.rb`, `app/javascript/dashboard/components-next/Contacts/
  CsvImportDialog.vue`.

### architecture at a glance
```
WhatsApp (official Cloud API)  ─┐
WhatsApp (companion, QR login) ─┼─> Chatwoot rails (API + web) ─> Postgres (pgvector) / Redis
                             web ─┘                                    └> Sidekiq (jobs)
email (campaigns / outbound) ───> SMTP
Captain AI agent ───────────────> replies via the same conversation pipeline
```

## Code Style

* **Ruby**: Follow RuboCop rules (150 character max line length).
* **Vue/JS**: Use ESLint (Airbnb base + Vue 3 recommended).
* **Vue Components**: PascalCase. **Events**: camelCase.
* **Vue API**: Always use Composition API with `<script setup>` at the top.
* **Type Safety**: PropTypes in Vue, strong params in Rails.
* **I18n**: No bare strings in templates; use i18n.
* **Error Handling**: Use custom exceptions (`lib/custom_exceptions/`).
* **Models**: Validate presence/uniqueness, add proper indexes.
* **Naming**: Use clear, descriptive names with consistent casing.
* **Styling**: Tailwind only — no custom CSS, no scoped CSS, no inline styles.
  Refer to `tailwind.config.js` for color definitions.

## Descriptive & Maintainable Code

The code should be understandable to another engineer **without requiring them to
reconstruct the author's intent**. Prefer code that clearly communicates *what it
does and why it exists*.

### Names Must Explain Intent
* Use descriptive names for variables, methods, classes, components, events, and
  constants. Avoid vague names such as `data`, `result`, `response`, `item`,
  `value`, `obj`, `config`, `handler`, `process`, `run`, `doThing`, or `temp`.
* Prefer domain-meaningful names: `conversation_messages` over `data`,
  `eligible_contacts` over `items`, `subscription_plan` over `plan`,
  `normalized_phone_number` over `value`, `customer_response` over `response`.
* Boolean variables/methods read naturally as predicates:
  `conversation_closed?`, `has_unread_messages?`, `should_sync_contacts?`,
  `requires_human_handoff?`.

### Methods Should Express One Clear Intent
* Method names describe the operation, not the implementation detail.
* Prefer: `assign_conversation_to_inbox`, `build_customer_payload`,
  `mark_messages_as_read`, `find_or_create_contact`.
* Avoid vague methods: `process`, `handle`, `execute`, `update_data`.
  Generic `perform` is acceptable as a conventional framework/service-object entry
  point **only** when the surrounding class name makes the intent obvious.

### Make the Main Flow Easy to Read
Write code so the primary business flow reads top-to-bottom.

```ruby
def sync_contact
  normalized_phone_number = normalize_phone_number
  existing_contact = find_contact(normalized_phone_number)

  return update_contact(existing_contact) if existing_contact

  create_contact(normalized_phone_number)
end
```

* Keep important business decisions visible.
* Extract logic when doing so gives a meaningful name to a business concept.
* Do not extract trivial one-line operations merely to make a method shorter.

### Avoid Clever or Compressed Code
Prefer explicit, readable code over clever tricks. Avoid dense one-liners that
combine multiple business decisions, deeply nested ternaries, excessive chaining
where intermediate values carry meaning, clever metaprogramming, and abbreviations
that require domain knowledge. A few extra lines are fine when they make intent
substantially clearer.

### Comments Should Explain Why, Not What
Do not add comments that merely restate the code.

```ruby
# Contacts can exist without an inbox assignment, so do not use the inbox scope
# when resolving the contact for webhook events.
contact = Contact.find(contact_id)
```

Use comments for: why a non-obvious implementation is necessary, a business rule
not obvious from code, a framework/external-API constraint, a compatibility
requirement, or why an unusual decision must remain. If naming/structure can make
the code self-explanatory, prefer that over a comment.

### Prefer Domain Language
Use terminology already established in Chatwoot/Kira. Before introducing new names,
search the repository for existing terminology and patterns. Avoid creating
synonyms for existing domain concepts (e.g. don't rename `conversation` to
`customer_thread`).

### Make Data Transformations Explicit
Use descriptive intermediate variables when they clarify a transformation.

```ruby
normalized_phone_number = normalize_phone_number(contact.phone_number)
whatsapp_contact_payload = build_whatsapp_contact_payload(
  normalized_phone_number, contact.name
)
```

### Avoid Boolean Ambiguity
Do not rely on ambiguous truthy/falsey values for important business decisions.

```ruby
if conversation.requires_human_handoff?
  escalate_conversation
end
```

Give a named predicate to any condition that represents a business rule.

### Keep Business Rules Discoverable
Important business rules should be easy to locate.

```ruby
return unless conversation_eligible_for_assignment?

def conversation_eligible_for_assignment?
  conversation.open? &&
    conversation.assignee.nil? &&
    conversation.inbox.present?
end
```

Do not extract trivial predicates solely for style. Extract them when the name
communicates a meaningful domain rule.

### Avoid Premature Abstraction
* Prefer existing abstractions when they fit.
* Do not introduce a service object for a few obvious lines, or a generic utility
  method with only one meaningful caller.
* Extract an abstraction when it represents a meaningful domain concept, removes
  substantial complexity, or is genuinely reused.

### Keep Classes and Methods Focused
A class or method should have one clear responsibility. Separate distinct business
operations only when the separation improves readability and names the extracted
logic. Avoid splitting a straightforward flow into tiny methods just to satisfy a
line count.

### Prefer Explicit Control Flow
Make meaningful branches easy to see; prefer guard clauses.

```ruby
return reject_message unless message_valid?
return escalate_message if requires_human_handoff?
return queue_message if outside_business_hours?

deliver_message
```

### Readability Over Cleverness
When two implementations have similar performance/complexity, choose the one a new
engineer understands faster. Optimize for: 1) Correctness, 2) Clear intent,
3) Maintainability, 4) Simplicity, 5) Performance. Do not sacrifice readability for
insignificant micro-optimizations.

## General Guidelines

* Prefer the smallest production-ready change that solves the current problem.
* Build for the expected production path first. Do not add speculative guards,
  fallbacks, retries, or edge-case handling unless the caller can actually hit that
  case or production has proven it necessary.
* Enforce eligibility/exclusivity rules at the earliest shared entry point. Do not
  repeat backup guards across downstream jobs, callbacks, services, or writes
  unless a proven independent path bypasses that point.
* When an impossible/misconfigured state indicates a setup/deployment bug, fail
  loudly instead of silently skipping behavior.
* For locked/internal configs that must exist in production, prefer direct reads
  (`find`, `find_by!`, required hash keys) over silent fallbacks.
* Do not add validation/response checks unless the code uses the result or the
  check changes behavior meaningfully.
* Prefer existing repo dependencies/client libraries over hand-rolled protocol code
  for auth, signing, parsing, or API plumbing.
* Prefer minimal, readable code over elaborate abstractions — **clarity beats
  cleverness**.
* Remove dead/unreachable/unused code. Don't ship multiple versions or backups for
  the same logic — pick the best approach and implement it.

## Before Writing Code

1. Understand the existing architecture and conventions.
2. Search for similar implementations in the repository.
3. Identify the existing domain terminology.
4. For Captain / channels / campaigns, locate the existing Kira-specific code (see
   *Kira-specific modules* above) and extend it rather than duplicating.
5. Reuse existing patterns and dependencies where appropriate.
6. Identify the smallest production-ready change.
7. Consider whether the result is understandable to an engineer who didn't write it.

Do not start coding immediately after finding the first apparently relevant file.

## After Writing Code

1. Read the changed code as if reviewing someone else's PR.
2. Check that names clearly communicate intent and the main flow is easy to follow.
3. Remove unnecessary abstractions, duplicated logic, and unused
   variables/imports/methods/comments.
4. Verify comments explain **why**, not **what**.
5. Confirm the implementation follows existing repository patterns.
6. Run the most relevant lint/test commands.
7. Review the final diff and ensure unrelated files were not modified.

The final implementation should feel like code written by an experienced engineer:
**explicit, descriptive, boring where possible, and easy to maintain.**

## Testing Conventions

* Avoid writing specs unless explicitly asked.
* In specs, avoid custom helper methods for setup/data. Prefer `let` values and
  direct per-example setup; only add a helper when it removes meaningful repeated
  complexity.
* Prefer `with_modified_env` (from spec helpers) over stubbing `ENV` directly.
* In parallel/reloading environments, prefer comparing `error.class.name` over
  constant class equality when asserting raised errors.
* Keep JS specs in `vitest` alongside the component under test.

## Commit Messages

* Prefer Conventional Commits: `type(scope): subject` (scope optional).
  Example: `feat(captain): add intent reporting`.
* Don't reference Claude or other assistants in commit messages.

## PR Description Format

* Start with a short, user-facing paragraph describing the product change.
* Add a `Closes` section with relevant issue links (GitHub, Linear, etc.).
* For feature PRs, add `How to test` from a product/UX standpoint.
* For bugfix PRs, use `How to reproduce` when helpful.
* Optionally add a `What changed` section for implementation highlights.
* Do not add a `How this was tested` section listing specs/commands.

## Project-Specific

### Translations
* For product/source-string changes, only update `en.yml` (backend) and
  `en.json` (frontend). Other languages are handled via Crowdin + community.
* Crowdin sync PRs may touch non-English locale files; don't flag those solely for
  modifying translated files.
* Preserve product/brand names, OAuth scopes, API values, and machine-readable
  identifiers unless an official localized form exists.

### Frontend
* Use `components-next/` for message bubbles (the rest is being deprecated).
* New routes/components generally live under `app/javascript/dashboard/`.
* **State management**: Pinia is the standard. Do not add new Vuex modules or `mapGetters`/`mapActions`/`createStore` from `vuex`; use `defineStore` / `storeToRefs` / `use*Store()` instead (see `app/javascript/dashboard/stores/` and `app/javascript/dashboard/store/storeFactory.js` with `type: 'pinia'`). Existing Vuex-style code still runs via the `vuexCompat.js` shim but is considered legacy and should be migrated opportunistically.

### Deployment
* Production images are published to `ghcr.io/kira-id` (see *Running with Docker*).
* The `whatsapp-companion` is a separate image
  (`ghcr.io/kira-id/whatsapp-companion:latest`) built from `whatsapp-companion/`.
