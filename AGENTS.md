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

## Fork (SaaS) Development — READ FIRST on this machine

Full spec and architecture: `docs/fork/` (start with `docs/fork/README.md`).

### Docker-only toolchain (overrides the rbenv/local-Ruby instructions above)

Ruby is NOT installed on this machine. Run every project command inside Docker:

- **Build images (first time)**: `docker compose build base rails vite`
- **Run dev**: `docker compose up rails sidekiq vite`
- **Ruby commands**: `docker compose run --rm rails bundle exec <rails|rubocop|rake> ...`
- **RSpec (ALWAYS via the isolated test stack — never through the `rails` service)**: `docker compose -f docker-compose.yaml -f docker-compose.rspec.yaml run --rm test bundle exec rspec <path>` — the plain `rails` service inherits Neon/Upstash from `.env`, and `RAILS_ENV=test` there would truncate the live dev database (see `docs/fork/error-log/2026-07-02-test-env-pointed-at-neon-dev-db.md`). Note `docker-compose.test.yaml` is an upstream production deploy file, not a test runner.
- **Spec DB init (schema only — NEVER seed it)**: `docker compose -f docker-compose.yaml -f docker-compose.rspec.yaml run --rm test bundle exec rails db:create db:schema:load` — `db:prepare` runs seeds, which breaks installation_config specs (see `docs/fork/error-log/2026-07-02-seeded-test-db-broke-installation-config-specs.md`). The test Postgres is tmpfs-backed, so re-run this after the container is recreated.
- **JS/pnpm commands**: `docker compose run --rm vite pnpm <eslint|test|build|dlx> ...`
- Postgres (Neon) and Redis (Upstash) are external, configured in `.env`. Never commit `.env` or copy its values into docs, logs, or commits.
- Prefer generators/CLIs inside the containers (`rails g migration ...`, `pnpm dlx ...`) over hand-writing boilerplate files.

### Fork rules

- All fork behavior lives in the `custom/` overlay (injected via `prepend_mod_with`/`include_mod_with`, same mechanism as `enterprise/`). Do not edit OSS (`app/`, `lib/`) or `enterprise/` files when an overlay works; the only sanctioned OSS edits are (a) the `custom/` autoload bootstrap in `config/application.rb` and (b) canonical one-line extension points at file bottoms (`Foo.prepend_mod_with('Foo')` — the standard Chatwoot pattern, a no-op upstream). See `docs/fork/ARCHITECTURE.md`.
- Public contracts are frozen: route paths, webhook event names/payloads, `X-Chatwoot-*` headers, and existing response shapes may only be extended additively.
- Quota/entitlement work extends `Account#usage_limits` and the `accounts.limits` jsonb chain — never a parallel store (see `docs/fork/ENTITLEMENTS.md`). Quota denials: HTTP 402 with the additive `error`/`error_code`/`resource`/`current`/`limit` shape.
- Every error you fix during fork work gets an entry in `docs/fork/error-log/` (template provided) before moving on.
- Fork specs live in `spec/custom/`, mirroring the OSS spec layout.
