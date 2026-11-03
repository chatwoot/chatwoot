# Chatwoot Development Guidelines

`CLAUDE.md` is a symlink to this file. Keep shared instructions here.

## Build, Test, and Lint

- **Ruby setup**: Use the version in `.ruby-version` through `rbenv`. Before Ruby commands, run `eval "$(rbenv init -)"`; use `bundle exec` for Rails, RSpec, and RuboCop.
- **Install dependencies**: `bundle install && pnpm install`
- **Run development**: `pnpm dev` or `overmind start -f Procfile.dev`
- **Lint Ruby**: `bundle exec rubocop <changed Ruby files>`; use autocorrection only when intended and inspect its diff.
- **Lint JS/Vue**: `pnpm exec eslint <changed JS/Vue files>`; `pnpm eslint` checks the full frontend.
- **Test Ruby**: `bundle exec rspec spec/path/to/file_spec.rb` (append `:LINE_NUMBER` for one example).
- **Test JS**: `pnpm test <test path>` or `pnpm test:watch`.
- **Seed data**: `bundle exec rails db:seed` for minimal data; `bundle exec rails search:setup_test_data` for search/load scenarios. For richer account data, Super Admin → Accounts → Seed enqueues `Internal::SeedAccountJob`, which uses `Seeders::AccountSeeder`.

## Readability and Scope

- Prefer the smallest production-ready change that solves the current problem. Build for supported callers and realistic production workloads; do not add speculative abstractions, guards, fallbacks, retries, or one-in-a-million edge cases.
- Optimize for understanding on the first read. Use descriptive names, explicit control flow, and ordinary multiline methods/functions. Avoid Ruby endless methods (`def value = expression`), semicolon-packed bodies, and compressed JavaScript functions; do not shorten code merely to fit line or class limits.
- Use existing dependencies, client libraries, and shared utilities before implementing protocol, auth, signing, parsing, or request plumbing yourself.
- Extract helpers or split files/classes when they clarify responsibilities or remove meaningful complexity. Avoid one-use helpers that only rename an obvious expression.
- Follow RuboCop and ESLint. Refactor responsibilities when size/complexity limits expose a problem; do not disable cops or exclude files to avoid that work. Any unavoidable suppression must be narrowly scoped and explain why the compliant approach is unsuitable.
- Do not introduce `Thread.new` or monotonic-clock APIs such as `Process.clock_gettime(Process::CLOCK_MONOTONIC)` unless necessary and explicitly approved by the user. Prefer existing job/concurrency patterns.
- Remove dead code and superseded implementations; do not keep alternate versions or commented-out logic.

## Rails, Validation, and Database Queries

- Follow RuboCop (including the 150-character line limit). Use compact namespace declarations such as `class Foo::Bar`, while keeping method bodies multiline.
- Use idiomatic model methods, associations, scopes, and named route helpers. Keep reusable queries and relationship traversal in models/scopes; return an ActiveRecord relation when callers need further filtering or ordering.
- Controllers coordinate requests and responses. Keep request-specific URL generation and presentation in controllers or view helpers.
- Enforce stored-value rules in model validations or existing JSON/JSONB schema validators so all ordinary write paths share them. Do not duplicate the same check in controllers. Validate transient filters, lookups, and service arguments at the request boundary before queries/services use them. Use strong params and existing errors so invalid input returns `422 Unprocessable Entity`.
- Accept only documented input types, shapes, and values. Fix malformed official clients instead of adding compatibility coercions.
- Prefer model-level constraints, associations, and callbacks over new database constraints. Add a database constraint only for a demonstrated integrity need that code-level enforcement cannot adequately cover. For foreign keys, check deletion behavior and production migration/locking risks; existing constraints are not a reason to add more.
- Write application queries, joins, and data migrations with ActiveRecord and Arel. Do not add raw SQL strings, SQL heredocs, `execute`, or raw SQL hidden inside `Arel.sql` to production paths. Keep raw SQL confined to temporary diagnostic or operational scripts; use Rails migration APIs for schema changes.
- Design queries and joins for production scale: use tenant-scoped predicates, appropriate indexes and column order, bounded results/batches, and preloading where needed. Check join cardinality, duplicate rows, N+1 queries, and costly counts/sorts. For material query changes, inspect generated SQL and representative query plans; a small fixture database is not performance evidence.
- Generate migrations with `bundle exec rails g migration <Name>` so their versions are real timestamps. Do not hand-write or round migration versions.
- Enforce eligibility/exclusivity at the earliest shared entry point. Add another guard only for a real independent path that bypasses it.
- Fail visibly for invalid required configuration or impossible setup states. Use required reads (`find`, `find_by!`, required hash keys) for locked/internal configuration; do not silently skip behavior. Add checks only when they meaningfully change behavior, and use existing custom exceptions in `lib/custom_exceptions/` where appropriate.

## Tests and Validation

- Add or update meaningful tests for customer-facing behavior and underlying model, service, job, API, or state changes. Cover the intended success path and relevant failures, permissions, and lifecycle transitions; use enough coverage to establish the behavior, not just the implementation shape.
- For a bug fix, add a focused regression that fails for the original behavior and passes with the fix. For core/Enterprise changes, cover the affected edition paths.
- Avoid tests that merely repeat migration declarations, configuration, formatting, or other mechanical changes. Test migration/backfill transformations when they carry meaningful data behavior, and verify operational migration safety separately.
- Run focused specs and linters after code changes. For documentation-only changes, check formatting, links, and the diff. Report checks actually run and any remaining validation gaps.
- Prefer `let` values and direct per-example setup; introduce custom spec helpers only when they remove meaningful repetition or complexity.
- Use `with_modified_env` rather than stubbing `ENV`. In parallel/reloading specs, prefer comparing `error.class.name` over constant class equality when asserting raised errors.
- Keep review-only work read-only unless changes are requested. Use existing specs or temporary probes and report missing regression coverage.

## Implementation and Review Safety

- Name the affected behavior and trace entry points, source of truth, side effects, and consumers across APIs, jobs, supported clients, and Enterprise overlays.
- Inspect unchanged helpers reached by new callers or defaults. Treat valid `false` configuration distinctly from missing values; check repeated reads, cache invalidation, and disabled-feature work.
- Bound database/Redis work, fanout, retries, scheduled jobs, and lock/connection hold time at representative production scale. Green unit tests or the existence of an index do not establish capacity.
- Exercise relevant sequences such as failure → success → failure, new events while quota-held, clock boundaries, and rollback with existing state. Assert exact required values, not merely that something changed.
- Carry deferred concerns through stacked PRs and review the assembled feature when activated. Include scheduled jobs, cached values, and persisted state in rollback/recovery reasoning.
- Review the exact PR head and complete relevant discussion; recheck affected findings if the head changes. A resolved thread is not proof that the failure was fixed.
- Give material findings a failure scenario, disposition, and evidence. Keep the approval/verdict consistent with open blockers. An accepted risk needs an explicit owner, rationale, mitigation, and follow-up or activation condition.
- Read the relevant sections of [Production Reliability](docs/production-reliability.md) when changes affect hot paths, queries, caches, fanout, quotas/retries, recovery, middleware/provider boundaries, or rollout state. Apply checks to actual risks; small changes do not need every protocol.

## Frontend and Styling

- Use Vue Composition API with `<script setup>` at the top, PascalCase component names, camelCase events, and `defineProps` declarations with appropriate types/validation.
- Use existing design-system utilities and shared composables. Use `components-next/` for message bubbles; older message-bubble components are being deprecated.
- Use Tailwind utilities; do not introduce custom/scoped CSS or inline styles. Refer to `tailwind.config.js` for colors and use existing typography utilities.
- Use logical utilities (`ms`, `me`, `start`, `end`) for direction-aware layouts. Use `rem` for arbitrary CSS dimensions, preserving native numeric values required by chart/SVG APIs.
- Extract repeated or domain-specific strings, thresholds, colors, and durations into named constants. Use shared request-cancellation utilities instead of local `AbortController` logic.

## Translations and Branding

- Use i18n for user-facing strings; no bare strings in templates. For product/source-string changes, update only backend `en.yml` and frontend `en.json`; Crowdin and the community handle other locales.
- Crowdin-generated sync PRs may update non-English files; do not flag that alone. Verify that product/brand names, OAuth scopes, API values, and other machine-readable identifiers remain unchanged unless an official localized form exists. Keep newly introduced protected terms in the Crowdin glossary as non-translatable.
- For UI strings that should adapt to branded/self-hosted installations, use `replaceInstallationName` from `shared/composables/useBranding` instead of hardcoded Chatwoot copy.

## Enterprise Compatibility

- Before changing core logic or public APIs, search both `app/` and `enterprise/` for related implementations. Keep request/response contracts compatible and mirror shared-code renames/moves where needed.
- Extend existing OSS functionality for Enterprise through modules (`prepend_mod_with` / `include_mod_with`), hooks, flags, or configuration instead of hardcoding plan/instance-specific behavior in OSS. Put Enterprise-exclusive functionality under `enterprise/`.
- For new endpoints, services, and models, consider the extension points Enterprise needs to avoid hard forks. Put Enterprise specs under `spec/enterprise`, mirroring OSS layout where applicable.
- Follow the [Enterprise development handbook](https://chatwoot.help/hc/handbook/articles/developing-enterprise-edition-features-38).

## AI Models

- Before adding/changing an OpenAI model, check the [deprecations page](https://developers.openai.com/api/docs/deprecations). Do not choose a model with a shutdown date; use its recommended replacement. Select models through `config/llm.yml` and `Llm::FeatureRouter`, not hardcoded names.

## Worktrees

- Use a separate worktree and branch per task; reuse the task's existing worktree when available.
- Keep Codex-specific local setup under `.codex/` and use `Procfile.worktree` for process orchestration.
- The setup in `.codex/environments/environment.toml` should generate per-worktree database names, ports, and Redis DB indexes. Use a distinct Overmind socket/title for each worktree.

## Commits and Pull Requests

- Prefer Conventional Commits: `type(scope): subject` (scope optional). Do not reference Claude in commit messages.
- Every PR must link an associated Linear ticket. Confirm an existing ticket or create the appropriate ticket before opening the PR; do not invent issue references.
- For medium/large features (for example, a new workflow or a change spanning several layers), link the design/PRD/implementation artifact in both the Linear ticket and the PR. Keep those links and the description aligned with the final scope.
- Start the PR description with a short, user-facing explanation of the change. Add a `Closes` section with the Linear ticket and any relevant GitHub issues.
- Follow applicable repository-template sections. For features, include product/UX `How to test` steps; for bug fixes, include `How to reproduce` when useful. Add `What changed` only when it helps review.
- Do not add a `How this was tested` section listing specs/commands; report automated validation in the task handoff instead.
