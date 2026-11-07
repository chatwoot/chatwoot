# AGENTS.md — working protocol for ai-service

The rules for every agent tool (Claude Code, Codex, ...) working on
`ai-service/`, the Go service that is the AI brain behind our Chatwoot fork.
`CLAUDE.md` in this folder imports this file. This file is the source of truth;
workspace files outside the repository only point here.

Plan and next steps: the checklist on issue DEV-Johnstocker/chatwoot#1.
Settled decisions: `docs/decisions.md`. Scope and acceptance gates:
`ai-service.contract.md`. How it works and how to run it: `README.md`.
Production and deploys: `deploy/README.md`.

## Project rules (these win over the general protocol below)

- Reply to the owner (John) in **English**, plain and direct.
- Base branch is **`develop`** (the fork), not `main`. Freshness check:
  `git fetch origin develop && git rev-list --left-right --count origin/develop...HEAD`.
- Our code lives only in `ai-service/` plus `.github/workflows/ai-service.yml`.
  Never edit Chatwoot's own files. Never open, copy or edit `enterprise/`.
  The repository-root `CLAUDE.md`/`AGENTS.md` are the Chatwoot team's Rails
  guide; they do not govern ai-service.
- Code adapted from agent-desk (Apache-2.0) keeps its notice, names its source
  file in the header, and is listed in `NOTICE`.
- No secrets in git. Machine secrets live in the workspace `local/.env`,
  outside this repository.
- Every change references issue #1.

## Commands

Run from `ai-service/`:

```bash
gofmt -l . && go vet ./... && go test -race ./...            # what CI runs
TEST_DATABASE_URL=postgres://... go test -p 1 ./...            # with pgvector tests (scratch DB only; -p 1: they share it)
go run golang.org/x/vuln/cmd/govulncheck@v1.9.0 ./...
docker build -t chatwoot-ai-service:dev .
```

CI: `.github/workflows/ai-service.yml` runs all of the above plus gitleaks and
actionlint on every PR into `develop`. Branch protection requires those five
checks and a PR for everyone, admins included.

## 1. Working autonomously

Decide and act; don't hand routine choices back. When there are options, pick
the recommended one and say which and why. Use the terminal, APIs, MCP servers
and a real browser before asking the owner to click something. Report what you
did, not what you could do.

Stop and ask only for:

- Secrets: creating, pasting or rotating a key, token or password. Never read a
  secret into the conversation; the owner pastes it.
- Production writes outside the release pipeline.
- Irreversible actions: deleting data, repositories, shared branches or
  published content; force-pushing a shared branch.
- Money and access: purchases, billing, permissions, branch protection,
  security settings.
- A real fork in the road (product direction, cost, risk appetite).

## 2. Propose better alternatives

- When a request could be done materially better, say so unasked. Recommend
  one option with its benefit and its cost, risk or scope. Cite a standard
  (WCAG, an RFC, vendor guidance) when it helps the decision; never invent one.
- Defined problem: pick the simplest sound solution. Exploratory request:
  compare a few real directions before committing.
- Build what was asked unless the alternative clearly replaces it, and say when
  it would. Changes to product direction, cost, access or accepted risk are the
  owner's call (§1).
- After verifying, critique the first version for failure states, security,
  usability, integration and maintenance. Fix what the acceptance gates need;
  flag the rest. One line per suggestion; no endless follow-up lists.

## 3. Branches and isolation

- Run the freshness check first. If behind, rebase or branch fresh.
- Never commit or push to `develop`. Every change, docs included, goes on a
  feature branch and through a pull request. Upstream Chatwoot updates too:
  merge `upstream/develop` into a branch and open a PR (the GitHub "Sync fork"
  button can't push to the protected branch).
- Use a worktree for substantial multi-file work (the workspace keeps them in
  `.claude/worktrees/<branch>`). Small single-file fixes need only a branch.
- One checkout per session. Never switch another session's branch, or commit,
  stash or reset its uncommitted work; if the shared checkout is in use, make
  your own worktree.
- Gitignore dependencies, `.env*`, build output and personal agent files.
- Go modules only; the service stays close to the standard library.

## 4. Implementation and testing

- Small, single-responsibility functions; follow the existing package layout.
- Test-driven: a unit test with every piece of business logic; for a bug, the
  failing test first. Arrange, Act, Assert in every test.
- Security boundaries (webhook signature, `/admin` auth, API keys) need
  negative tests: wrong secret, wrong credentials, replayed or malformed input,
  and proof that a rejected request changed nothing.
- Verify before claiming done: the CI commands above, with output read. Report
  failures with their output; say plainly when a step was skipped. Keep
  pre-existing failures apart from ones the change introduced, and local
  test results apart from live production results.

## 5. Database and release

- Before any database command, name the target (local, scratch, Supabase
  production) and confirm it without printing credentials. Tests use a scratch
  database only; production is never a test target.
- Schema changes are additive first: add, deploy, switch readers and writers,
  and remove old structures in a later change. Set a `lock_timeout` on
  schema changes. Never edit a change that was already applied.
- Release order: backup → apply schema → check the required tables and the
  `vector` extension exist → deploy the exact reviewed commit → health check.
  Rolling back code does not roll back a schema change.
- Production deploys go through Dokploy (`deploy/dokploy-compose.yml`) and need
  the owner's go-ahead. In Claude Code the owner runs `/deploy`
  (`.claude/skills/deploy/`), which checks, deploys and verifies.

## 6. Observability

- No `fmt.Println`/`log.Print` in production code. Use `log/slog` (JSON) with
  levels.
- Tag error logs with conversation ID and account ID. Never log secrets, API
  keys, message text or other personal data; log hosts, not full URLs.

## 7. Subagents

Default to doing the work yourself. Delegate only independent parallel work,
broad searches where only the conclusion matters, unanchored reviews, or long
side tasks. Reviews are always fresh: give the diff, not your conclusion. Treat
every report as a claim and verify what matters.

Read-only reviewers in `.claude/agents/`: `ai-service-security-reviewer` for
any change to a trust boundary (§4), `ai-service-migration-reviewer` for any
schema change (§5).

## 8. Version control

- Atomic commits, specific paths staged, tests passing. Use WIP commits, not
  `git stash`.
- Push when the unit of work is ready; never leave work only on the machine at
  session end (push a draft PR). Update with `git pull --rebase` and
  `git push --force-with-lease`; never plain `--force`, never `--no-verify`.
- Merge only after CI passes on the exact head:
  `gh pr merge --match-head-commit <full sha>`. A merged PR is not a deploy.
- Gitmoji: ✨ feat · 🐛 fix · ♻️ refactor · ⚡ perf · ✅ test · 🎨 style ·
  📝 docs · 🔧 chore.
- Each substantial workstream has one `<name>.contract.md` next to its code:
  scope, exclusions, runnable acceptance gates, recorded evidence.

## 9. Change review (visible changes only)

A change a person sees (the `/admin` pages, bot replies) needs the owner's
approval before pushing: a before/after page at 1280 px and 390 px published
as a private artifact, plus a running local URL and login. Backend, scripts
and docs skip this; their tests are the check.

## 10. Finishing and responding

- Finish the agreed scope, then check directly related gaps (failure paths,
  integration, real usage). Fix what the acceptance gates need; don't expand
  into unrelated work.
- Lead with the result. Recommend one option, not a menu. End with one handoff:
  what was delivered, what was verified, what is still open, and the one next
  step. Separate blockers from optional follow-ups.

## 11. Enforcement (Claude Code)

`.claude/settings.json` runs `.claude/hooks/guard.py` before tool calls. It
blocks pushes to `develop`, plain `--force`, `--no-verify`, any access to
`enterprise/`, edits to Chatwoot files outside our paths, and setting
`SAFE_FETCH_ALLOW_PRIVATE_NETWORK`. It also guards itself: agents cannot edit
`.claude/hooks/` or `.claude/settings*.json`; the owner changes those by hand.
A block is a rule, not an obstacle: never route around it. It is a guard
rail, not a sandbox. Tests:
`python3 -m unittest discover -s .claude/hooks`.

Keep this file under 200 lines. Point to other files instead of restating them.
