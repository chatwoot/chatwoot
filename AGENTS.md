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

## Frontend Conventions

- Prefer existing design-system utilities and shared composables.
- Use typography utilities instead of manually recreating font styles.
- Use logical Tailwind utilities (`ms`, `me`, `start`, `end`) for direction-aware layouts.
- Use `rem` for arbitrary CSS dimensions; preserve native numeric values required by chart/SVG APIs.
- Extract repeated or domain-specific strings, thresholds, colors, and durations into named constants.
- Use shared request-cancellation utilities instead of local `AbortController` logic.

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

## MU Today fork — deployment and upstream sync

This repo is a fork of `chatwoot/chatwoot`; the `upstream` remote points at it.

- **Merging here does not deploy anything.** Production (`support.mutoday.com`, Hetzner, Docker Compose) is driven by the separate `mu-support` folder, which is rsynced to `/opt/mu-support` on the server. Code only reaches the server once the image is rebuilt there.
- The production image is `chatwoot/chatwoot:<version>-mutoday`, built on the server by `mu-support/build.sh` from this repo's own `docker/Dockerfile`. It is a **full source build**, not a layer on the published image, because the fork changes frontend code — the unread tab badge, the attachment preview and `public/sw.js` — so the asset bundle has to be compiled. Budget tens of minutes and about 4 GB of RAM for it.
- **Syncing from upstream is not a fast-forward.** The fork carries its own commits, so use a real `git merge upstream/develop`, then rebuild the image.
- `Notification::NOTIFICATION_TYPES` carries a MUToday entry, `all_conversations_new_message: 9`. The value doubles as a FlagShihTzu bit on `notification_settings`, so if an upstream release ever adds its own type 9, renumber the MUToday one and migrate both the existing `notifications` rows and the flag bits. Upstream still stops at 8 as of 4.17.0.
- Upgrading production is `./upgrade.sh <version>-mutoday` in `mu-support`: it backs up, bumps `CHATWOOT_VERSION` in `.env`, rebuilds the image, migrates and restarts. It runs the migration with `POSTGRES_STATEMENT_TIMEOUT=0` on purpose — Chatwoot defaults to 14s, which kills `CREATE INDEX CONCURRENTLY` on large tables, and the migrations pass `if_not_exists`, so a retry skips the invalid index and reports success.

### Shipping a change to production

`mu-support/README.md` has the full procedure. The short version, after the change is merged into `develop` here:

1. `rsync -av --exclude .git --exclude backups --exclude src <mu-support>/ root@<server>:/opt/mu-support/` — `--exclude src` matters, that is where `build.sh` keeps its checkout of this repo on the server.
2. Pre-flight, read-only, against the real database:
   `docker compose exec -T postgres psql -U postgres -d chatwoot_production -c "SELECT (SELECT count(*) FROM captain_assistant_responses WHERE status = 0) AS pending_captain_faq, (SELECT max(version) FROM schema_migrations) AS latest_migration;"`
3. `cd /opt/mu-support && nohup ./upgrade.sh <chatwoot-version>-mutoday > upgrade.log 2>&1 &` then `tail -f upgrade.log`. Detach it: the build runs for tens of minutes and losing the SSH session partway through the migration is the worst case. The quiet stretch is `assets:precompile`, which needs about 4 GB of RAM and prints nothing.
4. Verify: `curl -s https://support.mutoday.com/api` reports the new version with `queue_services` and `data_services` both `ok`, and `SELECT count(*) FROM pg_index WHERE NOT indisvalid` returns 0. A killed `CREATE INDEX CONCURRENTLY` leaves an invalid index that the migrations' `if_not_exists` then skips on retry while reporting success, so that query is the only signal.

When the Chatwoot version has not moved and only this repo's code changed, skip `upgrade.sh` — `./build.sh <version>-mutoday && docker compose up -d` is enough, with no migration and no backup step.

Two things that are easy to get wrong:

- **Query the database with `-d chatwoot_production`.** `.env` sets no `POSTGRES_DATABASE`, so Rails falls back to the `config/database.yml` default. The `chatwoot` database that compose creates through `POSTGRES_DB` is empty and unused, and leaving the flag off gives answers that look plausible but come from the empty one.
- **The image tag is `chatwoot/chatwoot:<version>-mutoday`**, built locally on the server. It shares the `chatwoot/chatwoot` name with the published image but is never pulled, so `docker compose pull` has nothing to fetch — that is why `upgrade.sh` calls `build.sh` instead.
