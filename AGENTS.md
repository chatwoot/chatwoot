# Chatwoot Development Guidelines

## How we build

Chatwoot is never finished. We ship a small version that people can use, we watch what happens in production and in support conversations, and then we fix the problems people actually hit. The rules in this section describe how the team has worked in practice, based on the commit and review history from 2024 and 2025. Read them before you decide what a change should include.

### Decide the scope before you write code

- **Build what was asked, for the cases that happen.** Do not design for rare or future cases nobody asked about. Cover the states a user will see in normal use, such as an empty list, a loading state, a missing permission, or a channel that is not connected. Do not add handling for states the code already prevents. When a feature has a reasonable default, ship the default and wait for someone to ask for a choice.
- **Prefer a constant to a setting.** Add a setting only when a customer or the product owner has asked for one. Examples from the history include the 5 minute out of office guard (#11073), the 30 day stale contact rule (#11186), and the 1,000 chat threshold for skipping the meta request (#10518). Citations shipped as a prompt change and got a toggle months later, when people asked for it (#10958, #12052).
- **When a setting is needed, put it in the place that already exists.** Use a new key in an existing JSONB column or an installation config read through `GlobalConfig`, not a new table or an environment variable. Show the setting only where it applies, e.g., only on Chatwoot Cloud.
- **Do not build an abstraction for a second case that does not exist.** A reviewer removed a provider option from the first voice PR because Chatwoot supported only one provider (#11775). The multi language Captain PR first built a language detection service, then removed it and shipped one prompt line (#11068).
- **Reuse before you add.** Look for an existing concern, service, component, store, or composable that does most of the job, and extend it. Reviewers ask for this often, e.g., `Reauthorizable` instead of a new concern (#9017), the existing `draftMessages` store (#8018), and one shared `OAuthChannel.vue` for Google and Microsoft.
- **Write down what you left out, and say it in the PR.** A short "Not included" list in the PR description is enough, e.g., refunds and webhooks were listed as out of scope in the first Stripe PR (#15765). Do not assume a later cleanup will happen. The IMAP disconnect logic that was turned off "for now" in 2024 stayed off until 2026, so name the follow-up so someone can pick it up.
- **Delete what nobody uses.** When a replacement lands, remove the old path in the same PR or the next one. The team deleted the unused sentiment feature (#9304) and 9,360 lines of the old UI once the new UI was the default (#11720).

### Name things for the reader

- A name should tell the reader what the thing is or what it does, without opening the file. Spell the concept out, e.g., `first_reply_created_at`, not `frca`. Use only the abbreviations the product already uses, such as CSAT and SLA.
- Use one name for one concept across the model, the API, the store, and the UI copy. Two names for the same thing make every reader check whether they are different.
- Keep the Rails suffix that says which layer the class belongs to, such as `Service`, `Builder`, `Listener`, or `Job`, and make the rest of the name say the domain action, e.g., `Messages::StatusUpdateService`. Do not use a generic name such as `Handler`, `Manager`, or `Helper` with nothing more specific in front of it.
- A label, caption, or tooltip on screen has to make sense by itself, because the user can't open it to read more. If a label needs help text to be understood, change the label.
- If you can't find a clear name for a class or method, the design is probably not clear yet. Settle what the code does before you write it.

### Ship in small, reversible steps

- **Keep each PR to one change.** In 2024 and 2025, half of all fixes changed fewer than 20 lines, and the median feature changed between 90 and 230 lines. PRs over 1,000 lines were nearly always migrations, renames, translations, or deleted code. If a feature is larger, split it into stacked PRs by layer, e.g., model, then API, then UI. Do not reformat or rename code that the change does not need.
- **Ship unfinished features dark.** New features and channels start behind a flag in `config/features.yml` with `enabled: false`. The team uses the feature internally first, and releasing it is a separate PR that is often one line, e.g., Instagram went to everyone by deleting one line (#11323). Use one flag for one product change, not one flag per screen.
- **Fix the reported problem at its source.** A fix should change the code that produced the symptom, not every place that looks similar. When a broad fix in #10108 changed 13 files and broke something, the team reverted it within hours and shipped a 2 file fix the same day (#10120).
- **If a change breaks production, revert it and re-land a smaller one.** Do not stack fixes on a broken change. The bubble polish PR (#10759, 18 files) was reverted and came back as a 3 file change (#11348).
- **When you replace a code path, carry its checks over.** The new Copilot endpoint skipped the usage limit that the old endpoint enforced, and the gap stayed open for six weeks (#11489, #11845). List the guards, permissions, and limits on the old path before you replace it.
- **A small change still has to work.** The 31 line domain blocklist (#10016) never applied the list, so it blocked nothing until a fix three days later (#10046). Run the code path you changed before you call it done.

### Check your own work

You have the tools to check a change yourself, so use them instead of asking someone to test it for you.

- Run the specs closest to the change with `bundle exec rspec spec/path/to/file_spec.rb` and `pnpm test`.
- For a UI change, run the app (`pnpm dev`), sign in with the seeded data, and use the changed screen in a browser. Check both what the API saved and what the screen shows.
- End to end tests live in `tests/playwright`.
- Write specs for the behavior that matters most, such as a bug that reached production or a rule that is easy to break. Do not write one spec per method or specs that restate hardcoded values.
- Before you open a PR, run `git diff --stat origin/develop...HEAD` and remove any file that the change does not need.

### Review findings by likelihood and impact

Reviewers, human and AI, often flag problems that are possible in theory and almost never happen. Fixing each one makes the code longer and starts another review round.

- For each finding, rate how likely it is in normal use from 1 to 5, and how bad it would be from 1 to 5.
- If the two scores multiplied are 6 or more, fix it in the PR.
- If the product is below 6, leave the code alone and list the finding in the PR description or a follow-up issue.
- Always fix security problems, data loss, and wrong billing, whatever the score.
- Code that handles cases nobody asked for is also a finding. Flag it the same way you would flag a bug.

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
- **Ruby Version**: Manage Ruby via `rbenv` and install the version listed in `.ruby-version` (e.g., `rbenv install $(cat .ruby-version)`)
- **rbenv setup**: Before running any `bundle` or `rspec` commands, init rbenv in your shell (`eval "$(rbenv init -)"`) so the correct Ruby/Bundler versions are used
- Always prefer `bundle exec` for Ruby CLI tasks (rspec, rake, rubocop, etc.)
- Fix lint errors in the code. Do not disable or suppress a RuboCop or ESLint rule.

## Code Style

- **Ruby**: Follow RuboCop rules (150 character max line length). Use compact `module/class` definitions; avoid nested styles.
- **Vue/JS**: Use ESLint (Airbnb base + Vue 3 recommended)
- **Vue Components**: Use PascalCase
- **Events**: Use camelCase
- **I18n**: No bare strings in templates; use i18n
- **Error Handling**: Use custom exceptions (`lib/custom_exceptions/`)
- **Models**: Validate presence/uniqueness, add proper indexes
- **Type Safety**: Use PropTypes in Vue, strong params in Rails
- **Naming**: Use consistent casing. See "Name things for the reader" above.

## Backend

- **Database foreign keys**: Prefer Rails associations and callbacks over database foreign-key constraints. Add a database foreign key only when there is a clear need and after checking deletion behavior and production migration/locking risks. Existing foreign keys alone are not a reason to add new ones.
- **Migrations**: Create migrations with `bundle exec rails g migration <Name>` so the version is a real timestamp. Never hand-write or round the version (e.g. `20260925000000`); rounded versions collide across branches and break `db:migrate`.
- **One-off backfills**: Put them in `app/jobs/migration/` with `queue_as :async_database_migration`.
- **No custom SQL**: Write queries and data migrations in Ruby with ActiveRecord (`where`, `find_each`, `update!`). Do not use `execute`, SQL heredocs or raw SQL strings.
- Build for the expected production path first. Do not add speculative guards, fallbacks, retries, or edge-case handling unless the caller can actually hit that case or production has proven it necessary.
- Enforce eligibility and exclusivity rules at the earliest shared entry point. Do not repeat backup guards across downstream jobs, callbacks, services, or writes unless a proven independent path bypasses that point.
- Validate input where it is used, so invalid input returns `422 Unprocessable Entity` instead of reaching Sentry:
  - If the value is saved to the database (a column or a key in a JSON/JSONB column), validate it in the model with validations or the existing schema validator. This covers every write path, and `ActiveRecord::RecordInvalid` already returns `422`. Do not repeat the same check in the controller.
  - If the value is only used to process the request together with other params (filters, lookups, service arguments) and is not stored as-is, validate it at the controller or request boundary, reusing existing errors, before it reaches services or queries.
- Accept only the documented type, shape, and value. Do not add compatibility coercions for malformed client values; fix official clients instead.
- When an impossible or misconfigured state would indicate a setup/deployment bug, let it fail loudly instead of silently skipping behavior.
- For locked/internal configs that must exist in production, prefer direct reads (`find`, `find_by!`, required hash keys) over silent fallbacks.
- Operator settings belong in installation configs read through `GlobalConfig` and edited in Super Admin, not in environment variables.
- Do not add validation or response checks unless the code uses the result or the check changes behavior meaningfully.
- Prefer existing repo dependencies/client libraries over hand-rolled protocol code for auth, signing, parsing, or API plumbing.
- Avoid one-use private helpers unless they hide real complexity or make the main flow meaningfully easier to read.
- Optimize for human-readable, idiomatic Rails code. Prefer clear model methods, associations, scopes, and named route helpers over dense controller chains or manually assembled paths.
- Keep record relationships, association traversal, and reusable database queries in models or model scopes. Return an ActiveRecord relation when callers need to filter or order the result.
- Controllers should coordinate requests and prepare responses. Keep request-specific URL generation and presentation logic in controllers or view helpers. Before finalizing controller changes, check that relationship and traversal logic lives in the model layer.
- Put logic for a new feature in its own service instead of adding it to a shared model such as `Conversation`. Pass the account and user into services; do not read `Current.account` or `Current.user` inside them.
- Remove dead/unreachable/unused code
- Don’t write multiple versions or backups for the same logic — pick the best approach and implement it
- In specs, avoid custom helper methods for setup/data. Prefer `let` values and direct per-example setup; only add a helper when it removes meaningful repeated complexity.
- Prefer `with_modified_env` (from spec helpers) over stubbing `ENV` directly in specs
- Specs in parallel/reloading environments: prefer comparing `error.class.name` over constant class equality when asserting raised errors

## Channels and integrations

- **Start with the main flow.** The first PR for a channel or integration supports the main message types and events and lists the rest as not included. Handle webhook events from an explicit list, e.g., `SUPPORTED_EVENTS` in `Webhooks::InstagramEventsJob`, and acknowledge the rest without doing work.
- **Reuse the existing building blocks**:
  - Outgoing messages go through `Base::SendOnChannelService`.
  - Webhooks go through `app/controllers/webhooks/<provider>_controller.rb` and a job in `app/jobs/webhooks/`, with incoming payloads built in `app/builders/messages/`.
  - Integrations are an `Integrations::Hook` with an entry in `config/integration/apps.yml`, and their logic lives in `lib/integrations/<provider>/`.
  - Use the provider's Ruby gem when one exists.
- **Handle each provider error on purpose.** Do not wrap the call in a bare `rescue`.
  - For an authorization error, call `authorization_error!` or `prompt_reauthorization!` from `Reauthorizable` so the user is asked to reconnect. Do not `destroy!` the channel or hook.
  - For a known, harmless error, log it and link the provider's documentation in a comment.
  - For a failed send, mark the message failed with `Messages::StatusUpdateService`.
  - For an unknown error, report it with `ChatwootExceptionTracker`.
  - Log the error class, code, and request ID. Do not log response bodies, credentials, or customer data.
- **Add retries only after production shows the need.** Keep them narrow, with a short fixed limit. The Twilio media retry first shipped as a new download service with its own redirect handling, broke normal downloads, and was reverted. It came back the next day built on the existing `SafeFetch` (#15499, #15502, #15504).
- Scope network validations to the attribute that changed, e.g., `if: :api_key_changed?`.

## Frontend

- **Use `components-next/` for all new UI.** Build from `Button`, `Dialog`, `DropdownMenu`, `EmptyStateLayout`, `TeleportWithDirection`, and the other components in `app/javascript/dashboard/components-next/`. Do not use `woot-button` or `woot-modal`. Use `components-next/` for message bubbles; the old bubbles are being removed.
- **Copy the nearest sibling.** When you add a component, find the most similar existing one and follow it, e.g., `BulkMacroActions.vue` follows `BulkTeamActions`. Do not invent a new visual style or layout.
- **Use the existing composables** from `dashboard/composables/`, such as `useStore`, `useMapGetter`, `useAlert`, `useAccount`, `usePolicy`, `useUISettings`, and `useAbortableRequest`, and from VueUse. Use shared request-cancellation utilities instead of local `AbortController` logic.
- **Handle errors simply.** A failed request usually shows one `useAlert` toast. Add a separate error or empty view only when the screen needs it.
- **Vue API**: Write new components with the Composition API and `<script setup>`. When you edit an existing Options API component, add the composable you need through `setup()` instead of converting the whole file.
- **Migrate in small slices.** Move one mixin, one page, or one component per PR, and delete the old version when nothing uses it.
- Prefer existing design-system utilities and shared composables.
- Use typography utilities instead of manually recreating font styles.
- Use logical Tailwind utilities (`ms`, `me`, `ps`, `pe`, `start`, `end`, `border-s`) for direction-aware layouts. Use `ltr:` and `rtl:` only for utilities that have no logical form, such as `rotate` or `divide-x-reverse`. Update old `ltr:` and `rtl:` pairs on the lines you touch.
- Use `rem` for arbitrary CSS dimensions; preserve native numeric values required by chart/SVG APIs.
- Extract repeated or domain-specific strings, thresholds, colors, and durations into named constants.

## Styling

- **Tailwind Only**:
  - Do not write custom CSS
  - Do not use scoped CSS
  - Do not use static inline styles. A `:style` binding is fine for a value computed at runtime.
  - Always use Tailwind utility classes
- **Colors**: Use the `n-*` design tokens, e.g., `text-n-slate-11` and `border-n-weak`. Refer to `tailwind.config.js` for color definitions.
- Add new animations and keyframes to `tailwind.config.js`, not to a `<style>` block.

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

## Project-Specific

- **Translations**:
  - For product and source-string changes, only update `en.yml` and `en.json`; other languages are handled through Crowdin and the community
  - Crowdin-generated translation sync PRs may update non-English locale files; do not flag those changes solely for modifying translated locale files
  - Preserve product and brand names, OAuth scopes, API values, and other machine-readable identifiers unless an official localized form exists
  - When reviewing Crowdin syncs, verify protected terms remain unchanged. Add newly introduced product names, brand names, and machine-readable identifiers to the Crowdin glossary as non-translatable, and keep the glossary current
  - Backend i18n → `en.yml`, Frontend i18n → `en.json`
- **AI models**: Before adding or changing an OpenAI model in `config/llm.yml` or code, check the deprecations page (https://developers.openai.com/api/docs/deprecations). Do not use a model that has a shutdown date; use the replacement the page recommends. Pick models through `config/llm.yml` and `Llm::FeatureRouter`, not hard-coded names.
- **Branding / white-labeling**: For user-facing strings that currently contain "Chatwoot" but should adapt to branded/self-hosted installs, prefer applying `replaceInstallationName` from `shared/composables/useBranding` in the UI layer (for example tooltip and suggestion labels) instead of adding hardcoded brand-specific copy.

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
- Add a short `Not included` list when the PR leaves out part of the feature on purpose.
- Optionally add a `What changed` section for implementation highlights.
- Do not add a `How this was tested` section listing specs/commands.
