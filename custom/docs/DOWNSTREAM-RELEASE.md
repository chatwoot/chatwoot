# CommMate Downstream & Release Process

**Purpose**: Guide for downstream new Chatwoot releases and creating CommMate versions.  
**Scope**: Branch management, merging, conflict resolution. (Docker builds covered in `IMAGE-RELEASE.md`)  
**Audience**: AI agents, senior developers managing CommMate releases  
**Last Updated**: December 2025

---

## Overview

CommMate maintains a parallel versioning strategy:
- **Downstream branches**: Pure upstream Chatwoot code (for reference/comparison)
- **CommMate branches**: Chatwoot + CommMate customizations
- **Main branch**: Always points to latest stable CommMate release

---

## Prerequisites

### Required Setup
```bash
# 1. Ensure upstream remote exists
git remote -v | grep upstream
# Should show: upstream https://github.com/chatwoot/chatwoot.git

# 2. If missing, add it
git remote add upstream https://github.com/chatwoot/chatwoot.git

# 3. Verify you're in correct directory
pwd
# Should be: /path/to/commmmate/chatwoot
```

### Required Tools
- Git 2.x+
- Fish or Bash shell
- Network access for GitHub push/pull

---

## Branch Naming Convention

| Branch Type | Pattern | Example | Purpose |
|-------------|---------|---------|---------|
| **Downstream** | `downstream/vX.Y.Z` | `downstream/v4.8.0` | Pure upstream Chatwoot code |
| **CommMate** | `commmate/vX.Y.Z` | `commmate/v4.8.0` | Chatwoot + CommMate customizations |
| **Main** | `main` | `main` | Latest stable CommMate release |

**CRITICAL**: 
- Downstream branches must NEVER contain CommMate customizations
- CommMate branches are created BY MERGING downstream INTO a branch based on current main
- Main is updated BY MERGING the new CommMate branch into it

---

## Complete Downstream & Release Process

### Phase 1: Fetch Latest Upstream

```bash
cd /path/to/commmmate/chatwoot

# Fetch all tags and branches from upstream Chatwoot
git fetch upstream --tags
git fetch upstream --all

# Verify new version exists
git tag | grep "v4.8.0"
# Expected: v4.8.0

# Check what's new in the release
git log --oneline v4.7.0..v4.8.0 --no-merges | head -20
```

**Expected Outcome:**
- ✅ New version tag appears in git tags
- ✅ You can see changelog between versions
- ✅ No errors fetching from upstream

---

### Phase 2: Create Downstream Branch

**Purpose**: Create a pure reference branch with upstream Chatwoot code

```bash
# IMPORTANT: Stash any local changes first
git stash push -m "temp: local changes before downstream"

# Checkout main and ensure clean state
git checkout main
git status
# Expected: "working tree clean"

# Create downstream branch from upstream tag
git checkout -b downstream/v4.8.0 v4.8.0

# Verify branch is at correct commit
git log --oneline -3
# Expected: Shows "Merge branch 'release/4.8.0'" as first commit

# Push to GitHub
git push -u origin downstream/v4.8.0
```

**Expected Outcome:**
- ✅ New branch `downstream/v4.8.0` created locally
- ✅ Branch points to exact upstream release tag
- ✅ Branch pushed to GitHub successfully
- ✅ No CommMate customizations in this branch

**Common Issues:**

<details>
<summary>❌ Error: "cannot lock ref 'refs/heads/downstream/v4.8.0'"</summary>

**Cause**: Conflicting branch name (e.g., `downstream` exists as a branch)

**Solution**:
```bash
git branch -D downstream  # Delete conflicting branch
git checkout -b downstream/v4.8.0 v4.8.0  # Recreate
```
</details>

<details>
<summary>❌ Error: "Your local changes would be overwritten"</summary>

**Cause**: Uncommitted changes in working tree

**Solution**:
```bash
git stash push -m "temp: saving local changes"
# Then retry checkout
git checkout -b downstream/v4.8.0 v4.8.0
```
</details>

---

### Phase 3: Create CommMate Release Branch

**Purpose**: Merge upstream code into a new CommMate version branch

```bash
# Return to main branch
git checkout main
git pull origin main

# Create new CommMate branch from main (includes all customizations)
git checkout -b commmate/v4.8.0

# Merge downstream branch (brings in Chatwoot v4.8.0 code)
git merge downstream/v4.8.0 --no-edit
```

**Expected Outcome:**
- ✅ New branch `commmate/v4.8.0` created from main
- ✅ Merge initiated (may have conflicts - see Phase 4)

**CRITICAL NOTES:**
- Always create CommMate branch FROM main (to preserve customizations)
- Then merge downstream INTO it (to add upstream updates)
- NEVER create CommMate branch from downstream (loses customizations!)

---

### Phase 4: Resolve Merge Conflicts

**Most Common Conflict**: `db/schema.rb` (migration version mismatch)

#### A. Check Conflict Status

```bash
git status
# Shows:
# Unmerged paths:
#   both modified:   db/schema.rb
```

#### B. View Conflict Details

```bash
# Find conflict markers
grep -n "<<<<<<" db/schema.rb

# Shows something like:
# 13:<<<<<<< HEAD
# 14:ActiveRecord::Schema[7.1].define(version: 2025_10_12_222355) do
# 15:=======
# 16:ActiveRecord::Schema[7.1].define(version: 2025_11_14_173609) do
# 17:>>>>>>> downstream/v4.8.0
```

#### C. Resolve Schema Conflict

**Rule**: Always use the NEWER schema version (from downstream)

```bash
# Accept theirs (downstream/v4.8.0 - the newer version)
git checkout --theirs db/schema.rb

# Stage resolved file
git add db/schema.rb

# Verify no more conflicts
git status
# Expected: "All conflicts fixed but you are still merging"
```

#### D. Complete the Merge

```bash
# Commit the merge
git commit -m "chore: merge downstream/v4.8.0 into commmate/v4.8.0"

# Verify merge success
git log --oneline --graph -5
# Expected: Shows merge commit at top
```

**Expected Outcome:**
- ✅ All conflicts resolved
- ✅ Merge commit created
- ✅ Branch ready for testing

**Other Potential Conflicts:**

<details>
<summary>Conflict in: app/views/layouts/vueapp.html.erb</summary>

**Common Cause**: CommMate branding changes vs upstream updates

**Resolution Strategy**:
1. Open file, find `<<<<<<< HEAD` markers
2. Keep CommMate customizations (HEAD) for branding/styling
3. Accept upstream (theirs) for new functionality
4. Manual merge if both needed

```bash
# View conflict
cat app/views/layouts/vueapp.html.erb | grep -A5 -B5 "<<<<<<" 

# Resolve manually or accept one side
git checkout --ours app/views/layouts/vueapp.html.erb   # Keep CommMate
# OR
git checkout --theirs app/views/layouts/vueapp.html.erb # Use upstream

git add app/views/layouts/vueapp.html.erb
```
</details>

<details>
<summary>Conflict in: config/installation_config.yml</summary>

**Common Cause**: CommMate config vs upstream config updates

**Resolution Strategy**: Always keep CommMate version (ours)

```bash
git checkout --ours config/installation_config.yml
git add config/installation_config.yml
```

**Reason**: `custom/config/installation_config.yml` contains CommMate branding and will override anyway via initializer.
</details>

<details>
<summary>Conflict in: custom/* files</summary>

**Resolution**: Always keep ours (CommMate customizations)

```bash
git checkout --ours custom/
git add custom/
```

**Reason**: Custom folder is CommMate-specific, not in upstream.
</details>

---

### Phase 5: Push CommMate Branch to GitHub

```bash
# Still on commmate/v4.8.0 branch
git branch --show-current
# Expected: commmate/v4.8.0

# Push to GitHub
git push -u origin commmate/v4.8.0
```

**Expected Outcome:**
- ✅ Branch `commmate/v4.8.0` available on GitHub
- ✅ GitHub shows merge commit with both histories
- ✅ Ready for testing/CI/CD

---

### Phase 6: Update Main Branch

**Purpose**: Make the new CommMate version the default/stable release

```bash
# Checkout main
git checkout main

# Ensure main is up to date
git pull origin main

# Merge the new CommMate version (should be fast-forward)
git merge commmate/v4.8.0 --no-edit

# Verify merge
git log --oneline -3
# Expected: Same commits as commmate/v4.8.0

# Push updated main
git push origin main
```

**Expected Outcome:**
- ✅ Main branch fast-forwarded to CommMate v4.8.0
- ✅ Main pushed to GitHub
- ✅ Main now points to latest stable release

**IMPORTANT**: This should always be a fast-forward merge. If not, something went wrong.

---

## Verification Checklist

After completing all phases, verify:

```bash
# 1. Check all branches exist
git branch -a | grep -E "downstream/v4.8.0|commmate/v4.8.0|main"

# Expected output:
#   commmate/v4.8.0
#   downstream/v4.8.0
#   main
#   remotes/origin/commmate/v4.8.0
#   remotes/origin/downstream/v4.8.0
#   remotes/origin/main

# 2. Verify downstream is pure upstream
git log downstream/v4.8.0 -1
# Expected: "Merge branch 'release/4.8.0'" (Chatwoot commit)

# 3. Verify CommMate has merge commit
git log commmate/v4.8.0 -1
# Expected: "chore: merge downstream/v4.8.0 into commmate/v4.8.0"

# 4. Verify main matches CommMate branch
git rev-parse main
git rev-parse commmate/v4.8.0
# Expected: Same commit hash

# 5. Check that CommMate customizations still exist
ls -la custom/config/initializers/commmate_config_overrides.rb
ls -la custom/config/installation_config.yml
ls -la custom/assets/logos/
# Expected: All files present
```

**All checks passing** = ✅ Release ready for Docker build (see `IMAGE-RELEASE.md`)

---

## Complete Example: Release v4.8.0

This is a complete walkthrough for reference:

```bash
# ============================================
# PHASE 1: FETCH UPSTREAM
# ============================================
cd /path/to/commmmate/chatwoot
git fetch upstream --tags --all
git tag | grep v4.8.0
# ✅ v4.8.0

# ============================================
# PHASE 2: CREATE DOWNSTREAM BRANCH
# ============================================
git checkout main
git stash  # If needed
git checkout -b downstream/v4.8.0 v4.8.0
git push -u origin downstream/v4.8.0
# ✅ downstream/v4.8.0 created and pushed

# ============================================
# PHASE 3: CREATE COMMMATE BRANCH
# ============================================
git checkout main
git pull origin main
git checkout -b commmate/v4.8.0
git merge downstream/v4.8.0 --no-edit
# ⚠️ CONFLICT in db/schema.rb

# ============================================
# PHASE 4: RESOLVE CONFLICTS
# ============================================
git checkout --theirs db/schema.rb
git add db/schema.rb
git commit -m "chore: merge downstream/v4.8.0 into commmate/v4.8.0"
# ✅ Merge completed

# ============================================
# PHASE 5: PUSH COMMMATE BRANCH
# ============================================
git push -u origin commmate/v4.8.0
# ✅ commmate/v4.8.0 pushed

# ============================================
# PHASE 6: UPDATE MAIN
# ============================================
git checkout main
git merge commmate/v4.8.0 --no-edit
git push origin main
# ✅ main updated to v4.8.0

# ============================================
# VERIFICATION
# ============================================
git branch -a | grep -E "downstream/v4.8.0|commmate/v4.8.0|main"
# ✅ All branches present

git log --oneline --graph -5
# ✅ Shows merge history
```

---

## Branch Relationship Diagram

```
upstream/master (Chatwoot Official)
    │
    ├─ v4.7.0 tag ──> downstream/v4.7.0 (reference only)
    │                        │
    │                        └──> commmate/v4.7.0 ──> main (was here)
    │                                    │
    │                                    └─ CommMate customizations
    │
    ├─ v4.8.0 tag ──> downstream/v4.8.0 (new - pure upstream)
                             │
                             └──> commmate/v4.8.0 (new - merge)
                                         │
                                         └──> main (updated here)
```

**Key Points:**
1. Downstream branches = pure Chatwoot code snapshots
2. CommMate branches = main (customizations) + downstream (updates)
3. Main = always latest CommMate stable release

---

## What Gets Merged

### From Downstream (Chatwoot v4.8.0):
- ✅ New features and improvements
- ✅ Bug fixes
- ✅ Security patches
- ✅ Database migrations
- ✅ Dependency updates
- ✅ Translation updates

### From Main (CommMate Customizations):
- ✅ Branding system (`custom/config/initializers/commmate_config_overrides.rb`)
- ✅ Privacy controls (disabled Chatwoot Hub connections)
- ✅ Custom configs (`custom/config/installation_config.yml`)
- ✅ Custom seeds (`custom/db/seeds_commmate.rb`)
- ✅ Custom assets (logos, favicons)
- ✅ Custom styles (`custom/styles/`)
- ✅ Custom documentation (`custom/docs/`)

**Result**: CommMate v4.8.0 = Chatwoot v4.8.0 features + CommMate branding & privacy

---

## Conflict Resolution Strategies

### 1. db/schema.rb (Most Common)

**Rule**: Always use downstream version (newer migrations)

```bash
git checkout --theirs db/schema.rb
git add db/schema.rb
```

**Why**: Schema version from downstream includes all new migrations. Main's schema is older.

### 2. config/installation_config.yml

**Rule**: Keep CommMate version

```bash
git checkout --ours config/installation_config.yml
git add config/installation_config.yml
```

**Why**: `custom/config/installation_config.yml` overrides this via initializer anyway.

### 3. app/views/layouts/vueapp.html.erb

**Rule**: Manual review required

**Strategy**:
1. Check if conflict is in `<head>` section (likely CommMate meta tags)
2. Keep CommMate customizations in `<head>`
3. Accept upstream changes in `<body>`

```bash
# View conflict
cat app/views/layouts/vueapp.html.erb | grep -A10 -B10 "<<<<<<" 

# Resolve manually with editor
code app/views/layouts/vueapp.html.erb

# After resolving
git add app/views/layouts/vueapp.html.erb
```

### 4. custom/* (Any Custom Files)

**Rule**: Always keep ours (CommMate)

```bash
git checkout --ours custom/
git add custom/
```

**Why**: These files don't exist in upstream Chatwoot.

### 5. lib/chatwoot_hub.rb

**Rule**: Keep CommMate version

```bash
git checkout --ours lib/chatwoot_hub.rb
git add lib/chatwoot_hub.rb
```

**Why**: Contains `DISABLE_CHATWOOT_CONNECTIONS` checks added by CommMate.

---

## Post-Merge Verification

After merging, verify customizations are intact:

```bash
# 1. Check initializer exists
cat custom/config/initializers/commmate_config_overrides.rb | head -5
# Expected: "# CommMate Configuration Overrides"

# 2. Check installation config
cat custom/config/installation_config.yml | grep "INSTALLATION_NAME"
# Expected: "value: 'CommMate'"

# 3. Check Chatwoot Hub is disabled
grep "DISABLE_CHATWOOT_CONNECTIONS" lib/chatwoot_hub.rb
# Expected: Multiple return statements with this check

# 4. Check branding migration exists
ls db/migrate/*apply_commmate_branding*
# Expected: db/migrate/20251102174650_apply_commmate_branding.rb

# 5. Check logos
ls -la custom/assets/logos/
# Expected: logo-full.png, logo-icon.png, etc.
```

**All checks pass** = ✅ Ready for Docker build (see `IMAGE-RELEASE.md`)

---

## Rollback Procedures

### Rollback Failed Merge

```bash
# If merge went wrong and NOT YET PUSHED
git merge --abort
git checkout main

# If already committed but NOT pushed
git reset --hard origin/commmate/v4.8.0  # If it exists
# OR
git reset --hard HEAD~1  # Undo last commit

# If already pushed (extreme case)
# DON'T FORCE PUSH - create a revert commit instead
git revert -m 1 HEAD
git push origin commmate/v4.8.0
```

### Rollback Main Branch Update

```bash
# If main was updated incorrectly
git checkout main
git reset --hard origin/main  # Reset to remote state

# If remote main is wrong too
git reset --hard commmate/v4.7.0.1  # Reset to previous version
# DON'T FORCE PUSH to main without team agreement
```

---

## Next Steps After Successful Downstream

Once all phases complete successfully:

### 1. Test the New Branch Locally (Optional)

```bash
git checkout commmate/v4.8.0

# Restore local changes if any
git stash pop

# Run local tests (if applicable)
bundle install
pnpm install
bundle exec rspec spec/models/installation_config_spec.rb
```

### 2. Build Docker Image → NEXT STEP

**See**: `IMAGE-RELEASE.md` for complete image build and publishing process

Quick reference:
```bash
# Complete process in IMAGE-RELEASE.md
./custom/script/build_multiplatform.sh v4.8.0
podman manifest push commmate/commmate:v4.8.0 docker://commmate/commmate:v4.8.0
podman manifest push commmate/commmate:v4.8.0 docker://commmate/commmate:latest
```

### 3. Deploy to Production

**See**: `DOCKER-SETUP.md` for production deployment details

---

## Version Numbering

### CommMate Version Strategy

CommMate uses a patch-increment strategy to track customizations:

| Chatwoot Version | CommMate Version | Git Tag | Docker Tag | Notes |
|------------------|------------------|---------|------------|-------|
| v4.7.0 | v4.7.0 | v4.7.0-commmate | v4.7.0 | Initial downstream |
| v4.7.0 | v4.7.0.1 | v4.7.0.1-commmate | v4.7.0.1 | CommMate patch |
| v4.9.1 | v4.9.1.3 | v4.9.1.3-commmate | v4.9.1.3 | Evolution WhatsApp inbox |

**Version Configuration File**: `custom/config/commmate_version.yml`

```yaml
# For downstream release (new Chatwoot version)
commmate_version: '4.9.0'
base_chatwoot_version: '4.9.0'

# For CommMate patch (customization only)
commmate_version: '4.8.0.1'
base_chatwoot_version: '4.8.0'
```

### When to Increment

**Downstream Release** (Major.Minor.Patch):
- New Chatwoot version downstreamed
- Both versions match: `4.9.0` based on `4.9.0`
- Update both fields in `commmate_version.yml`

**CommMate Patch** (Major.Minor.Patch.CommMatePatch):
- CommMate-only changes (branding, features, fixes)
- Increment: `4.8.0` → `4.8.0.1` → `4.8.0.2`
- Only update `commmate_version`, keep `base_chatwoot_version` same
- Examples: admin branding, custom features, bug fixes

---

## Troubleshooting

### Issue: "Merge conflict in 500+ files"

**Cause**: Merging in wrong direction or from wrong base

**Solution**:
```bash
git merge --abort
# Verify you're on commmate/v4.8.0 (created from main)
git branch --show-current
# Verify you're merging downstream INTO commmate
git merge downstream/v4.8.0
```

### Issue: "CommMate customizations missing after merge"

**Cause**: Created CommMate branch from downstream instead of main

**Solution**: Start over
```bash
git checkout main
git branch -D commmate/v4.8.0
git checkout -b commmate/v4.8.0  # From main this time!
git merge downstream/v4.8.0
```

### Issue: "Cannot push - rejected"

**Cause**: Diverged history or network issue

**Solutions**:
```bash
# Pull latest first
git pull origin commmate/v4.8.0 --rebase

# OR verify network
git remote -v
ping github.com

# OR check authentication
git push -v origin commmate/v4.8.0
```

### Issue: "Bundler version mismatch during commit"

**Cause**: Git hooks trying to run rubocop/bundler that's not installed locally

**Solution**: Ignore (hooks run in CI anyway) OR:
```bash
gem install bundler:2.5.16
bundle install
```

**Note**: Commit will succeed anyway - these are just warnings.

---

## Reference: Complete Branch List

After a successful release cycle to v4.8.0:

```bash
$ git branch -a | grep -E "downstream|commmate|main"

# Local branches
  commmate/v4.7.0
  commmate/v4.7.0.1
  commmate/v4.8.0       ← NEW
  downstream/v4.7.0
  downstream/v4.8.0     ← NEW
* main                  ← UPDATED to v4.8.0

# Remote branches  
  remotes/origin/commmate/v4.7.0
  remotes/origin/commmate/v4.7.0.1
  remotes/origin/commmate/v4.8.0       ← NEW
  remotes/origin/downstream/v4.7.0
  remotes/origin/downstream/v4.8.0     ← NEW
  remotes/origin/main                  ← UPDATED
```

---

## Time Estimates

| Phase | Estimated Time | Complexity |
|-------|---------------|------------|
| Fetch upstream | 1-2 min | Low |
| Create downstream | 1-2 min | Low |
| Create CommMate branch | 1 min | Low |
| Resolve conflicts | 5-30 min | **Medium-High** |
| Push branches | 2-3 min | Low |
| Update main | 1-2 min | Low |
| **Total** | **15-45 min** | Medium |

**Note**: Time varies based on:
- Number of conflicts
- Size of changes between versions
- Network speed
- Local git performance

---

## Success Criteria

✅ **Downstream branch created**: Pure upstream Chatwoot code  
✅ **CommMate branch created**: Upstream + customizations merged  
✅ **All conflicts resolved**: No remaining conflict markers  
✅ **Customizations intact**: Initializers, configs, assets present  
✅ **Branches pushed**: All on GitHub  
✅ **Main updated**: Points to latest CommMate version  
✅ **No force pushes**: Clean git history maintained  
✅ **Verification passed**: All checks in "Post-Merge Verification" section  

---

## Related Documentation

- **Image Build**: See `IMAGE-RELEASE.md` for building and publishing Docker images (NEXT STEP)
- **Docker Setup**: See `DOCKER-SETUP.md` for running containers in development
- **Branding**: See `REBRANDING.md` for complete branding system and environment variables
- **Upgrade**: See `UPGRADE.md` for upgrading existing installations
- **Development**: See `DEVELOPMENT.md` for local development setup

---

## Quick Reference Commands

```bash
# Create downstream branch
git checkout -b downstream/vX.Y.Z vX.Y.Z
git push -u origin downstream/vX.Y.Z

# Create CommMate branch (from main!)
git checkout main
git checkout -b commmate/vX.Y.Z
git merge downstream/vX.Y.Z

# Resolve schema conflict (most common)
git checkout --theirs db/schema.rb
git add db/schema.rb
git commit

# Push and update main
git push -u origin commmate/vX.Y.Z
git checkout main
git merge commmate/vX.Y.Z
git push origin main
```

---

**Last Updated**: January 14, 2026  
**Process Version**: 2.1  
**Tested With**: Chatwoot v4.9.1 → CommMate v4.9.1.3  
**Maintained By**: CommMate Team

