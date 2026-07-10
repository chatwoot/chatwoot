# Syncing the Fork with Upstream Chatwoot (Runbook)

**Who this is for:** you, the next time GitHub says *"This branch has conflicts
that must be resolved / Discard N commits to make this branch match the upstream
repository."* on the fork's `develop`.

**TL;DR:** When the banner offers to **discard commits**, do **not** click it —
that variant deletes your fork work. (When it offers a plain **"Update branch"**
merge instead, it is safe — see §1.) The real fix for the conflict case is a
one-line merge conflict in a generated file. This doc records what happened on
**2026-07-08**, exactly how it was fixed, and how to do it yourself next time.

- **`upstream`** = `github.com/chatwoot/chatwoot` (the original repo).
- **`origin`**  = `github.com/mujibulhaquetanim/meta-crm` (your fork).

Related: [`UPSTREAM_DIFF.md`](./UPSTREAM_DIFF.md) (what the fork changes and why it
stays conflict-friendly), [`ARCHITECTURE.md`](./ARCHITECTURE.md) (the `custom/`
overlay mechanism).

---

## 1. What actually happened

GitHub's fork page showed, on `develop`:

> This branch has conflicts that must be resolved.
> Discard 31 commits to make this branch match the upstream repository.
> 31 commits will be removed from this branch.

This looks alarming, but it is **not** a code problem. It is GitHub's **"Sync
fork"** feature talking. Here is the real state we measured with git:

| Ref | Relationship to `upstream/develop` |
|---|---|
| `origin/develop` (your fork) | **31 ahead**, 14 behind |
| merge-base (last common commit) | `8818d27`, dated **2026-07-02** |

The two histories had simply **diverged**: your fork had 31 commits of fork work
(the `custom/` overlay, docs, super-admin, quota, branding) that upstream doesn't
have, and upstream had 14 new commits that your fork didn't have yet.

### Why GitHub offered to "discard 31 commits"

GitHub's **Sync fork** button has two modes, picked automatically:

1. **Clean case → "Update branch."** If upstream's new commits merge into your
   branch without conflicts, the button performs a real **merge** (commit
   message *"Merge branch 'chatwoot:develop' into develop"*) — or a fast-forward
   when your branch has no commits of its own. This is safe: it is the same
   merge §6 does by hand. It happened on **2026-07-10** (merge commit
   `cc717c6`, 13 upstream commits, zero conflicts, fork columns verified
   intact afterwards).
2. **Conflict case → "Discard N commits."** If the merge *would conflict*
   (here: the `db/schema.rb` version line, §2), GitHub cannot resolve it in the
   web UI, so its only remaining offer is: **throw away your N commits so the
   branch matches upstream exactly.** That would erase the entire fork.
   **Never accept the discard offer.**

So the button itself is not the trap — the **"discard commits"** fallback is.
When you see "conflicts must be resolved / discard N commits", close the page
and do the manual merge below; the only conflict is trivial.

---

## 2. The only real conflict: `db/schema.rb` (and only one line of it)

When we did a trial merge of `upstream/develop` into `origin/develop`, git
reported **exactly one** conflicted file:

```
Auto-merging app/models/team.rb          ← merged clean
Auto-merging config/locales/en.yml       ← merged clean
Auto-merging .../i18n/.../settings.json  ← merged clean
Auto-merging db/schema.rb
CONFLICT (content): Merge conflict in db/schema.rb   ← the ONLY conflict
```

**Zero conflicts in any actual code** — OSS (`app/`, `lib/`, `config/`) or the
fork's `custom/` overlay. This is the fork architecture working as designed: all
fork behavior lives in `custom/` (injected via `prepend_mod_with`), a tree
upstream never touches, so it can never textually collide. See
[`UPSTREAM_DIFF.md` §0](./UPSTREAM_DIFF.md).

### Why `db/schema.rb` conflicts every time

`db/schema.rb` is a **generated file**. Its first meaningful line is a version
stamp equal to the timestamp of the newest migration that has been applied:

```ruby
ActiveRecord::Schema[7.1].define(version: 2026_07_06_215758) do
```

Both sides added migrations since the 2026-07-02 split, so both sides bumped this
line to a *different* value — and git can't auto-pick one:

| Side | Newest migration added | schema version line |
|---|---|---|
| merge-base (2026-07-02) | — | `2026_06_20_000000` |
| **your fork** | `20260704000000_add_platform_managed_to_platform_resources` | `2026_07_04_000000` |
| **upstream** | `20260706215758_add_feature_flags_ext_2_to_accounts` (+2 index migs) | `2026_07_06_215758` |

The **table/column bodies** of `schema.rb` merged cleanly on their own, because
each side's new columns live in different, non-overlapping sections of the file.
Only the single version line at the top actually conflicts. **This recurs on any
sync where *both* sides added migrations since the last one** — it is normal and
trivial. (When only upstream added migrations — the common case once the fork's
schema work settles — the merge is conflict-free, as on 2026-07-10.)

---

## 3. How it was fixed (exact steps)

```bash
# 0. Make sure upstream is fetched
git fetch upstream develop

# 1. Get local develop to the fork's tip, then merge upstream in
git checkout develop
git merge --ff-only origin/develop      # local develop -> fork tip (0f8c9ba)
git merge --no-ff upstream/develop       # conflicts ONLY on db/schema.rb
```

The conflict looked like this:

```
<<<<<<< HEAD
ActiveRecord::Schema[7.1].define(version: 2026_07_04_000000) do
=======
ActiveRecord::Schema[7.1].define(version: 2026_07_06_215758) do
>>>>>>> upstream/develop
```

**Resolution rule: keep the newer (higher) timestamp.** After a full merge the
newest applied migration is upstream's `2026_07_06_215758`, so that line wins:

```ruby
ActiveRecord::Schema[7.1].define(version: 2026_07_06_215758) do
```

Then verify **both** sides' schema changes survived the auto-merge (they did),
finish the merge, and push **to the fork only**:

```bash
git grep -nE '^(<<<<<<<|=======|>>>>>>>)'   # -> nothing: no markers left
grep -c platform_managed db/schema.rb        # -> 3  (fork columns present)
grep -c index_calls_on_account_id_and_created_at db/schema.rb  # -> 1 (upstream present)

git add db/schema.rb
git commit --no-edit                         # merge commit 745be5b
git push origin develop                      # to YOUR fork, never upstream
```

**Session audit trail (SHAs):**

| Thing | SHA |
|---|---|
| merge-base (2026-07-02) | `8818d27` |
| fork `develop` before merge | `0f8c9ba` |
| `upstream/develop` tip merged in | `b9536fb` |
| the merge commit | `745be5b` |
| develop after PR #8 squash-merged on top | `c7d17c8` |

> **Note on regenerating instead of hand-editing:** the 100%-correct way to
> produce `schema.rb` is to run the migrations and let Rails re-dump it
> (`db:migrate` / `db:schema:dump`). Hand-picking the version line is the fast,
> safe shortcut *when the column bodies already auto-merged cleanly* — which is
> the normal case. If you ever see conflicts inside the table bodies (not just
> the version line), don't hand-merge: finish the merge taking either side, then
> run migrations in dev and commit the regenerated `schema.rb`.

---

## 4. The guards that stop you pushing fork code into Chatwoot

Two guards were installed on **2026-07-08** so your project code can never
accidentally land in `chatwoot/chatwoot`.

### Guard 1 — `git push upstream` is disabled

The `upstream` remote's **push** URL was pointed at an invalid sentinel, so any
push to upstream fails instantly and locally (no network, no accident). **Fetch
still works** (fetch URL unchanged).

```bash
git remote set-url --push upstream DISABLE_PUSH_TO_CHATWOOT_UPSTREAM
```

### Guard 2 — `gh pr create` targets the fork

```bash
gh repo set-default mujibulhaquetanim/meta-crm
```

Without this, `gh pr create` defaults a new PR's base to the **parent** repo
(chatwoot). With it, PRs go to your fork's `develop`.

### ⚠️ The web UI is the one hole these guards don't cover

Opening a PR on **github.com** still defaults the *base repository* to the parent
(chatwoot). When you create PRs in the browser, **check the "base repository"
dropdown says `mujibulhaquetanim/meta-crm`** before clicking create.

### ⚠️ These guards are machine-local, not committed

Both guards live in **local git/gh config on this machine only** — they are *not*
part of the repo. On a **fresh clone** (or a new machine) you must re-apply them,
then re-verify.

---

## 5. Verify the guards (run anytime)

```bash
# Guard 1: push URL must be the sentinel, and a push must fail
git remote -v | grep upstream
#   upstream  https://github.com/chatwoot/chatwoot.git (fetch)
#   upstream  DISABLE_PUSH_TO_CHATWOOT_UPSTREAM (push)      <- correct
git push upstream develop --dry-run    # must FAIL ("repository does not exist")

# Guard 2: default repo must be the fork
gh repo set-default --view             # -> mujibulhaquetanim/meta-crm
```

Both were confirmed working on 2026-07-08.

---

## 6. The routine for every future upstream sync

Do this whenever you want upstream's latest, or when GitHub nags about the fork
being behind:

```bash
git fetch upstream develop
git checkout develop
git merge --ff-only origin/develop     # only if local is behind the fork remote
git merge --no-ff upstream/develop     # at most ONE conflict: db/schema.rb version line
                                       # (only when BOTH sides added migrations; often clean)
# -> if schema.rb conflicts: keep the higher (newer) version timestamp
git add db/schema.rb && git commit --no-edit
git push origin develop                # fork only
```

Then bring feature branches up to date off the fork, not upstream:

```bash
git checkout <feature-branch>
git merge develop                      # usually zero conflicts (schema already resolved)
```

### Do / Don't

- ✅ **Merge** `upstream/develop` into your `develop`, resolve the one schema line, push to `origin`.
- ✅ Expect **at most** `db/schema.rb` to conflict, and only its version line.
- ✅ GitHub's **Sync fork → "Update branch"** (the clean-merge offer) is fine — it does this same merge.
- ✅ Verify guards after any fresh clone.
- ❌ **Never** click **"Discard N commits"** (Sync fork's conflict fallback) — it deletes the fork's commits.
- ❌ **Never** `git push upstream ...` (Guard 1 blocks it, but don't fight it).
- ❌ **Never** hand-edit `schema.rb` table bodies — if those conflict, regenerate via migrations.

---

## 7. Why this stays cheap forever

The fork keeps **all** real behavior in `custom/` (plus `docs/fork/` and
`spec/custom/`) — trees upstream never touches — and only ever touches OSS files
in the four inert ways catalogued in
[`UPSTREAM_DIFF.md` §0](./UPSTREAM_DIFF.md) (the fourth, dev-env/tooling files
like `docker-compose.yaml` and `database.yml`, is the one surface that *can*
conflict when upstream reworks those files — see `UPSTREAM_DIFF.md` §6).
That is *why* a merge across 14
upstream commits produced zero code conflicts. As long as that discipline holds,
every future sync is the same trivial one-line `schema.rb` fix — never a real
merge battle.
