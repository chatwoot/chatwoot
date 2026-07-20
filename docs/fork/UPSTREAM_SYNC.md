# Syncing the Fork with Upstream Chatwoot (Runbook)

**Who this is for:** you, the next time GitHub says *"This branch has conflicts
that must be resolved / Discard N commits to make this branch match the upstream
repository."* on the fork's `develop`.

**TL;DR:** When the banner offers to **discard commits**, do **not** click it —
that variant deletes your fork work. (When it offers a plain **"Update branch"**
merge instead, it is safe — see §1.) Do the merge by hand (§6). Expect **at most
two small conflicts**, both with a standing resolution rule: the `db/schema.rb`
version line, and occasionally one of the OSS files the fork branded (§2). This
doc records the **2026-07-08** sync and the **2026-07-20** one, which conflicted
in a way the original version of this doc said was impossible (§3b).

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
and do the manual merge below; the conflicts are few and each has a standing
resolution rule (§2).

---

## 2. The two things that can conflict

> **Corrected 2026-07-20.** This section used to claim `db/schema.rb` was the
> *only* possible conflict and that there were "zero conflicts in any actual
> code." That is wrong, and it set the wrong expectation: the 2026-07-20 sync
> conflicted on a **`.vue` file** while `schema.rb` merged clean — the exact
> inverse of what this doc promised. See §3b for that case.

There are exactly **two** classes of conflict, and they have different causes:

| # | Surface | Cause | Frequency |
|---|---|---|---|
| **A** | `db/schema.rb` version line | Both sides added migrations since the split | Only when *both* sides migrated |
| **B** | The OSS files the fork **edits directly** | Upstream changes a line the fork also changed | Rare, and shrinking — see below |

**Class B is the one to actually watch.** The reassuring version of this doc was
right about `custom/`: fork *behavior* lives there, upstream never touches that
tree, so it cannot textually collide. But the fork does not live *entirely* in
`custom/`. It edits a small, catalogued set of OSS files directly — chiefly the
**white-label pass** (`432483c`), which replaced literal "Chatwoot" strings in
`en.json` / `en.yml` and a handful of `.vue` literals. Those lines are OSS lines,
so upstream can and does edit them too. See
[`UPSTREAM_DIFF.md` §0](./UPSTREAM_DIFF.md) for the full catalogue of the fork's
OSS touchpoints — **that list is your conflict surface**, not `schema.rb`.

The good news: class B is **self-liquidating**. Upstream is independently
migrating its own hardcoded brand strings to `replaceInstallationName()`. Every
time it does, the fork's corresponding hardcode should be *dropped* in favour of
upstream's dynamic version (§3b) — which permanently removes that line from the
conflict surface.

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

## 3b. Worked example of a class-B conflict (2026-07-20)

The sync of **14 upstream commits** (`5af26e4` → `160732c`, Chatwoot 4.16.0)
behaved the opposite way to everything above:

- `db/schema.rb` **merged clean** — the fork added no migrations that cycle, so
  upstream's newer stamp (`2026_07_13_184351`) won uncontested.
- The one conflict was in
  `app/javascript/dashboard/routes/dashboard/settings/inbox/components/SenderNameExamplePreview.vue`.

Upstream PR **#15076** ("apply installation name to sender name preview") changed
the same two lines the fork's white-label pass had changed:

```
<<<<<<< HEAD
      businessName: 'Meta CRM',                        ← fork: hardcoded
=======
      businessName: replaceInstallationName('Chatwoot'), ← upstream: dynamic
>>>>>>> upstream/develop
```

**Resolution rule for class B: when upstream implements the branding properly,
take upstream's side and drop the fork's hardcode.**

Here that was strictly better on three counts:

1. It is the pattern the fork's own `CLAUDE.md` prescribes — route brand strings
   through `replaceInstallationName` from `shared/composables/useBranding`
   instead of hardcoding.
2. It still renders "Meta CRM": the composable substitutes
   `globalConfig.installationName`, which `Custom::BrandingSetup`
   (`custom/app/services/custom/branding_setup.rb`) populates from
   `INSTALLATION_NAME`.
3. It **removes** a fork edit to an OSS file, so those two lines can never
   conflict again.

Before taking upstream wholesale, confirm the fork's edit to that file was
*only* the branding lines:

```bash
git diff <merge-base> develop -- <the-conflicted-file>
```

If the fork made other changes to the file, resolve hunk-by-hunk instead of
`git checkout --theirs`.

### Verify the overlay still binds (do this every sync)

A clean text merge does **not** prove the `custom/` overlay still works —
`prepend` silently breaks if upstream renames or removes the method being
`super`'d. Cross-reference what upstream touched against what the fork overlays:

```bash
git diff <merge-base> upstream/develop --name-only > /tmp/up.txt
git ls-files custom/ | grep -E '\.rb$' | while read f; do
  oss=$(echo "$f" | sed 's|^custom/||; s|/custom/|/|')
  grep -qxF "$oss" /tmp/up.txt && echo "OVERLAP: $oss"
done
```

For each overlap, confirm the method the overlay calls `super` on still exists.
On 2026-07-20 there was one — `app/models/inbox.rb` — and it was benign:
upstream added `InboxBrandedEmailLayoutable` and an `email_templates`
association, neither of which touches `assignable_agents`, the method
`Custom::Inbox` overrides.

Also confirm the white-label pass did not regress — upstream's new strings can
reintroduce "Chatwoot" into files the fork de-branded:

```bash
grep -ci chatwoot app/javascript/dashboard/i18n/locale/en/*.json
# compare against the same counts before the merge; they should be unchanged
```

**Audit trail:**

| Thing | SHA |
|---|---|
| merge-base | `5af26e4` |
| `upstream/develop` tip merged in | `160732c` |
| the merge commit on `develop` | `8d48f57` |
| merge into `fork/super-admin-privilege-separation-spec` | `f2fe7e3` |

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
git fetch upstream develop             # NOT bare `git fetch upstream` — that pulls
                                       # every branch and can take many minutes
git checkout develop
git merge --ff-only origin/develop     # only if local is behind the fork remote
git merge --no-ff upstream/develop     # expect 0-2 conflicts, see §2:
                                       #  A) db/schema.rb version line -> keep the higher timestamp
                                       #  B) an OSS file the fork branded -> usually take upstream (§3b)
git commit --no-edit
# then verify the overlay still binds + no branding regressions (§3b)
git push origin develop                # fork only
```

Then bring feature branches up to date off the fork, not upstream:

```bash
git checkout <feature-branch>
git merge develop                      # usually zero conflicts (schema already resolved)
```

### Do / Don't

- ✅ **Merge** `upstream/develop` into your `develop`, resolve the conflicts in §2, push to `origin`.
- ✅ Expect conflicts **only** in `db/schema.rb` and in the OSS files the fork edits
  directly (catalogued in [`UPSTREAM_DIFF.md` §0](./UPSTREAM_DIFF.md)) — mostly branding strings.
- ✅ When upstream implements a brand string via `replaceInstallationName`, take
  **upstream's** version and delete the fork's hardcode (§3b).
- ✅ Run the overlay-binding and branding-regression checks in §3b after every sync.
- ✅ `git fetch upstream develop`, not bare `git fetch upstream`.
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
That is *why* syncs of 13-14 upstream commits resolve in minutes rather than
turning into merge battles.

But "cheap" is not "zero" — the honest claim is narrower than the one this
section used to make:

- **`custom/`, `spec/custom/`, `docs/fork/` can never conflict.** Upstream does
  not know those trees exist. This is the architecture doing its job, and it
  covers the overwhelming majority of fork code.
- **The fork's direct OSS edits can conflict, and periodically will.** That is
  the white-label string pass plus the dev-env/tooling files. It is a small,
  enumerable surface — but it is not empty, and 2026-07-20 proved it (§3b).

The surface also **shrinks over time**: each time upstream converts one of its
own hardcoded brand strings to `replaceInstallationName`, the fork deletes its
corresponding hardcode and that line leaves the conflict surface permanently.
The way to keep syncs cheap is therefore to keep taking upstream's dynamic
implementation whenever it appears — never to re-hardcode a brand string that
upstream now handles through config.
