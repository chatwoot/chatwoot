# Rails 8.1 Upgrade Assessment

Date: 2026-07-24
Repository revision assessed: `56e72eff8d67`

## Executive conclusion

Chatwoot should target **Rails 8.1.3**, but it should not jump from Rails 7.1 to 8.1 in one compatibility change or one production deployment.

The implementation sequence is:

1. Refresh the existing Rails upgrade PR on the latest `develop` and move to Rails 7.2.3.1 while retaining Rails 7.0 framework defaults.
2. Upgrade to Rails 8.0.5 in a stacked PR.
3. Upgrade to Rails 8.1.3 in a second stacked PR.
4. Enable the accumulated Rails 7.1, 7.2, 8.0, and 8.1 defaults in separately deployable risk groups.

Rails itself recommends upgrading one minor version at a time because minor versions may change public APIs and each intermediate release provides the useful deprecation warnings. It also recommends enabling new framework defaults gradually. See the official [Rails upgrade guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html).

The distinction is:

- **Direct-to-8.1 as the final target:** yes.
- **A direct 7.1-to-8.1 implementation and rollout:** no.
- **Stopping on Rails 7.2:** no. Rails 7.2.0 was released on 2024-08-09 and Rails security support lasts two years, so the 7.2 series reaches security end of life on 2026-08-09. It is a short-lived compatibility checkpoint, not a useful long-term destination. See the [Rails maintenance policy](https://guides.rubyonrails.org/maintenance_policy.html).

As of this assessment, the current releases are Rails 7.1.6, 7.2.3.1, 8.0.5, and 8.1.3. See [Rails versions on RubyGems](https://rubygems.org/gems/rails/versions).

Applying the published one-year bug-fix and two-year security windows to each series' initial release date gives:

| Series | Role in this plan | Bug-fix support through | Security support through |
| --- | --- | --- | --- |
| Rails 7.2 | Short compatibility checkpoint | 2025-08-09, already ended | 2026-08-09 |
| Rails 8.0 | Short compatibility/rollback checkpoint | 2025-11-07, already ended | 2026-11-07 |
| Rails 8.1 | Target | 2026-10-22 | 2027-10-22 |

## Current Chatwoot baseline

| Area | Current state | Consequence |
| --- | --- | --- |
| Ruby | 3.4.4 | Already satisfies Rails 7.2 and Rails 8.x. Do not combine another Ruby upgrade with this work. |
| Rails | `~> 7.1`, locked at 7.1.5.2 | Four minor-version checkpoints remain: current 7.1 patch, 7.2, 8.0, and 8.1. |
| Framework defaults | `config.load_defaults 7.0` | The project is on Rails 7.1 code with Rails 7.0 behavior. Defaults migration is a separate body of work. |
| Initializers | 47 files | Several defaults and framework integrations are explicitly customized. |
| Application models | 109 files | Active Record changes have a broad possible blast radius. |
| Application jobs | 86 files | Active Job and transaction timing changes need representative integration tests. |
| Controllers | 185 files | Routing, redirects, query parsing, cookies, and response serialization need smoke coverage. |
| Specs | 796 total, including 234 Enterprise specs | The existing suite is substantial, but upgrade-specific contract tests are still needed. |
| Enterprise overlay | 427 files under `enterprise/app` | Eight of the known Rails 8 enum changes are in Enterprise code. |
| Asset stacks | Vite plus Sprockets-backed Super Admin assets | Rails 8 new-app defaults must not be applied mechanically. |
| File storage | Local/S3/GCS plus the Rails Azure service | Rails 8.1 removes the built-in Azure service. |

Two defaults-sensitive surfaces are particularly important:

- Chatwoot declares 19 encrypted attributes across 13 OSS and Enterprise files.
- Chatwoot has 166 `perform_later`/`deliver_later` call sites; 14 files contain both transaction and enqueue behavior.

## What the compatibility experiments showed

The assessment used isolated copies of this exact revision, changed only dependency constraints and the minimum code necessary to boot, and did not modify the application worktree.

### Rails 7.2.3.1

- Bundler resolved Rails 7.2.3.1.
- The only definite application-code incompatibility found is `User` using `alias_attribute` to alias an association:
  - `app/models/user.rb`: `alias_attribute :conversations, :assigned_conversations`
  - Rails 7.2 treats `alias_attribute` as a database-attribute facility. This should become an explicit method or `alias_method`.
- `administrate-field-belongs_to_search` must move from 0.9.0 to 0.10.0 because 0.9.0 constrains Rails to `< 7.2`.
- Updating `jbuilder` and `debug` during this checkpoint removes failures that otherwise surface later:
  - Jbuilder 2.11.5 uses `ActiveSupport::ProxyObject`, which Rails 8 removes.
  - Debug 1.8.0 fails in the current Ruby 3.4 toolchain while running the Rails update task.
- The first live worker boot exposed an unsafe resolver result: Sidekiq 7.3.1 accepts `connection_pool >= 2.3`, so Bundler selected 3.0.2, but both Sidekiq scheduler threads then crashed because 7.3.1 calls the removed positional `TimedStack#pop` API. Sidekiq 7.3.10 explicitly constrains `connection_pool < 3`; that exact worker line and `connection_pool` 2.5.5 are required for this checkpoint.
- Rack Mini Profiler 3.2.0 references the removed `Rack::File` constant under Rack 3.2. Updating it to 4.0.1 restores its JavaScript endpoint.
- Rails' Active Storage install task tried to generate three migrations, but Chatwoot's initial schema migration and current `schema.rb` already contain `service_name`, variant records, and a nullable checksum. Those generated migrations must not be copied blindly.

### Rails 8.1.3

The initial dependency resolution failed for three independent reasons:

1. Chatwoot's `devise-secure_password` fork constrains Railties to `< 8`.
2. `administrate-field-belongs_to_search` 0.10.0 constrains Rails to `< 8` and Administrate to `< 1`.
3. `rails-i18n ~> 7.0` constrains Railties to `< 8`.

After locally relaxing the two fork constraints, selecting Rails-compatible dependency versions, and making the minimum code changes:

- `bin/rails zeitwerk:check` passed on Rails 8.1.3.
- This required changes to 35 existing main-repository files:
  - `Gemfile` and `Gemfile.lock`
  - 31 model files using removed enum keyword syntax
  - the custom schema dumper initializer
  - the singular `app` route
- The Rails 7.2 `User` association alias fix raises the known floor to **36 files**.
- This boot result does not prove production readiness. It deliberately did not solve Azure support, activate new defaults, run the complete test matrix, or add the required regression specs.

The resolved Rails 8.1 graph also required or selected these application-level changes:

| Dependency | Current | Resolved Rails 8.1-compatible line | Why it changes |
| --- | ---: | ---: | --- |
| `administrate` | 0.20.1 | 1.0.0 | 0.20.x requires Rails `< 8`; Super Admin compatibility and assets must be tested. |
| `administrate-field-belongs_to_search` | 0.9.0 | Custom/upstream-compatible release | 0.10.0 still requires Rails `< 8` and Administrate `< 1`. |
| `devise-secure_password` | Chatwoot fork | Upstream 2.2.1 | This is the latest upstream release supporting Devise 4 while allowing Railties 8; 2.2.3 requires Devise 5. |
| `rails-i18n` | 7.0.10 | 8.1.0 | The 7.x line requires Railties `< 8`. |
| `jbuilder` | 2.11.5 | 2.15.1 | Current version uses removed `ActiveSupport::ProxyObject`. |
| `acts-as-taggable-on` | 12.0.0 | 13.0.0 | Version 12 does not allow Active Record 8.1. |
| `audited` | 5.4.1 | 5.8.0 | Current constraint does not cover Rails 8. |
| `hairtrigger` | 1.0.0 | 1.3.1 | Current constraint does not cover Active Record 8. |
| `devise-two-factor` | 6.1.0 | 6.4.0 | Current constraint stops below Rails 8.1. |
| `devise_token_auth` | 1.2.5 | 1.2.6 | Current constraint stops below Rails 8.1. |
| `bullet` | 8.0.7 | 8.1.3 | Current version rejects Active Record 8.1 at runtime. |
| `sidekiq` | 7.3.1 | 7.3.10 with `connection_pool` 2.5.5 | Sidekiq 7.3.1 crashes its schedulers with `connection_pool` 3. Sidekiq 7.3.10 encodes the safe `< 3` constraint. Rails 8.1 also deprecates its built-in adapter in favor of Sidekiq's adapter, so avoid a simultaneous Sidekiq 8 migration. |
| `sprockets-rails` | Transitive | Explicit dependency, 3.5.x | Administrate 1 no longer supplies the transitive dependency, but Chatwoot Super Admin still uses Sprockets. |
| `debug` | 1.8.0 | 1.11.1 | Required for the current Ruby/Rails update tooling to run cleanly. |

The current, Rails 7.2, and experimental Rails 8.1 lock graphs all passed `bundle-audit` against the advisory database updated on 2026-07-22. That does not replace a release-time audit.

## File-impact estimate

These estimates are for tracked files in the Chatwoot repository. Any remaining companion dependency work is listed separately.

| Path | Exact known minimum | Production-ready estimate | Explanation |
| --- | ---: | ---: | --- |
| Rails 7.2.3.1, version compatibility only | 3 | 3–5 | `Gemfile`, `Gemfile.lock`, and the `User` association alias. |
| Refreshed existing Rails 7.2 PR | 22 | 22 | Also carries Rails-7.2 boundary fixes, Azure adapter replacement, Sidekiq scheduler and profiler compatibility, test stabilization, a production preflight, and the migration guide. |
| Rails 7.2.3.1 plus staged 7.1/7.2 defaults | 3 | 8–15 | Adds explicit defaults, encryption/serialization guards, and focused regression specs. |
| Rails 8.1.3, minimum boot floor from 7.1 | 36 | At least 36 | 31 enum files, two dependency files, `User`, routes, and schema dumper. |
| Rails 8.1.3, production-ready | 36 | 50–70 | Adds Azure strategy, Super Admin asset fixes, defaults, job/auth/storage/request specs, schema validation, and rollout configuration. |
| External companion repositories | 1 repository | Approximately 2–4 files | Only a fork/replacement of `administrate-field-belongs_to_search` remains; `devise-secure_password` is resolved upstream. |

The sequential route does **not** materially reduce the final total number of changed files. It changes when and how those files are changed:

- Rails 7.2 isolates the association and dependency compatibility issues.
- Rails 8.0 isolates removed APIs and the Administrate/Sprockets transition.
- Rails 8.1 isolates Azure removal and request/job/time behavior.
- Each checkpoint can be deployed and rolled back before a serializer or encryption default becomes irreversible.

`bin/rails app:update --pretend` reported 26 config/bin/public actions for Rails 7.2 and 32 for Rails 8.1, in addition to attempted migrations. Those are candidate generator changes, not a recommended diff. Accepting them wholesale would overwrite or churn Chatwoot-specific Vite, Sprockets, environment, deployment, and initializer choices.

## Changed interfaces and Chatwoot impact

### Defaults Chatwoot has not yet activated

Because `config.load_defaults` is still 7.0, upgrading the gem alone and activating defaults are different operations.

| Interface/default | Change | Chatwoot exposure | Required action |
| --- | --- | --- | --- |
| Active Record encryption digest | Rails 7.1 changes key derivation/digest behavior and disables SHA-1 support for affected legacy ciphertext by default. | 19 encrypted declarations, including inbox/channel credentials, integration tokens, OTP secrets, webhook secrets, and Enterprise Twilio credentials. | Pin legacy-readable behavior first, inventory/decrypt all affected records, test deterministic lookups, rewrite ciphertext if needed, then flip the default in a later deploy. |
| Cache serialization | Rails 7.1 introduces format 7.1. | Redis cache and rolling application deploys. | Keep the old write format during the version deploy, then enable the new format after every old process is gone. Treat rollback compatibility as an acceptance criterion. |
| Message serialization/metadata | Rails 7.1 moves to newer serializers and optimized metadata. | Signed IDs, Active Storage IDs, OAuth account signed IDs, Warden/session-adjacent signatures, and any persisted messages. | Explicitly pin on the first deploy; validate old tokens and signatures; enable separately. |
| Callback ordering | Rails 7.1 changes callback execution defaults. | Message creation, notifications, webhooks, emails, imports, and auditing rely heavily on callbacks. | Add ordering assertions around side effects and enable separately from the version bump. |
| Attribute/association validation | Rails 7.1 changes readonly-attribute and belongs-to foreign-key validation defaults. | High model count and Enterprise extensions. | Run the complete model/request suite and inspect new validation errors before enabling. |
| Test exception handling | Rails 7.1 replaces boolean `show_exceptions` values with `:all`, `:rescuable`, and `:none`. | `config/environments/test.rb` still sets `true`. | Replace it with the intentional symbolic mode and re-run controller/request exception specs. |
| HTML parsing/sanitization | Rails 7.1 defaults use HTML5 variants. | Email/message rendering, Help Center content, and Action Text. | Run content fixtures through sanitizer and rendering regression tests. |
| Enqueue after transaction commit | Rails 7.2 changes the standard job/transaction integration. | 166 enqueue/delivery calls and 14 files combining transactions and enqueueing. | Verify jobs never observe uncommitted/missing data and that rollback does not enqueue side effects. |
| PostgreSQL date decoding and migration timestamps | Rails 7.2 changes decoding and validates migration timestamps. | Reporting, imports, schema setup, and old migration history. | Run reporting/import specs and validate both existing-database and fresh-database setup. |

An AST scan found no explicit `return`, `break`, or `throw` inside Chatwoot transaction blocks, so Rails 7.2's changed non-local-return transaction behavior has no direct syntax hit in the current app. Keep a runtime audit for gem and dynamically composed behavior.

### Rails 7.2 interface changes

| Interface | Repo finding | Migration |
| --- | --- | --- |
| `alias_attribute` | `User` aliases `conversations` to an association. | Replace with an explicit delegating method or `alias_method`; add a user association spec. |
| Active Job test adapter selection | Tests now consistently respect configured `queue_adapter`. | Ensure test config uses the test adapter where matcher semantics require it; run job and mailer specs. |
| Framework defaults | Enqueue timing, Active Storage WebP behavior, PostgreSQL date decoding, migration timestamp validation, and YJIT defaults become available. | Activate one risk group at a time after the Rails 7.2 code deploy. |

See the official [Rails 7.2 release notes](https://guides.rubyonrails.org/7_2_release_notes.html) and [upgrade guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html).

### Rails 8.0 interface changes

| Interface | Repo finding | Migration |
| --- | --- | --- |
| Enum declaration | Rails 8 removes keyword-form enum declarations. Chatwoot has 39 declarations in 31 files: 23 OSS and 8 Enterprise files. | Change `enum status: ...` to `enum :status, ...`; preserve prefixes, suffixes, defaults, scopes, and serialized values; run model/API specs. |
| `ActiveSupport::ProxyObject` | Jbuilder 2.11.5 uses the removed class. | Upgrade Jbuilder before the Rails 8 bump. |
| Active Record internal APIs | Rails removes deprecated connection-pool and schema behavior. Chatwoot subclasses a generic internal schema dumper constant. | Rework or remove the schema dumper monkey patch against the PostgreSQL dumper and verify triggers/indexes/schema output. |
| Active Job transaction setting | Old `enqueue_after_transaction_commit` configuration is deprecated on the path to removal in 8.1. | Use the supported boolean/per-job behavior and verify Sidekiq jobs around commit and rollback. |
| Azure Active Storage | The service is deprecated in 8.0. | Complete an extracted/custom adapter or customer migration before 8.1. |
| Fresh database migration behavior | `db:migrate` on a fresh database loads the schema before pending migrations. | Test both fresh schema load and upgrade from the oldest supported production schema. |
| New-app stack defaults | Propshaft, Solid Queue, Solid Cache, Solid Cable, Kamal, and the authentication generator are promoted for new apps. | Do not adopt them as part of the Rails upgrade. Existing Vite, Sprockets, Sidekiq, Redis, and Devise contracts should remain stable. |

See the official [Rails 8.0 release notes](https://guides.rubyonrails.org/8_0_release_notes.html).

### Rails 8.1 interface changes

| Interface | Repo finding | Migration |
| --- | --- | --- |
| Azure Active Storage service | Rails removes the built-in service. `config/storage.yml` still defines `service: AzureStorage`, selectable with `ACTIVE_STORAGE_SERVICE=microsoft`. | This is a hard production blocker for Azure-backed installations. Supply a maintained adapter with integration tests or formally migrate/deprecate Azure. |
| Routes | `resource :app, only: [:index]` fails Rails 8.1 route validation because a singular resource has no collection index action. | Express the route with an explicit `scope`/`get` while preserving every existing URL and helper consumed by the frontend. |
| Parameter parsing | Leading-bracket parameter names are no longer normalized and semicolons are no longer query separators. | Add request contract tests and sample production traffic for API, OAuth, and webhook query strings. Communicate any client-facing incompatibility. |
| Routes to multiple paths | Deprecated multi-path route support is removed. | Confirm all routes compile and compare `rails routes` before and after. |
| Time conversion | `to_time` now preserves the receiver timezone; Time/TimeWithZone arithmetic removals land. | Test the two application `to_time` call sites, especially reporting timezone boundaries and DST fixtures. |
| `schema.rb` order | Table columns are sorted alphabetically. | Expect a large one-file diff; isolate it in a schema-only commit and prove no semantic schema loss. |
| Active Job adapter | The Rails built-in Sidekiq adapter is deprecated in favor of the adapter shipped by Sidekiq. Symbol values and the application-level enqueue-after-commit setting are removed. | Update within Sidekiq 7.3.x, verify the loaded adapter origin, and test retries, schedules, unique/cron jobs, mail delivery, and transaction boundaries. |
| Custom job serializers | `#klass` must be public. | No custom serializer was found in the current tree; retain a boot-time registry check. |
| Redirect/JSON defaults | New 8.1 apps raise on path-relative redirects and stop escaping selected HTML characters in JSON. | When activating 8.1 defaults, audit 73 `redirect_to` call sites and API snapshots. Version-only boot can retain old behavior. |
| Order-dependent finders | Rails 8.1 deprecates order-dependent `first` calls without an order. | Capture deprecations in CI and fix only queries where nondeterminism matters. |
| `ActiveSupport::Configurable` | Deprecated in 8.1. | The experimental boot warning originates in `omniauth-rails_csrf_protection` 1.0.2; track or patch upstream before Rails 8.2. |

See the official [Rails 8.1 release notes](https://guides.rubyonrails.org/8_1_release_notes.html).

### Removed interfaces audited without a direct application hit

The repository scan also checked the principal removed interfaces that do not currently require an application edit:

| Removed/deprecated interface | Audit result |
| --- | --- |
| `ActiveRecord::ConnectionAdapters::ConnectionPool#connection` | No application or Enterprise call found. |
| Active Job `:never`, `:always`, and `:default` enqueue-after-commit values | No application configuration using these symbols found. |
| Application-level deprecated `config.active_job.enqueue_after_transaction_commit` | No current setting found; transaction/enqueue behavior still needs runtime tests. |
| Custom Active Job serializer private `#klass` | No custom Active Job serializer found. |
| SuckerPunch's internal Rails adapter | SuckerPunch is not the configured queue backend. |
| Time-to-TimeWithZone addition and `Time#since(Time)` | No direct application call pattern found; the two `to_time` call sites remain in scope. |
| SQLite adapter removals | Chatwoot's supported production path is PostgreSQL; fresh and upgraded PostgreSQL remain in the matrix. |

## Highest-risk break scenarios

| Risk | Severity | What could break | Detection and containment |
| --- | --- | --- | --- |
| Encrypted credentials become unreadable | Critical | Email inbox passwords, social tokens, webhook secrets, OTP secrets, integration tokens, and Enterprise channel credentials. | Preflight decrypt scan with counts by model/attribute; dual-readable configuration; canary reads and writes; do not remove legacy support until all old processes and ciphertext are gone. |
| Azure file storage stops booting or serving files | Critical for affected installs | Upload, download, preview, direct upload, and purge operations when `ACTIVE_STORAGE_SERVICE=microsoft`. | Decide support policy before Rails 8.0; run Azure emulator/real-account contract tests; block Rails 8.1 rollout without a passing adapter. |
| Jobs run before commit or disappear on rollback | High | Notifications, email, webhooks, message fan-out, imports, search indexing, and reporting side effects. | Transaction integration specs plus Sidekiq smoke tests; compare enqueue and failure metrics during canary. |
| Authentication/session/signature invalidation | High | Agent sessions, API auth, OTP flows, signed IDs, password policy, OAuth, and Active Storage links. | Mixed-version rolling-deploy test; old cookie/token fixtures; fork compatibility specs; explicit serializer settings. |
| Super Admin loses CSS/JS or fields | High | Administrate 1 changes and loss of transitive Sprockets dependencies. | Make `sprockets-rails` explicit or migrate intentionally; production asset precompile; browser smoke every Super Admin CRUD path and custom field. |
| API or webhook parameter behavior changes | High | Leading-bracket or semicolon query strings from old/third-party clients. | Production log sampling, request fixtures, contract tests, and a documented client migration if such traffic exists. |
| Enum API/values drift | High | Scopes, predicates, validations, JSON values, database values, Enterprise policies, and background jobs. | Mechanical syntax-only commits split by domain; assert mappings before/after; run affected request/job specs. |
| Schema or fresh install drifts | High | Trigger definitions, schema loader, Active Storage duplicate migrations, and extension setup. | Compare schema objects, indexes, constraints, triggers, and extensions on upgraded and fresh PostgreSQL databases. |
| Time/reporting results shift | Medium | Daily boundaries, unread counts, report grouping, and DST behavior. | Timezone matrix tests for UTC, non-UTC, and DST transition dates. |
| Hidden Enterprise incompatibility | Medium to high | Overrides and prepended modules load after the OSS path appears healthy. | Run `zeitwerk:check`, the full Enterprise suite, and product smokes with Enterprise enabled at every checkpoint. |

## Prerequisites and migration decisions

The following work must happen before Rails 8.1 can be considered releasable:

1. **Choose the Azure policy.**
   - Preserve Azure by extracting/maintaining an `ActiveStorage::Service` adapter, or
   - announce deprecation and supply a verified blob migration path to S3/GCS.
   - This decision changes product support and must not be inferred during implementation.

2. **Prepare the Rails-constrained Admin dependency.**
   - `devise-secure_password` is resolved by moving to upstream 2.2.1 in the Rails 7.2 checkpoint.
   - Replace, upstream, or maintain a Rails 8/Administrate 1-compatible `administrate-field-belongs_to_search`.

3. **Inventory encrypted production data.**
   - Count rows by model and encrypted attribute.
   - Prove all values decrypt under the transition configuration.
   - Prove deterministic queries still return the same records.
   - Define the re-encryption batch, retry, audit, and rollback procedure.

4. **Define rolling-deploy compatibility.**
   - Pin cache, message, cookie, and encryption formats during version-only deploys.
   - Test old and new application processes against the same Redis, database, jobs, and cookies.
   - Enable each new write format only after old processes cannot return.

5. **Make the Super Admin asset ownership explicit.**
   - Either declare and retain Sprockets or migrate those assets in a separate project.
   - Do not let an Administrate dependency update silently choose the asset architecture.

6. **Reconcile Active Storage migration history.**
   - Verify every supported installation has the `service_name`, variant record, and nullable checksum changes even though the squashed initial migration already has them.
   - Add idempotent corrective migrations only if real supported installations are missing them.

7. **Add upgrade observability.**
   - Fail CI on new Rails deprecations after an allowlist is baselined.
   - Add dashboards/alerts for job failures and latency, session/auth failures, Active Storage errors, request 4xx/5xx, database errors, and cache hit rate.

## Dependency-ordered implementation plan

Each milestone should be independently green and revertible. Framework defaults and serialized write formats should not change in the same deployment as the Rails gem version.

### Milestone 0: Guardrails and dependency unblockers

#### R0.1 — Establish the upgrade CI lane (S)

- **Files:** CI configuration, deprecation configuration, and a small boot/contract spec.
- **Work:** Run the current suite with deprecations captured; add `zeitwerk:check`, production boot, assets, fresh schema load, and `bundle-audit`.
- **Acceptance:** Current Rails 7.1.5.2 is green; known deprecations are recorded with owners; newly introduced deprecations fail the upgrade lane.
- **Verify:** Full OSS and Enterprise RSpec suites, targeted frontend build, RuboCop for changed Ruby files, production asset precompile, and fresh PostgreSQL schema load.
- **Depends on:** None.

#### R0.2 — Move `devise-secure_password` to upstream 2.2.1 (S)

- **Work:** Replace the inaccessible Chatwoot fork with the exact upstream release supporting Devise 4 and Railties 8; validate password policy, Devise callbacks, authentication, and MFA.
- **Acceptance:** Upstream 2.2.1 is locked and the authentication/MFA matrix passes on every checkpoint.
- **Depends on:** R0.1.

#### R0.3 — Resolve the Administrate search field dependency (M, companion repository)

- **Work:** Upstream, fork, or replace the field for Administrate 1/Rails 8; verify its search query, form, display, and authorization behavior.
- **Acceptance:** Versioned dependency compatible with both the Rails 7.2 checkpoint and Administrate 1; Super Admin contract tests pass.
- **Depends on:** R0.1.

#### R0.4 — Decide and prototype Azure support (M)

- **Work:** Select preserved-adapter or migration/deprecation path; prototype the chosen option against upload/download/direct-upload/variant/purge operations.
- **Acceptance:** Written product decision and a passing proof of concept. Rails 8.1 is blocked until this is complete.
- **Depends on:** None.

### Milestone 1: Reach Rails 7.2 safely

#### R1.1 — Resolve Rails 7.2 dependencies and association alias (M)

- **Files:** `Gemfile`, `Gemfile.lock`, `app/models/user.rb`, focused dependency/user specs.
- **Work:** Upgrade Rails to 7.2.3.1, select `administrate-field-belongs_to_search` 0.10.0, update Jbuilder/debug, and replace the association `alias_attribute`.
- **Acceptance:** Rails reports 7.2.3.1; defaults remain 7.0; user conversation APIs are unchanged; no unexpected lockfile upgrades.
- **Verify:** User model/request specs, authentication specs, Admin specs, full suite, `zeitwerk:check`, asset builds, and advisory audit.
- **Depends on:** R0.1 and a compatible result from R0.3.

#### R1.2 — Validate data, jobs, and supported databases on 7.2 (M)

- **Files:** Focused request/job/storage/reporting specs and CI matrix only.
- **Work:** Test Active Job adapter behavior, transaction boundaries, PostgreSQL date handling, migration timestamp validation, WebP variants, upgraded database, and fresh database.
- **Acceptance:** No job observes uncommitted data; rollback suppresses side effects; schema and reports match the 7.1 baseline.
- **Depends on:** R1.1.

**Deployment checkpoint:** Deploy Rails 7.2.3.1 with 7.0 defaults, canary it, and prove rollback to 7.1.6.

### Milestone 2: Catch up Rails 7.1 and 7.2 defaults

#### R2.1 — Migrate encryption and serialized formats (M)

- **Files:** Framework-default initializer/config, encryption service or runner if needed, and encryption/cache/signature specs.
- **Work:** Pin transition settings; run decrypt/deterministic-query inventory; re-encrypt if required; then enable cache and message formats in separate deploys.
- **Acceptance:** Old ciphertext, cookies, signed IDs, cached values, and jobs remain readable through the rolling-deploy window; rollback procedure is exercised.
- **Depends on:** R1.2.

#### R2.2 — Enable model, callback, parser, and job defaults (M)

- **Files:** Defaults initializer plus focused model, callback, message-rendering, and job specs.
- **Work:** Enable remaining 7.1 defaults in small groups, then 7.2 defaults; keep any intentionally retained old setting documented.
- **Acceptance:** `config.load_defaults 7.2` is possible without an unexplained compatibility override; all product contracts remain stable.
- **Depends on:** R2.1.

**Deployment checkpoint:** Run Rails 7.2 with 7.2 defaults before beginning Rails 8 removal work.

### Milestone 3: Remove Rails 8.0 incompatibilities

The enum rewrite should be split into four syntax-only tasks so review can verify value mappings:

#### R3.1a — Conversation and messaging enums (S)

- **Files:** `conversation`, `message`, `attachment`, `contact`, `inbox`, `webhook`, `notification`, and `notification_subscription`.
- **Acceptance:** Every mapping and generated predicate/scope is identical before and after.
- **Depends on:** R2.2.

#### R3.1b — Accounts, channels, bots, and integrations enums (S)

- **Files:** `user`, `account_user`, `agent_bot`, `agent_bot_inbox`, `assignment_policy`, `integrations/hook`, `channel/twilio_sms`, and `channel/web_widget`.
- **Acceptance:** Same as R3.1a, including deterministic encrypted integration behavior.
- **Depends on:** R2.2.

#### R3.1c — Content, import, campaign, and filter enums (S)

- **Files:** `article`, `data_import`, `data_import_item`, `custom_filter`, `custom_attribute_definition`, `campaign`, and `macro`.
- **Acceptance:** Same as R3.1a; import and campaign jobs preserve values and scopes.
- **Depends on:** R2.2.

#### R3.1d — Enterprise enums (S)

- **Files:** Eight Enterprise model/concern files found by the audit.
- **Acceptance:** Enterprise mappings, policies, Captain flows, SLA behavior, and Copilot message behavior are unchanged.
- **Depends on:** R2.2.

#### R3.2 — Upgrade Administrate and own the asset pipeline (M)

- **Files:** Dependency files, asset manifest/config if needed, Super Admin views/fields only where Administrate 1 requires it, and Admin specs.
- **Work:** Upgrade Administrate to 1.0, make `sprockets-rails` explicit, integrate R0.3, and preserve Vite for the dashboard.
- **Acceptance:** Production assets precompile; every Super Admin CRUD screen loads CSS/JS and custom fields; no dashboard asset regression.
- **Depends on:** R0.3, R3.1 tasks.

#### R3.3 — Replace removed/internal Rails APIs (S)

- **Files:** Schema dumper initializer, route compatibility only if needed on 8.0, and focused schema/route specs.
- **Work:** Remove or rebase the PostgreSQL schema dumper patch; upgrade Jbuilder; prove there are no remaining removed API calls.
- **Acceptance:** `zeitwerk:check`, schema dump/load, and route compilation pass on both Rails 7.2 and 8.0.
- **Depends on:** R3.1 tasks.

#### R3.4 — Upgrade to Rails 8.0.5 (M)

- **Files:** Dependency files plus narrowly required config/spec updates.
- **Work:** Update Rails, Administrate-related dependencies, Audited, Hairtrigger, Rails I18n, and compatible supporting gems. Keep Sidekiq 7.3 and existing runtime architecture.
- **Acceptance:** Rails 8.0.5 boots in production mode; 7.2 defaults remain explicit; OSS/Enterprise suites and product smokes pass.
- **Depends on:** R0.2, R3.2, R3.3.

**Deployment checkpoint:** Deploy Rails 8.0.5 and observe it before removing Azure or activating Rails 8 defaults.

### Milestone 4: Reach Rails 8.1

#### R4.1 — Complete the Azure storage migration/adapter (M)

- **Files:** Adapter/config/migration runner and storage contract specs, according to R0.4.
- **Acceptance:** Every supported storage service passes upload, download, direct upload, variant, mirror if applicable, delete, and purge tests; customer rollback/migration procedure is documented.
- **Depends on:** R0.4, R3.4.

#### R4.2 — Migrate Rails 8.1 routes and request contracts (M)

- **Files:** `config/routes.rb` plus route/request/webhook/OAuth specs.
- **Work:** Replace the singular-resource index route, compare route tables, and test legacy query syntax exposure.
- **Acceptance:** Existing frontend URLs and helpers are unchanged; any unsupported third-party query syntax has an explicit migration decision.
- **Depends on:** R3.4.

#### R4.3 — Update Rails 8.1 dependencies and job adapter (M)

- **Files:** Dependency files, job config, and focused auth/job specs.
- **Work:** Update Rails I18n, acts-as-taggable-on, Devise Two Factor, Devise Token Auth, Bullet, and Sidekiq within 7.3.x; verify Sidekiq supplies the adapter.
- **Acceptance:** Authentication, OTP, tokens, tags, retries, cron, mail, and transaction timing pass; no Rails built-in Sidekiq adapter warning.
- **Depends on:** R0.2, R3.4.

#### R4.4 — Upgrade to Rails 8.1.3 (M)

- **Files:** Dependency files, time call sites if behavior requires an explicit conversion, schema dumper, and focused specs.
- **Work:** Take Rails 8.1.3, verify time semantics, allow the intentional schema sort in an isolated commit, and resolve app-owned deprecations.
- **Acceptance:** Production boot, `zeitwerk:check`, full OSS/Enterprise suites, asset builds, fresh/upgrade database paths, all storage services, auth, jobs, Action Cable, mailboxes, APIs, webhooks, and reporting smokes pass.
- **Depends on:** R4.1, R4.2, R4.3.

**Deployment checkpoint:** Canary Rails 8.1.3 with prior defaults and serialized formats. Prove rollback to Rails 8.0.5.

### Milestone 5: Activate Rails 8 defaults and close the migration

#### R5.1 — Enable Rails 8.0 defaults (S)

- **Work:** Enable each 8.0 default, including regex timeout and freshness behavior, with targeted tests.
- **Acceptance:** `config.load_defaults 8.0` is possible with documented exceptions only.
- **Depends on:** Stable R4.4 production checkpoint.

#### R5.2 — Enable Rails 8.1 defaults (M)

- **Work:** Enable relative-redirect enforcement, JSON escaping changes, view tracker changes, required-column ordering checks, and remaining defaults in separate risk groups.
- **Acceptance:** API snapshots, redirects, views, forms, and query behavior are intentionally accepted; `config.load_defaults 8.1` is active.
- **Depends on:** R5.1.

#### R5.3 — Remove transition compatibility and finish observability window (S)

- **Work:** Remove encryption/serializer dual-read settings only after the rollback window expires; close the deprecation allowlist; capture operational results.
- **Acceptance:** No unexplained Rails deprecations; no old processes/data require transition settings; runbook and support notes are complete.
- **Depends on:** Stable R5.2 deployment.

## Verification matrix

Every Rails-version checkpoint should run:

```sh
eval "$(rbenv init -)"
bundle check
bundle exec rails runner 'puts Rails.version'
bundle exec rails zeitwerk:check
bundle exec bundle-audit check --update
bundle exec rspec
bundle exec rubocop <changed-ruby-files>
pnpm build
```

It should also run production-mode boot and asset precompile using CI-safe secrets, plus:

- Fresh PostgreSQL database creation from `schema.rb`.
- Upgrade of a scrubbed production-like database with realistic encrypted data.
- Redis shared between old/new app and Sidekiq processes.
- Mixed-version rolling deploy and rollback.
- Disk, S3, GCS, and Azure-or-replacement Active Storage contracts.
- Agent login, API token, OTP, password policy/history, OAuth, and signed-link fixtures.
- Inbox message creation through API, email, supported social channels, and webhook delivery.
- Sidekiq immediate, scheduled, retry, cron, mail, and transaction-boundary jobs.
- Action Cable/WebSocket updates and notification fan-out.
- Super Admin CRUD and custom field browser smoke tests.
- Reporting across UTC, a non-UTC zone, and a DST transition.
- Enterprise-enabled suite and Captain/SLA/Copilot smokes.

## Rollout and rollback rules

- Never combine a Rails minor-version change with a new cache/message/encryption write format.
- Keep database changes expand/contract compatible with the previous deployed Rails version.
- Do not remove old serializer/encryption readers until all old workers, web processes, cached values, queued jobs, and rollback windows are gone.
- Canary web and worker processes separately; a healthy web boot does not prove Active Job compatibility.
- Preserve Rails 8.0.5 as the immediate rollback target for the Rails 8.1 deployment.
- Treat Azure service errors, decrypt failures, auth failure-rate increases, Sidekiq retry growth, and schema drift as rollout blockers rather than post-release cleanup.

## Scope deliberately excluded

The Rails migration should not also introduce:

- Propshaft migration for the dashboard or Super Admin.
- Solid Queue, Solid Cache, or Solid Cable.
- Sidekiq 8.
- A different Ruby version.
- Authentication architecture replacement.
- Redis topology changes.
- Unrelated Rails generator changes.

Each may be valuable later, but coupling them to the framework upgrade removes the ability to attribute and safely roll back failures.

## Final recommendation

Start the work now with Rails 8.1.3 as the declared target and Rails 7.2.3.1/8.0.5 as required deployable checkpoints. Rails 7.2 is too close to security end of life to justify a separate long-term upgrade project, but skipping it would discard the exact deprecation and isolation boundary Rails provides.

The critical path is not the 31 mechanical enum edits. It is:

1. Azure Active Storage support.
2. The Rails-constrained Administrate search-field dependency.
3. Encrypted-data and serialized-format compatibility across rolling deploys.
4. Administrate 1 plus explicit Sprockets ownership.
5. Job timing and Sidekiq adapter verification.

Once those are settled, the remaining Rails 8 code changes are bounded and the isolated Rails 8.1 boot proves the application can reach the target without a broad rewrite.
