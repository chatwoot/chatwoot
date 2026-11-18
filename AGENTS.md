# Chatwoot Development Guidelines

`CLAUDE.md` is a symlink to this file. Keep shared, repository-wide instructions here and detailed procedures in linked docs. Add nested `AGENTS.md` files only for subtree-specific differences; avoid duplicating root rules.

## Build, Test, and Lint

- **Ruby setup**: Use the version in `.ruby-version` through `rbenv`. Before Ruby commands, run `eval "$(rbenv init -)"`; use `bundle exec` for Rails, RSpec, and RuboCop.
- **Install dependencies**: `bundle install && pnpm install`
- **Run development**: `pnpm dev` or `overmind start -f Procfile.dev`
- **Lint Ruby**: `bundle exec rubocop <changed Ruby files>`; use autocorrection only when intended and inspect its diff.
- **Lint JS/Vue**: `pnpm exec eslint <changed JS/Vue files>`; `pnpm eslint` checks the full frontend.
- **Test Ruby**: `bundle exec rspec spec/path/to/file_spec.rb` (append `:LINE_NUMBER` for one example).
- **Test JS**: `pnpm test <test path>` or `pnpm test:watch`. Pass the file directly (`pnpm test <file>`), never `pnpm test -- <file>`.
- **Seed data**: `bundle exec rails db:seed` for minimal data; `bundle exec rails search:setup_test_data` for search/load scenarios. For richer account data, Super Admin → Accounts → Seed enqueues `Internal::SeedAccountJob`, which uses `Seeders::AccountSeeder`.

## Readability and Scope

- Prefer the smallest production-ready change that solves the current problem. Build for supported callers and realistic production workloads; do not add speculative abstractions, guards, fallbacks, retries, or one-in-a-million edge cases.
- Optimize for understanding on the first read. Use descriptive names, explicit control flow, and ordinary multiline methods/functions. Avoid Ruby endless methods (`def value = expression`), semicolon-packed bodies, and compressed JavaScript functions; do not shorten code merely to fit line or class limits.
- Extract helpers or split files/classes when they clarify responsibilities or remove meaningful complexity. Avoid one-use helpers that only rename an obvious expression.
- Follow RuboCop and ESLint. Refactor responsibilities when size/complexity limits expose a problem; do not disable cops or exclude files to avoid that work. Any unavoidable suppression must be narrowly scoped and explain why the compliant approach is unsuitable.
- Do not introduce `Thread.new` or monotonic-clock APIs such as `Process.clock_gettime(Process::CLOCK_MONOTONIC)` unless necessary and explicitly approved by the user. Prefer existing job/concurrency patterns.
- Remove dead code and superseded implementations; do not keep alternate versions or commented-out logic.

## Dependencies

- Add an npm package, Ruby gem, or other dependency only when necessary. Reuse existing maintained dependencies, standard-library capabilities, or shared utilities first; explain why they or a small, maintainable implementation cannot reasonably meet the requirement.
- Before adding a dependency, verify current upstream maintenance, release activity, community/support health, and security advisories and patch responsiveness. Do not introduce abandoned or unmaintained packages. Prefer a small, readable implementation for behavior we can reasonably own; continue to use maintained, proven libraries for protocol, authentication, and signing rather than hand-rolling them.
- Before upgrading, read release notes, changelogs, and migration guides across the full version jump. Audit every call site, wrapper, configuration, and indirect integration, including framework usage and affected OSS/Enterprise paths, for changed APIs, defaults, error behavior, and deprecations. Update affected code and tests together.
- Verify runtime/framework, peer, and transitive dependency compatibility; inspect manifest and lockfile changes for unintended upgrades. Run focused behavior and integration checks across all affected surfaces to establish compatibility. A successful install or a minor/patch version label is not sufficient evidence that an upgrade is safe.

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
- For new or changed functionality, map and test every affected surface and consumer, including dashboard, widget/SDKs, APIs, jobs, integrations, real-time events, and OSS/Enterprise paths where relevant. Include shared behavior outside the edited files. Explicitly check whether Super Admin screens, configuration, permissions, or management actions need corresponding changes, and implement and test them when required.
- For a bug fix, add a focused regression that fails for the original behavior and passes with the fix. For core/Enterprise changes, cover the affected edition paths.
- Avoid tests that merely repeat migration declarations, configuration, formatting, or other mechanical changes. Test migration/backfill transformations when they carry meaningful data behavior, and verify operational migration safety separately.
- Run focused specs and linters after code changes. For documentation-only changes, check formatting, links, and the diff. Report checks actually run and any remaining validation gaps.
- Prefer `let` values and direct per-example setup; introduce custom spec helpers only when they remove meaningful repetition or complexity.
- Use `with_modified_env` rather than stubbing `ENV`. In parallel/reloading specs, prefer comparing `error.class.name` over constant class equality when asserting raised errors.
- Keep review-only work read-only unless changes are requested. Use existing specs or temporary probes and report missing regression coverage.
- A spec must cover behavior that can actually break. Drop the ones that only restate the implementation or exist as documentation: a redundant spec costs CI time and gets rewritten with the code it mirrors.
- A backend change usually has a frontend half, and the reverse. Check for the counterpart before calling the change done.
- Specs tagged `:redis_streams` talk to a real Redis (the app's own pools are MockRedis in tests, which implements no stream, blocking or scripting command). They need `REDIS_URL` to point at a running server; CI already provides one.

## Code Review Rules

- Apply these checks during implementation and PR review. Report concrete regressions on supported paths, with the trigger, impact, and evidence; distinguish intended behavior from defects. Leave formatting and lint-only findings to CI.
- Name the affected behavior and trace entry points, source of truth, side effects, and consumers across APIs, jobs, supported clients, and Enterprise overlays.
- Inspect unchanged helpers reached by new callers or defaults. Treat valid `false` configuration distinctly from missing values; check repeated reads, cache invalidation, and disabled-feature work.
- Bound database/Redis work, fanout, retries, scheduled jobs, and lock/connection hold time at representative production scale. Green unit tests or the existence of an index do not establish capacity.
- Exercise relevant sequences such as failure → success → failure, new events while quota-held, clock boundaries, and rollback with existing state. Assert exact required values, not merely that something changed.
- Carry deferred concerns through stacked PRs and review the assembled feature when activated. Include scheduled jobs, cached values, and persisted state in rollback/recovery reasoning.
- Review the exact PR head and complete relevant discussion; recheck affected findings if the head changes. A resolved thread is not proof that the failure was fixed.
- Give material findings a failure scenario, disposition, and evidence. Keep the approval/verdict consistent with open blockers. An accepted risk needs an explicit owner, rationale, mitigation, and follow-up or activation condition.
- Read the relevant sections of [Production Reliability](docs/production-reliability.md) when changes affect hot paths, queries, caches, fanout, quotas/retries, recovery, middleware/provider boundaries, or rollout state. Apply checks to actual risks; small changes do not need every protocol.

## Git Remotes & PRs

This repo is a fork of `chatwoot/chatwoot`. Remotes and their roles:

- **origin** → `fazer-ai/chatwoot` (our CE fork). Feature/fix PRs from `main` target this repo.
- **chatwoot-pro** → `fazer-ai/chatwoot-pro` (Pro fork). Its trunk is `main` there (`chatwoot-pro-main` is only the local branch name in the shared checkout), it receives CE work as a merge of CE's `main` and no PR of its own, and it carries the `vX.Y.Z-fazer-ai-pro.N` tags/releases. **Never open a PR on the Pro repo to port a change that is landing in CE** — see Pro repo gotchas.
- **upstream** → `chatwoot/chatwoot` (Chatwoot OSS). Read-only / sync only (merge `develop` via the `sync-fork` skill). **Never open a PR against upstream.**

⚠️ **`gh` fork gotcha:** because `origin` is a fork of `chatwoot/chatwoot`, `gh` resolves the PR base repo to the **parent (upstream)** when no default is set — so `gh pr create` silently opens the PR on `chatwoot/chatwoot`. Pin the base repo once per clone:

```sh
gh repo set-default fazer-ai/chatwoot   # writes remote.origin.gh-resolved=base
```

When unsure, be explicit: `gh pr create --repo fazer-ai/chatwoot` (for Pro PRs, `--repo fazer-ai/chatwoot-pro`).

### Merge strategy

- Default for every PR: `gh pr merge <n> --squash --admin`.
- **Exception 1 — upstream sync PRs (`chore/merge-upstream-X.Y.Z`): merge with `--merge`, never `--squash`.** A squash drops the merge commit's second parent, so the upstream tag stops being an ancestor of `main`: GitHub reports `main` as permanently "N commits behind chatwoot:develop" (the count only grows), and the next sync bases on a stale tag and replays a whole version's diff as conflicts. After merging a sync PR, `git rev-list --count main..vX.Y.Z` must be 0 — when it isn't, see the `sync-fork` skill's **Repairing a squashed sync** recipe.
- **Exception 2 — a PR whose branch Pro's trunk already contains: merge with `--merge`.** Same root cause pointing the other way. The squash lands a commit with no ancestry to the branch Pro already contains, so the next CE → Pro merge treats the whole delivery as new content and hands it back as conflicts. Measured on the i18n stack (#364/#365) on 2026-08-17: squash → 18 conflicting files in the CE → Pro sync, squash plus redoing the work on Pro → 8, merge commit → 0.
- Before merging a delivery Pro already has, measure instead of guessing — in a throwaway worktree, run each candidate route as `git merge --no-commit --no-ff <ref>` and count `git diff --name-only --diff-filter=U`.
- **Stacked PRs:** after the lower PR is squashed, the upper one needs `git rebase --onto origin/main <lower-branch> <upper-branch>` before it can merge. The squash leaves the upper PR's merge base at the original divergence point, so GitHub replays the lower PR's whole diff over the squash and conflicts even when the two trees are identical.

### Pro repo gotchas

- **A change reaches Pro through the CE → Pro sync, never through a port of its own.** No cherry-pick, no parallel PR opened on the Pro repo, however small the diff and however tempting the Pro-only CI is. Every CE delivery in Pro's history arrived as `Merge branch 'main' into <pro trunk>` (flow B of the `sync-fork` skill), and that merge is what makes the CE commit an ancestor of Pro. A cherry-picked copy is a second commit carrying the same diff with no ancestry, so the next sync replays those hunks and hands them back as conflicts: measured at 18 conflicting files on the i18n stack (#364/#365). "This also has to be in Pro" says where the change ends up, not that it is delivered twice.
- **Pro's trunk is `main`.** The local branch in the shared checkout is conventionally called `chatwoot-pro-main` so it does not collide with CE's `main`, and the push is `git push chatwoot-pro HEAD:main`. Pushing that local branch **by name** is what created a stray remote `chatwoot-pro-main` in 2026-08, which then collected every push for a month while remote `main` went stale; that branch is gone and must not come back.
- **Pro is where `spec/enterprise` runs in CI.** `run_ee_spec.yml` exists in Pro and not in CE, and it runs `spec/enterprise` on pull requests. CE's `run_foss_spec.yml` deletes `enterprise` and `spec/enterprise` before its suite, so a CE change that Enterprise code depends on has no CE CI evidence for that side: run `spec/enterprise` and `spec/lint/enterprise_isolation_spec.rb` locally before merging in CE, and let the Pro run after the sync be the workflow that measures them.

## CI: the CE spec workflow

- `run_foss_spec.yml` runs the whole suite on every push to `main` and on tags. On a branch, nothing runs until you dispatch it, and the dispatch default is **affected mode**: the specs the branch's diff against `main` maps to (`app/x/y.rb` and `lib/x/y.rb` to every `y_spec.rb`, plus the spec files themselves), in one shard per 40 files. Shared files (Gemfile, `config/` other than routes and locales, `spec/support`, the helpers, base classes, a modified factory) fall back to the full suite on their own.
- `gh workflow run run_foss_spec.yml --ref <branch>` runs affected mode; add `-f full=true` for the whole suite (mandatory before merging an upstream sync, see the `sync-fork` skill) or `-f specs="spec/a_spec.rb spec/b_spec.rb"` for an explicit list. Affected mode is a pre-check, not the gate: the push to `main` runs everything.
- Do not re-dispatch the full suite after every fix. Between 2026-08-12 and 2026-09-05 this workflow was dispatched 191 times by hand (23 on one branch), each run costing ~75 billed Blacksmith minutes; that is the whole reason the affected mode exists.

## Frontend and Styling

- Use Vue Composition API with `<script setup>` at the top, PascalCase component names, camelCase events, and `defineProps` declarations with appropriate types/validation.
- Use existing design-system utilities and shared composables. Use `components-next/` for message bubbles; older message-bubble components are being deprecated.
- Use Tailwind utilities; do not introduce custom/scoped CSS or inline styles. Refer to `tailwind.config.js` for colors and use existing typography utilities.
- Use logical utilities (`ms`, `me`, `start`, `end`) for direction-aware layouts. Use `rem` for arbitrary CSS dimensions, preserving native numeric values required by chart/SVG APIs.
- Extract repeated or domain-specific strings, thresholds, colors, and durations into named constants. Use shared request-cancellation utilities instead of local `AbortController` logic.
- **Conversation ids: the dashboard knows a conversation by its `display_id`.** `Conversations::EventDataPresenter#push_data` sends `id: display_id`, so `allConversations[].id`, `currentChat.id`, the routes and every `/conversations/:id` endpoint use the display id. Other payloads that embed a conversation do not always follow that: the kanban task's `conversations[]` has the internal id in `id` next to `display_id`, and the WhatsApp `voice_call.*` events from `Call#broadcast_voice_call_event`, `Whatsapp::CallService` and `Whatsapp::CallPermissionReplyService` still send the internal id as `conversation_id` (nothing reads it there today; the ones from `Whatsapp::IncomingCallService`, which the call widget does read, carry the display id since #735). Before you match an embedded id against the store, a route or the API, read what the producer actually sends. And write the spec with an internal id that differs from the display id: with `{ id: 10 }` and nothing else, the wrong key passes. This is not hypothetical. In 2026-09 the kanban cable handlers matched on `conversations[].id` and put one clinic patient's card on another patient's conversation (fazer-ai/chatwoot-pro#90), and the specs that should have caught it used exactly such a payload.

## Translations and Branding

- **Translations**: the fork's strings live in their own tree, never inside upstream's locale files. See **Fork translations** below.
- Use i18n for user-facing strings; no bare strings in templates. For product/source-string changes, update only backend `en.yml` and frontend `en.json`; Crowdin and the community handle other locales.
- Crowdin-generated sync PRs may update non-English files; do not flag that alone. Verify that product/brand names, OAuth scopes, API values, and other machine-readable identifiers remain unchanged unless an official localized form exists. Keep newly introduced protected terms in the Crowdin glossary as non-translatable.
- For UI strings that should adapt to branded/self-hosted installations, use `replaceInstallationName` from `shared/composables/useBranding` instead of hardcoded Chatwoot copy.
- The brand is always written `fazer.ai`, lowercase and with the dot. Never `Fazer.ai`, `FAZER.AI` or `fazer-ai` in prose, comments, or user-facing copy. The only exceptions are slugs where a dot is illegal (the `fazer-ai` GitHub org, the `@fazer-ai-pro` npm scope), env vars (`FAZER_AI_HUB_URL`), and code identifiers following the language's convention (`fazerAi`, `FazerAi`, `fazer_ai`).

## Enterprise Compatibility

- Chatwoot has an Enterprise overlay under `enterprise/` that extends/overrides OSS code.
- **`enterprise/` and `spec/enterprise/` are upstream's and stay byte-identical to the release in `VERSION_CW`.** The fork does not change Enterprise behavior at all: not by editing those files, and not from outside them either (no overlay directory, no reopened Enterprise class or module, no `prepend`, `include` or `class_eval` aimed at an Enterprise constant, no CE module prepended over a method Enterprise defines). Using or distributing modified Enterprise code requires a Chatwoot Enterprise subscription, which is why. `bin/validate_enterprise_parity` checks the files, `bin/validate_enterprise_isolation` checks the patches statically (both in CI and in the pre-commit hook), `spec/lint/enterprise_isolation_spec.rb` adds the runtime check with `enterprise/` loaded, and `.claude/settings.json` denies agent edits under `enterprise/`.
- **Code under `enterprise/` does not run on CE installs.** No published image carries `enterprise/` in its final layers: `docker/Dockerfile` builds the assets with the official tree for `VERSION_CW` and drops it, and the entrypoint fetches it at boot only when the container sets `CW_EDITION=ee` (there is no separate `-ee` image), checked against the hash pinned at build time (`docker/entrypoints/helpers/enterprise.sh`). The build's intermediate stages do hold the official tree, so a build cache pushed to a registry must export only the final image's layers (`mode=min`), never `mode=max`, or the cache distributes `enterprise/`. A checkout run from source loads `enterprise/` whenever the directory is there, with or without `CW_EDITION`. Premium features such as `channel_voice` stay off on the community pricing plan, and the plan comes only from Chatwoot's official hub: the fazer.ai hub that Pro's `fazer_ai/` layer talks to licenses Pro and provides no Chatwoot plan. So a defect in `enterprise/` only shows up on an install with a Chatwoot Enterprise plan, and it is upstream's to fix: the fork either changes the CE code the Enterprise path goes through (when the defect is really there) or reports it upstream and waits for the release that fixes it. An issue about `enterprise/` code must say that it only affects installs with `CW_EDITION=ee` and a Chatwoot plan, and which feature has to be on for it to happen, so nobody triages it as affecting every install.
- When you add or modify core functionality, always check for corresponding files in `enterprise/` and keep behavior compatible with them as they are.
- Follow the Enterprise development practices documented here:
  - https://chatwoot.help/hc/handbook/articles/developing-enterprise-edition-features-38

Practical checklist for any change impacting core logic or public APIs
- Search for related files in both trees before editing (e.g., `rg -n "FooService|ControllerName|ModelName" app enterprise`).
- If adding new endpoints, services, or models, keep upstream's extension points (`prepend_mod_with`, `include_mod_with`) where upstream has them, so Enterprise keeps refining the class the way it expects. Never put a module of ours in front of Enterprise's.
- Avoid hardcoding instance- or plan-specific behavior in OSS; prefer configuration, feature flags, or extension points consumed by Enterprise.
- Keep request/response contracts stable across OSS and Enterprise; update both sets of routes/controllers when introducing new APIs.
- When a CE change has to reach an action Enterprise also refines, make it in the CE class itself (a call from the CE method, as `AgentBotAssignment::DropdownOffersNoForeignBot` is called from `Api::V1::Accounts::AssignableAgentsController#index`), never as a module prepended over it.
- Tests: `spec/enterprise` is upstream's. The fork adds no Enterprise specs of its own, because it has no Enterprise code of its own.
- An Enterprise-only behavior the fork wants is not built on top of Enterprise. Either it belongs in CE for every install, or it is not built.

## AI Models

- Before adding/changing an OpenAI model, check the [deprecations page](https://developers.openai.com/api/docs/deprecations). Do not choose a model with a shutdown date; use its recommended replacement. Select models through `config/llm.yml` and `Llm::FeatureRouter`, not hardcoded names.

## Fork translations

Upstream's locale files are byte-identical to the Chatwoot release we track. **Never add or edit a key inside an upstream locale tree** — `app/javascript/dashboard/i18n/locale/`, `app/javascript/survey/i18n/locale/`, or `config/locales/<locale>.yml`. CI fails if you do, and the next upstream sync would conflict on every string we own.

We ship our features in **en, pt_BR and es**, and every key must exist in all three: `check` fails when a key present in `en` is missing from another language we ship. Upstream keeps translating the other ~55 languages, and our keys fall back to `en` there. Everything the fork translates lives in two places:

- Frontend, dashboard → `app/javascript/dashboard/i18n/fazer-ai/locale/<locale>/*.json`
- Frontend, survey → `app/javascript/survey/i18n/fazer-ai/locale/<locale>.json` (one file, not a folder: it is a single small namespace)
- Backend → `config/locales/fazer_ai.<locale>.yml` (and `fazer_ai.mailers.<locale>.yml` for the Chatwoot mailer copy upstream hardcodes in ERB)

Each frontend bundle has its own upstream tree and its own overlay, merged by that bundle's `i18n/index.js`; the merging itself lives in `shared/helpers/forkTranslations`. `check`, `drift` and `scaffold` cover every tree listed in `FE_TREES`, so a new bundle means one entry there.

Both are deep-merged on top of upstream's: the frontend in `i18n/index.js` via `withForkMessages`, the backend by Rails, which already loads every `config/locales/*.yml`. No registration step — files are picked up by directory scan, which is also why CE → Pro merges don't conflict here.

**Which file does a key go in?**

- A namespace that is entirely ours gets its own file: `kanban.json`, `internalChat.json`, `groups.json`, `scheduledMessages.json`, `fazerAi.json`.
- A key we add *inside* an upstream namespace goes in a file named after the upstream file it extends: `INBOX_MGMT.ADD.WHATSAPP.*` → `fazer-ai/locale/en/inboxMgmt.json`.
- Replacing an upstream string goes in `overrides.json`, and only there. Overrides apply per language: overriding in `en` does not change `es`, and they are exempt from the coverage rule, since fixing upstream's English says nothing about whether its Spanish needs fixing too.
- An override is for copy the fork's product needs to say differently (a behavior the fork changed, a provider the fork adds, branding). It is not for fixing upstream's translations: a typo, a wrong word or an awkward phrase in an upstream string is upstream's, and the fix is a suggestion on Chatwoot's Crowdin project, not a fork key. An override never goes away on its own, and it silently hides every later upstream change to that key, so a typo fixed here outlives the fix upstream and drifts from the string it replaced.

**Adding a language**: `ruby scripts/i18n/fork_translations.rb scaffold <locale>` copies the `en` tree as a starting point, so the new language starts complete (in English) and the coverage check stays green while you translate the values in place. The `en` fallback is still there (vue-i18n's `fallbackLocale`, `config.i18n.fallbacks` in production), but for the languages we ship it is a safety net, not a plan: leaving a key untranslated fails CI.

**Checks**: `ruby scripts/i18n/fork_translations.rb check` enforces the boundaries and full coverage in every language present under `fazer-ai/locale/`. `drift` compares upstream's files against the tracked release and needs that tag fetched first. Both run in `.github/workflows/fazer_ai_i18n.yml`.

**On upstream sync**: bump `UPSTREAM_BASE` in `scripts/i18n/fork_translations.rb` to the new release, then run `drift`. If it fails, upstream changed a file we also changed and the resolution belongs in our tree, not theirs.

## Worktree Workflow

Use a separate git worktree + branch per task so multiple instances run in parallel, fully isolated.

A new worktree only materializes **versioned** files — `git worktree add` does NOT copy the gitignored, per-worktree setup: `.env`, `.env.test`, `Procfile.worktree`, `.bundle/config`, and `CLAUDE.local.md`. Generate these per worktree with non-colliding values:

- **Ports**: distinct Rails (`PORT`) and Vite (`VITE_RUBY_PORT`).
- **Postgres**: a dedicated `POSTGRES_DATABASE`, separate for dev and test — `.env.test` overrides it so specs never touch the dev DB (dotenv-rails loads `.env.test` before `.env` under `RAILS_ENV=test`).
- **Redis**: a distinct logical DB index (dev and test) via `REDIS_URL`.
- **Hostname**: a distinct `*.localhost` host in `FRONTEND_URL` (macOS resolves `*.localhost` natively) so session cookies don't clash between worktrees.
- **Overmind**: its own `OVERMIND_SOCKET`; start with `overmind start -f Procfile.worktree`.

Automate this with your worktree tool's create hook (e.g. worktrunk's `pre-start`): generate the local files from a shared master `.env`, derive the values above deterministically from the branch name, run `bundle install && pnpm install`, then create the DBs (`rails db:prepare` for dev; `RAILS_ENV=test rails db:create db:schema:load` for test). Keep DB setup non-fatal so a broken seed doesn't abort worktree creation. The actual per-worktree URL/port/DB/Redis values land in that worktree's `CLAUDE.local.md`.

## Release Notes

- Every GitHub release cut from this repo must include a `user-notes` block per shipped language (en, pt-BR, es) in the release body, written for non-technical end users.
- Before running `gh release create`, `gh release edit`, the `release` skill from `fazer-ai-tools`, or any flow that touches a release body (including retroactive backfills), invoke the `release-user-notes` skill at `.claude/skills/release-user-notes/SKILL.md` to draft and validate the blocks.

## Cutting a release

**A published image comes from a cut release, and from nothing else.** The publish workflows fire on `release: [released]`, so cutting the release is what builds and pushes the image, including `:latest`. `workflow_dispatch` is there to validate the workflow itself with `-f push=false`; dispatching it with `push=true` is the one way to put an image in front of users without a release, and it must not be used for that, no matter how much faster it looks when you only want an image for a test. Need an image in production? Cut the release.

The rest of this section exists because that rule was broken once, and the damage landed two days later.

- **A tag can exist with no release attached, so never derive the next number from `gh release list`.** Ask the tags instead, and require an empty answer: `git ls-remote --tags <remote> "<tag>"`.
- **`gh release create --target <sha>` silently ignores `--target` when the tag already exists.** The API documents `target_commitish` as unused in that case, so the command succeeds, prints the release URL, and attaches the release to whatever commit the old tag names. The publish workflow then builds that tree.
- **Dereference the tag after cutting and compare it with what you aimed at**, before trusting anything built from it:

  ```sh
  git fetch <remote> "refs/tags/<tag>:refs/tags/<tag>" --force
  git rev-parse "<tag>^{commit}"   # must equal the SHA passed to --target
  ```

- Measured on `v4.17.0-fazer-ai-pro.133`: on 2026-09-10 the tag was pushed and the publish dispatched with `-f push=true`, to get a Pro image for a live test without cutting a release. `gh release list` therefore still showed `.132` as the latest. On 09-12 the release for the merge of `v4.17.0-fazer-ai.113` was cut with that same number, `--target` was dropped on the floor, and the two-day-old tree shipped to production under the new number, with the new number stamped inside it.

## Commits and Pull Requests

- Prefer Conventional Commits: `type(scope): subject` (scope optional).
- Start the PR description with a short, user-facing paragraph describing the product change. Add a `Closes` section with relevant issue links (GitHub, Linear, etc.).
- For feature PRs, add `How to test` from a product/UX standpoint. For bugfix PRs, use `How to reproduce` when helpful. Optionally add a `What changed` section for implementation highlights.
- Do not add a `How this was tested` section listing specs/commands; report automated validation in the task handoff instead.

## Account-level toggles: do NOT extend `config/features.yml`

- Since upstream 4.16.0, account feature flags are multi-column: `Featurable::FEATURE_FLAG_COLUMNS` maps `config/features.yml` entries to `accounts.feature_flags` (default) or `accounts.feature_flags_ext_1` via each entry's `column:` key, with a hard cap of 63 flags per bigint column enforced at boot (`validate_feature_count!` raises). The default column is FULL (63/63) — any new upstream-style flag MUST set `column: feature_flags_ext_1` and be appended at the end.
- Bit positions are persisted per column: never reorder or remove existing entries, and never change an existing feature's `column` after release.
- `chatwoot-pro-main` inserts `kanban` and `internal_chat_pro` mid-list in the DEFAULT column. With the 63-per-column boot validation, the next CE→Pro merge will raise `ArgumentError` at boot until Pro's extra flags move to `feature_flags_ext_1` — and moving them changes their persisted bit positions on Pro installs, so that migration must remap existing account values.
- Local DB pitfall: bit positions differ between `main` and `chatwoot-pro-main` because of the kanban/internal_chat_pro insertion. The same bit set on one branch maps to a different feature on the other. Use separate dev DBs per branch or reset `feature_flags` when switching.

For NEW account-level toggles, prefer the `settings` jsonb column instead of `feature_flags`:

1. Declare a `store_accessor :settings, :your_toggle` in `app/models/account.rb` and override the writer to cast (`super(ActiveModel::Type::Boolean.new.cast(value))` for booleans) so JSON schema validation accepts the value.
2. Add the key to `SETTINGS_PARAMS_SCHEMA` in `app/models/concerns/account_settings_schema.rb`.
3. Register it as a `Field::Boolean` (or appropriate field) in `app/dashboards/account_dashboard.rb` (`ATTRIBUTE_TYPES`, `FORM_ATTRIBUTES`, `SHOW_PAGE_ATTRIBUTES`).
4. The frontend reads it from `account.settings.your_toggle` (already serialized via `app/views/api/v1/models/_account.json.jbuilder` as `json.settings resource.settings`).

This keeps toggles keyed by name (immune to bit-position drift between branches) and unbounded by the bigint width.
