# Chatwoot Development Guidelines

Chatwoot is a Rails API with a Vue 3 dashboard and widget. Enterprise code lives under `enterprise/` and extends the open source code in `app/`.

## Commands

- **Setup**: `bundle install && pnpm install`
- **Run Dev**: `pnpm dev` or `overmind start -f ./Procfile.dev`
- **Seed Local Test Data**: `bundle exec rails db:seed` (quickly populates minimal data for standard feature verification)
- **Seed Search Test Data**: `bundle exec rails search:setup_test_data` (bulk fixture generation for search/performance/manual load scenarios)
- **Seed Account Sample Data (richer test data)**: `bundle exec rails runner "Internal::SeedAccountJob.perform_now(Account.find(<id>))"`, or Super Admin → Accounts → Seed
- **Lint JS/Vue**: `pnpm eslint` / `pnpm eslint:fix`
- **Lint Ruby**: `bundle exec rubocop -a`
- **Test JS**: `pnpm test` or `pnpm test:watch`
- **Test Ruby**: `bundle exec rspec spec/path/to/file_spec.rb`
- **Single Test**: `bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`
- **End to end tests**: `tests/playwright`
- **Ruby**: install the version in `.ruby-version` with `rbenv`, and run `eval "$(rbenv init -)"` before any `bundle` or `rspec` command. Always prefer `bundle exec` for Ruby CLI tasks.

## Working agreements

- Make the smallest production-ready change that solves the task. Small changes are faster to review, test, and revert.
- Build for the cases users hit in normal use, such as an empty list, a loading state, a missing permission, or a disconnected channel. Do not add guards, fallbacks, retries, or settings unless the task asks for them, a caller can actually hit the case, or production has shown it is needed.
- Use a constant until the task asks for a setting. Do not add an abstraction until a second real case exists.
- Reuse an existing concern, service, component, store, or composable before writing a new one. Don't write multiple versions or backups of the same logic.
- Change only what the task needs. Do not reformat or rename unrelated code.
- Remove dead, unreachable, or replaced code in the same PR or the next one.
- If a change looks larger than a few hundred lines, propose a split into stacked PRs, e.g., model, then API, then UI, before you write it.
- Ship unfinished features behind a flag in `config/features.yml` with `enabled: false`, and release in a separate PR.
- Fix a reported problem at its source, not in every place that looks similar.
- When you replace a code path, carry over its guards, permissions, and limits.
- List anything you left out on purpose in the PR description.
- Avoid writing specs unless explicitly asked.
- Before you call a change done, run the specs closest to it. For a UI change, run the app, sign in as a user from `db/seeds.rb`, and use the changed screen. If you can't open a browser, say the UI change is unverified.

## Code Review Rules

These rules apply to whoever writes a review and whoever receives it.

- Score each finding from 1 to 5 for how likely it is in normal use and from 1 to 5 for how bad it would be. Write both scores next to the finding.
- Fix findings whose scores multiply to 6 or more. List the rest in the PR description or a follow-up issue, and leave the code alone.
- When you receive a finding, score it yourself before changing code. If the product is below 6, reply with your scores.
- Always fix a security problem a user or outside caller can reach, data loss, and wrong billing, whatever the score.
- Flag code that handles cases nobody asked for.
- Do not flag non-English locale changes in Crowdin translation sync PRs. Do check that protected terms are unchanged.

## Backend

- Follow RuboCop (150 character lines). Use compact `module/class` definitions, not nested ones.
- **Migrations**: Create migrations with `bundle exec rails g migration <Name>` so the version is a real timestamp. Never hand-write or round the version (e.g. `20260925000000`); rounded versions collide across branches and break `db:migrate`.
- **No custom SQL**: Write queries and data migrations in Ruby with ActiveRecord (`where`, `find_each`, `update!`). Do not use `execute`, SQL heredocs or raw SQL strings.
- **Database foreign keys**: Prefer Rails associations and callbacks over database foreign-key constraints. Add a database foreign key only when there is a clear need and after checking deletion behavior and production migration/locking risks. Existing foreign keys alone are not a reason to add new ones.
- **Models**: Validate presence/uniqueness and add proper indexes. Keep relationships, association traversal, and reusable queries in models or scopes, and return an ActiveRecord relation when callers need to filter or order the result.
- **Controllers**: Coordinate the request and prepare the response. Use strong params, named route helpers, and model methods instead of dense controller chains or manually assembled paths. Keep request-specific URL generation and presentation logic in controllers or view helpers. Before finalizing controller changes, check that relationship and traversal logic lives in the model layer.
- **Services**: Put logic for a new feature in its own service, not in a shared model such as `Conversation`. Name classes by what they act on and what they do, e.g., `Messages::StatusUpdateService`.
- **Settings**: Add a key to an existing JSONB column, or an installation config read through `GlobalConfig` and edited in Super Admin. Do not add environment variables for operator settings.
- **Errors**: Use custom exceptions from `lib/custom_exceptions/`. When an impossible or misconfigured state would indicate a setup/deployment bug, let it fail loudly. For locked/internal configs that must exist in production, use direct reads (`find`, `find_by!`, required hash keys), not silent fallbacks.
- Validate input where it is used, so invalid input returns `422 Unprocessable Entity` instead of reaching Sentry:
  - If the value is saved to the database (a column or a key in a JSON/JSONB column), validate it in the model with validations or the existing schema validator. This covers every write path, and `ActiveRecord::RecordInvalid` already returns `422`. Do not repeat the same check in the controller.
  - If the value is only used to process the request together with other params (filters, lookups, service arguments) and is not stored as-is, validate it at the controller or request boundary, reusing existing errors, before it reaches services or queries.
- Accept only the documented type, shape, and value. Do not add compatibility coercions for malformed client values; fix official clients instead.
- Enforce eligibility and exclusivity rules at the earliest shared entry point. Do not repeat backup guards across downstream jobs, callbacks, services, or writes unless a proven independent path bypasses that point.
- Do not add validation or response checks unless the code uses the result or the check changes behavior.
- Prefer existing repo dependencies/client libraries over hand-rolled protocol code for auth, signing, parsing, or API plumbing.
- Avoid one-use private helpers unless they hide real complexity or make the main flow meaningfully easier to read.
- In specs, prefer `let` values and direct per-example setup over custom helper methods; only add a helper when it removes meaningful repeated complexity. Use `with_modified_env` instead of stubbing `ENV`, and compare `error.class.name` instead of constant classes when asserting raised errors.

## Channels and integrations

- Handle webhook events from an explicit list, e.g., `SUPPORTED_EVENTS` in `Webhooks::InstagramEventsJob`, and acknowledge the rest without doing work.
- Handle each provider error on purpose, not with a bare `rescue`:
  - Authorization error: call `authorization_error!` or `prompt_reauthorization!` from `Reauthorizable` so the user is asked to reconnect.
  - Known, harmless error: log it and link the provider's documentation in a comment.
  - Failed send: mark the message failed with `Messages::StatusUpdateService`.
  - Unknown error: report it with `ChatwootExceptionTracker`.
- Log the error class, code, and request ID. Do not log response bodies, credentials, or customer data.
- Add retries only after production shows the need, with a short fixed limit, built on existing helpers such as `SafeFetch`.

## Frontend

- Write new components with the Composition API and `<script setup>` at the top. Use PropTypes. No bare strings in templates; use i18n.
- Build new UI from `app/javascript/dashboard/components-next/`, including message bubbles. Do not invent a new visual style.
- Use shared request-cancellation utilities instead of local `AbortController` logic.
- **Styling**: Use Tailwind utility classes only. No custom CSS, scoped CSS, or static inline styles; a `:style` binding is fine for a value computed at runtime. Use the `n-*` color tokens and typography utilities from `tailwind.config.js`, and add new animations there.
- Use logical Tailwind utilities (`ms`, `me`, `ps`, `pe`, `start`, `end`, `border-s`). Use `ltr:` and `rtl:` only for utilities with no logical form, such as `rotate`.
- Use `rem` for arbitrary CSS dimensions; keep native numeric values required by chart/SVG APIs.

## Old patterns not to copy

- Options API components and mixins still exist. When you edit one, add the composable you need through `setup()`; do not convert the whole file or copy the pattern into new code.
- `woot-modal` and the old message bubbles are being replaced by `components-next/`. Do not use them in new code.
- Many templates still use `ltr:`/`rtl:` pairs and pixel values. New code uses logical utilities and `rem`.

## Gotchas

- The `feature_flags` column is full. New flags in `config/features.yml` must set `column: feature_flags_ext_1` and be appended at the end. Never reorder or remove existing entries, because bit positions are stored per account.
- `CLAUDE.md` and `.windsurf/rules/chatwoot.md` are links to this file. Edit `AGENTS.md`.

## Enterprise Edition

- Before you change core functionality, search both trees (e.g., `rg -n "FooService|ControllerName|ModelName" app enterprise`) and keep behavior compatible.
- To change OSS behavior for Enterprise, add an Enterprise module with `prepend_mod_with`/`include_mod_with` instead of editing the OSS file, especially for policies, controllers, and services. Put Enterprise-only features directly under `enterprise/`.
- If adding new endpoints, services, or models, consider whether Enterprise needs an override (e.g., `enterprise/app/...`) or an extension point (e.g., `prepend_mod_with`, hooks, configuration) to avoid hard forks.
- Do not hardcode instance- or plan-specific behavior in OSS; use configuration, feature flags, or extension points.
- Keep request/response contracts the same across OSS and Enterprise; update both sets of routes/controllers when introducing new APIs, and mirror renames or moves of shared code in `enterprise/`.
- Put Enterprise specs under `spec/enterprise`, mirroring the OSS layout.
- Practices: https://chatwoot.help/hc/handbook/articles/developing-enterprise-edition-features-38

## Translations, AI models, and branding

- For product and source-string changes, only update `en.yml` (backend) and `en.json` (frontend). Other languages come through Crowdin.
- Preserve product and brand names, OAuth scopes, API values, and other machine-readable identifiers unless an official localized form exists. Add new ones to the Crowdin glossary as non-translatable.
- Before adding or changing an OpenAI model, check https://developers.openai.com/api/docs/deprecations and do not use a model with a shutdown date; use the replacement the page recommends. Pick models through `config/llm.yml` and `Llm::FeatureRouter`, not hard-coded names.
- For user-facing strings that contain "Chatwoot" and should adapt to branded or self-hosted installs, apply `replaceInstallationName` from `shared/composables/useBranding` in the UI layer.

## Worktrees

- Use a separate git worktree and branch per task.
- Give each worktree its own database, Rails and Vite ports, Redis DB index, and Overmind socket/title so several can run at once.

## Commit Messages

- Prefer Conventional Commits: `type(scope): subject` (scope optional)
- Example: `feat(auth): add user authentication`
- Don't reference Claude, Codex, or other AI tools in commit messages

## PR Description Format

- Start with a short, user-facing paragraph describing the product change.
- Add a `Closes` section with relevant issue links (GitHub, Linear, etc.).
- For feature PRs, add `How to test` from a product/UX standpoint.
- For bugfix PRs, use `How to reproduce` when helpful.
- Optionally add a `What changed` section for implementation highlights.
- Do not add a `How this was tested` section listing specs/commands.
