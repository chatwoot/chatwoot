---
name: chatwit-upstream-sync
description: "Safely merge upstream Chatwoot updates into the Chatwit fork while preserving all customizations (SocialWise, JusMonitorIA, rich messages, branding). Use this skill when the user asks to update from upstream Chatwoot, sync the fork, pull latest Chatwoot changes, check for upstream updates, or merge Chatwoot into Chatwit. Also trigger when the user mentions 'upstream', 'chatwoot updates', 'sync fork', 'atualizar do chatwoot', or 'merge upstream'."
category: devops
risk: high
source: witdev
date_added: "2026-03-09"
date_updated: "2026-03-10"
version: "2.1"
---

# Chatwit Upstream Sync v2

Safely merge upstream Chatwoot repository updates into the Chatwit fork, preserving all custom integrations and branding.

## Context

Chatwit is a fork of Chatwoot with custom integrations (SocialWise, JusMonitorIA, rich messages, branding). When Chatwoot releases updates, we need to merge them without losing our customizations. This is a delicate operation because both codebases modify some of the same files.

## Critical Lessons Learned

> **2026-03-10 Incident:** A previous sync was done via **cherry-picks** instead of `git merge`, which created duplicate commits with different SHAs. The merge-base stayed at v4.10.1 even though content was at v4.11.2. This caused git to report 163 upstream commits "ahead" when only 7 were truly missing. Future merges would have been catastrophic — git would try to re-apply 150+ commits already present, generating massive phantom conflicts.

**The root cause:** Cherry-picks do NOT update the merge-base. Git uses the merge-base to determine divergence, so cherry-picked history creates invisible drift that compounds over time.

## Golden Rules (read BEFORE every sync)

1. **ALWAYS use `git merge`, NEVER cherry-pick for bulk sync.** Cherry-pick is only for isolated emergency hotfixes (1-2 commits).
2. **ALWAYS verify merge-base health** before starting — a stale merge-base means the previous sync was done wrong and needs recovery first.
3. **ALWAYS create a backup branch** before any operation.
4. **ALWAYS verify true divergence by PR number**, not raw commit count — cherry-picked commits have different SHAs.
5. **NEVER force-resolve all conflicts to one side** — each conflict needs individual analysis.
6. **NEVER lose our `extract_interactive_data` method** — it's the core of QUICK_REPLY support.
7. **NEVER overwrite Chatwit logos with Chatwoot logos** — brand assets are always ours.
8. **If unsure about a conflict, ask the user** — it's better to pause than to lose code.
9. **After merging, verify no conflict markers remain** — `grep -rn "<<<<<<" . --include="*.rb" --include="*.vue" --include="*.yml"`
10. **ALWAYS push at the end** — the service must be complete: backup, sync, verify, push. Deliver the house clean and locked.
11. **ALWAYS update `AGENTS.md` after any sync** — record the new Chatwoot version, new merge-base, and any important code changes that affect migration safety (renamed files, changed APIs, new protected areas, branch strategy changes). This keeps the historical migration table accurate and prevents future syncs from breaking silently.

## Protected Customization Areas

These files/directories contain Chatwit custom code that must NEVER be lost during a merge:

### SocialWise Integration
- `lib/integrations/socialwise/` — Core SocialWise services
- `lib/integrations/socialwise_flow/` — Flow engine (debounce, processors)
- `config/initializers/socialwise_bot.rb` — Agent Bot auto-provisioning
- `config/initializers/socialwise_cache.rb` — Cache preload
- `app/jobs/socialwise_*.rb` — Background jobs
- `app/controllers/api/v1/accounts/integrations/socialwise_*.rb` — API controllers

### JusMonitorIA Integration
- `lib/integrations/jusmonitoria/` — Processor, response, webhook forwarder
- `config/initializers/jusmonitoria_bot.rb` — Bot auto-provisioning

### Rich Messages & UI
- `app/javascript/dashboard/components-next/message/bubbles/WhatsAppInteractive.vue`
- `app/javascript/dashboard/components-next/message/bubbles/RichCards.vue`
- `app/javascript/dashboard/components-next/message/Message.vue` — Content type routing
- `app/services/messages/whatsapp_renderer_mapper.rb`
- `app/services/messages/instagram_renderer_mapper.rb`

### WhatsApp Enhancements
- `app/services/whatsapp/incoming_message_base_service.rb` — QUICK_REPLY extraction via `extract_interactive_data`
- `app/services/whatsapp/providers/whatsapp_cloud_service.rb` — Template dispatch
- `app/services/whatsapp/populate_template_parameters_service.rb` — quick_reply parameters
- `app/jobs/whatsapp_typing_job.rb` — Typing indicator
- `app/listeners/whatsapp_typing_listener.rb` — Typing events

### Instagram/Facebook Enhancements
- `app/builders/messages/instagram/base_message_builder.rb` — Postback/quick_reply payload
- `app/builders/messages/facebook/message_builder.rb` — Postback/quick_reply + message_content
- `app/services/instagram/rich_message_service.rb`
- `app/services/facebook/rich_message_service.rb`

### Webhook Customizations
- `app/listeners/webhook_listener.rb` — `include_access_token` support
- `app/javascript/dashboard/routes/dashboard/settings/integrations/Webhooks/WebhookForm.vue`
- `app/views/api/v1/accounts/webhooks/_webhook.json.jbuilder`

### Redis Keys
- `lib/redis/redis_keys.rb` — SocialWise debounce keys

### Branding
- `public/brand-assets/logo.svg` — Always keep Chatwit version
- `public/brand-assets/logo_dark.svg` — Always keep Chatwit version
- `public/brand-assets/logo_w.svg`, `logo_dark_w.svg`, `logo_thumbnail_w.svg` — Chatwit variants

### Config & Docs
- `config/integration/apps.yml` — SocialWise + JusMonitorIA integrations
- `config/locales/en.yml` — Custom i18n keys (additive)
- `chatwitdocs/` — All documentation

---

## Workflow

Execute these phases in order. Communicate progress clearly at each stage. Do NOT skip phases.

### Phase 1: Pre-flight Checks

```bash
# 1. Verify we're in the right repo
git remote -v  # Must show origin (Witroch4/chatwit) and upstream (chatwoot/chatwoot)

# 2. Check for uncommitted changes
git status

# 3. Verify current branch
git branch --show-current  # Must be develop
```

If `upstream` remote doesn't exist:
```bash
git remote add upstream https://github.com/chatwoot/chatwoot.git
```

If there are uncommitted changes, ask the user: commit, stash, or abort.

### Phase 2: Fetch & Diagnose Merge-Base Health

This is the most critical diagnostic phase. It determines whether this is a **normal merge** or a **recovery from cherry-pick drift**.

```bash
# 1. Fetch latest upstream
git fetch upstream

# 2. Identify the merge-base
BASE=$(git merge-base HEAD upstream/develop)
echo "Merge-base: $(git log --oneline -1 $BASE)"

# 3. Check version tags
git tag --sort=-version:refname | grep -E "^v?4\." | head -5

# 4. Raw divergence counts
UPSTREAM_AHEAD=$(git log --oneline HEAD..upstream/develop | wc -l)
OUR_AHEAD=$(git log --oneline upstream/develop..HEAD | wc -l)
echo "Upstream ahead: $UPSTREAM_AHEAD | Ours ahead: $OUR_AHEAD"
```

#### Critical: Detect Cherry-Pick Drift

If `UPSTREAM_AHEAD` is large (>20) but we recently synced, the previous sync was likely cherry-picks:

```bash
# Compare by PR number — this reveals the TRUE gap
git log --oneline $BASE..upstream/develop | grep -oP '#\d+' | sort -u > /tmp/upstream_prs.txt
git log --oneline $BASE..HEAD | grep -oP '#\d+' | sort -u > /tmp/our_prs.txt

TRULY_MISSING=$(comm -23 /tmp/upstream_prs.txt /tmp/our_prs.txt | wc -l)
ALREADY_PRESENT=$(comm -12 /tmp/upstream_prs.txt /tmp/our_prs.txt | wc -l)

echo "PRs upstream total: $(wc -l < /tmp/upstream_prs.txt)"
echo "PRs already in our branch: $ALREADY_PRESENT"
echo "PRs truly missing: $TRULY_MISSING"
```

**Decision point:**

| Condition | Diagnosis | Action |
|-----------|-----------|--------|
| `UPSTREAM_AHEAD` is small (< 20) AND merge-base is recent | **Normal sync** — proceed to Phase 3 | `git merge upstream/develop` |
| `UPSTREAM_AHEAD` is large BUT `TRULY_MISSING` is small (< 20) | **Cherry-pick drift** — previous sync used cherry-picks | Go to **Phase 2R: Recovery Mode** |
| `UPSTREAM_AHEAD` is large AND `TRULY_MISSING` is also large | **Long-neglected sync** — many real changes to integrate | Proceed to Phase 3 with extra caution |

Also check for commits without PR numbers (merge commits, version bumps):
```bash
# Upstream commits without PR# (may be missing too)
git log --oneline $BASE..upstream/develop | grep -vP '#\d+'
```

### Phase 2R: Recovery Mode (Cherry-Pick Drift)

> **Only enter this phase if Phase 2 detected cherry-pick drift.** This happens when a previous sync cherry-picked upstream commits instead of merging, leaving the merge-base stale.

**Goal:** Bring in the truly missing commits, then fix the merge-base so future syncs work correctly.

#### Step 1: Identify truly missing commits

```bash
# Get the missing PR numbers
MISSING_PRS=$(comm -23 /tmp/upstream_prs.txt /tmp/our_prs.txt)

# For each missing PR, find the upstream commit SHA
for pr in $MISSING_PRS; do
  git log --oneline $BASE..upstream/develop | grep "$pr"
done
```

Also check commits without PR numbers — compare manually:
```bash
git log --oneline $BASE..upstream/develop | grep -vP '#\d+'
git log --oneline $BASE..HEAD | grep -vP '#\d+'
```

#### Step 2: Analyze missing commits for conflict risk

For each missing commit, check which files it touches:
```bash
for sha in <MISSING_SHAS>; do
  echo "--- $(git log --oneline -1 $sha) ---"
  git diff-tree --no-commit-id --name-only -r $sha
done
```

Cross-reference with the Protected Customization Areas list above. Present a risk table:

| PR | Description | Files | Touches Protected? | Risk |
|----|-------------|-------|--------------------|------|
| #XXXXX | fix: something | file.rb | No | Low |

#### Step 3: Backup

```bash
git branch backup/pre-upstream-sync-$(date +%Y%m%d) HEAD
```

#### Step 4: Cherry-pick the truly missing commits

Cherry-pick ONLY the missing ones, in chronological order (oldest first):
```bash
git cherry-pick <SHA1> <SHA2> ...
```

Resolve any conflicts per the Conflict Resolution rules below.

#### Step 5: Fix the merge-base (CRITICAL)

After all missing commits are applied, reconcile the merge-base with a strategy merge:

```bash
git merge -s ours upstream/develop -m "merge(upstream): reconcile merge-base with upstream/develop

All upstream commits already present via cherry-pick.
This merge updates the merge-base so future syncs use git merge cleanly.

Chatwit customizations preserved:
- SocialWise Flow integration
- JusMonitorIA integration
- Rich messages (WhatsApp/Instagram/Facebook)
- QUICK_REPLY button payload extraction
- Webhook access token inclusion
- Chatwit branding
- Redis debounce keys"
```

> **What `git merge -s ours` does:** It creates a real merge commit linking both histories, but keeps ALL of our files unchanged (the "ours" strategy). This tells git: "we already have everything from upstream." Future `git merge upstream/develop` will now only show truly new commits.

#### Step 6: Verify recovery

```bash
# Must be 0 — we're fully caught up
git log --oneline HEAD..upstream/develop | wc -l

# Merge-base must now point to upstream/develop HEAD
git merge-base HEAD upstream/develop
```

Then skip to **Phase 7: Verify & Finalize**.

---

### Phase 3: Conflict Analysis (Normal Merge Path)

Before touching anything, analyze which customized files overlap with upstream changes:

```bash
BASE=$(git merge-base HEAD upstream/develop)

# Files modified by us (custom code)
git diff --name-only $BASE HEAD | sort > /tmp/our_files.txt

# Files modified by upstream
git diff --name-only $BASE upstream/develop | sort > /tmp/upstream_files.txt

# Intersection = potential conflicts
comm -12 /tmp/our_files.txt /tmp/upstream_files.txt
```

For each overlapping file, analyze the nature of changes:

```bash
for f in $(comm -12 /tmp/our_files.txt /tmp/upstream_files.txt); do
  echo "=== $f ==="
  echo "OURS: $(git diff $BASE HEAD -- "$f" | grep "^+" | grep -v "^+++" | wc -l) lines added"
  echo "UPSTREAM: $(git diff $BASE upstream/develop -- "$f" | grep "^+" | grep -v "^+++" | wc -l) lines added"
done
```

Present a clear risk table:

| File | Our Changes | Upstream Changes | Risk |
|------|------------|-----------------|------|
| file.rb | What we added | What they changed | Low/Medium/High |

### Phase 4: Backup

```bash
git branch backup/pre-upstream-sync-$(date +%Y%m%d) HEAD
```

Inform the user: "Backup at `backup/pre-upstream-sync-YYYYMMDD`. Recovery: `git reset --hard backup/pre-upstream-sync-YYYYMMDD`."

### Phase 5: Merge

**ALWAYS use `git merge`. NEVER cherry-pick for bulk sync.**

```bash
git merge upstream/develop
```

If this is a clean merge (no conflicts), skip to Phase 7.

### Phase 6: Conflict Resolution

Resolve each conflict following these rules. Read each file carefully — no scripts, no bulk resolution.

#### Auto-resolve (keep upstream):
- `public/404.html`, `public/422.html`, `public/500.html` — Error pages
- `swagger/` files — API documentation

```bash
git checkout --theirs <file> && git add <file>
```

#### Auto-resolve (keep ours / Chatwit):
- `public/brand-assets/logo.svg` — Always Chatwit branding
- `public/brand-assets/logo_dark.svg` — Always Chatwit branding
- `public/brand-assets/logo_w.svg`, `logo_dark_w.svg`, `logo_thumbnail_w.svg`
- `chatwitdocs/` — Our documentation, always keep

```bash
git checkout --ours <file> && git add <file>
```

#### Smart merge (keep BOTH sides):

For files where we added code AND upstream added different code, combine both:

- **`db/schema.rb`** — Keep upstream version number (higher), keep all columns from both
- **`lib/redis/redis_keys.rb`** — Keep our debounce keys AND upstream's new keys
- **`config/locales/en.yml`** — Additive, keep all keys from both sides
- **`app/views/api/v1/accounts/webhooks/_webhook.json.jbuilder`** — Keep both fields
- **`WebhookForm.vue`** — Keep both data properties

#### Careful merge (understand both sides):

These files need manual analysis because both sides modify the same logic. Open the file, read both versions, understand intent, then combine:

- **`incoming_message_base_service.rb`** — Upstream may refactor core methods. Our `extract_interactive_data` method is self-contained and must be preserved. The `create_message` method must include `content_attrs.merge(extract_interactive_data(message))`.

- **`webhook_listener.rb`** — Our `include_access_token` logic wraps the payload. Upstream may change `WebhookJob.perform_later` signature. Keep our access token injection AND upstream's new parameters.

- **`instagram/base_message_builder.rb`** and **`facebook/message_builder.rb`** — Our postback/quick_reply payload extraction is additive. Upstream may add echo support. Keep both.

- **`Message.vue`** — Our additions (WhatsAppInteractive and RichCards content type routing) are in separate `if` blocks. Upstream changes are usually in different sections. Both coexist.

After resolving each file:
```bash
git add <resolved-file>
# Verify no conflict markers remain
grep -n "<<<<<<\|=======\|>>>>>>>" <resolved-file>
```

### Phase 7: Verify & Finalize

```bash
# 1. No remaining conflicts
git diff --name-only --diff-filter=U  # Must be empty

# 2. No conflict markers in codebase
grep -rn "<<<<<<" . --include="*.rb" --include="*.vue" --include="*.yml" --include="*.html" --include="*.js" --include="*.ts" | grep -v node_modules | grep -v ".git/"
# Ignore lines that are decorative separators (e.g. "=======" in comments)

# 3. Verify ALL protected customizations exist
for f in \
  "lib/integrations/socialwise/" \
  "lib/integrations/socialwise_flow/" \
  "lib/integrations/jusmonitoria/" \
  "config/initializers/socialwise_bot.rb" \
  "config/initializers/socialwise_cache.rb" \
  "config/initializers/jusmonitoria_bot.rb" \
  "app/javascript/dashboard/components-next/message/bubbles/WhatsAppInteractive.vue" \
  "app/javascript/dashboard/components-next/message/bubbles/RichCards.vue" \
  "public/brand-assets/logo.svg"; do
  test -e "$f" && echo "OK: $f" || echo "MISSING: $f"
done

# 4. Verify merge-base is now current
echo "Upstream ahead: $(git log --oneline HEAD..upstream/develop | wc -l)"
# Must be 0

# 5. Commit (if not already committed by merge)
git log --oneline -1  # Check if merge commit exists

# 6. Final log
git log --oneline -5
```

### Phase 8: Push & Deliver

The service is complete only when the code is pushed:

```bash
git push origin develop
```

Verify the push:
```bash
git log --oneline origin/develop -3
```

### Phase 9: Summary Report

Present a clear summary:

```
## Upstream Sync Complete

**Sync type:** Normal merge / Recovery (cherry-pick drift)
**Version:** vX.Y.Z (N commits integrated)
**Merge-base:** <new merge-base SHA>
**Conflicts resolved:** X files
**Backup:** backup/pre-upstream-sync-YYYYMMDD
**Pushed to:** origin/develop

### Conflict Resolution Summary
| File | Resolution |
|------|-----------|
| ... | ... |

### Key Upstream Features Added
- ...

### Chatwit Customizations Verified
- [x] SocialWise Flow
- [x] JusMonitorIA
- [x] Rich Messages
- [x] WhatsApp enhancements
- [x] Instagram/Facebook enhancements
- [x] Webhook customizations
- [x] Branding
- [x] Redis keys
- [x] Config & docs
```

---

### Phase 10: Update AGENTS.md

Append a one-block entry to the `## Histórico de Migração` section in `AGENTS.md`:

```markdown
### YYYY-MM-DD — Upstream sync vX.Y.Z (N commits)
- Sync type: Normal merge / Recovery
- New merge-base: <git merge-base HEAD upstream/develop | cut -c1-8>
- Conflicts: <N> resolved
- Critical: <anything future syncs must know — renamed file, moved method, new protected area>
```

Only also update the **Arquivos críticos** or **Componentes SocialWise** tables if a protected path actually changed.

---

## Quick Diagnostic Cheat Sheet

Run this to instantly assess sync health:

```bash
BASE=$(git merge-base HEAD upstream/develop)
echo "Merge-base: $(git log --oneline -1 $BASE)"
echo "Upstream ahead (raw): $(git log --oneline HEAD..upstream/develop | wc -l)"
echo "Ours ahead (raw): $(git log --oneline upstream/develop..HEAD | wc -l)"

# True gap by PR#
git log --oneline $BASE..upstream/develop | grep -oP '#\d+' | sort -u > /tmp/up.txt
git log --oneline $BASE..HEAD | grep -oP '#\d+' | sort -u > /tmp/us.txt
echo "Truly missing PRs: $(comm -23 /tmp/up.txt /tmp/us.txt | wc -l)"
comm -23 /tmp/up.txt /tmp/us.txt
```

If "Upstream ahead" is high but "Truly missing PRs" is low → cherry-pick drift. Use Phase 2R.
If both are low → normal state, use regular merge.
If both are high → long-neglected sync, proceed carefully with Phase 3+.
