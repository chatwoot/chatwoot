# Upstream Sync

## Overview

AirysChat is a fork of [chatwoot/chatwoot](https://github.com/chatwoot/chatwoot). To receive security patches and bug fixes, we periodically pull from the upstream repository.

## Git Remotes

```
origin    → git@github.com:gabrieldeholanda/AirysChat.git  (push enabled)
upstream  → https://github.com/chatwoot/chatwoot.git       (push DISABLED)
```

The upstream push URL is set to `no_push` to prevent accidental pushes to the original Chatwoot repo.

### Setup (one-time)

```bash
git remote add upstream https://github.com/chatwoot/chatwoot.git
git remote set-url --push upstream no_push
```

## Automated Weekly Sync

A GitHub Actions workflow runs every Monday at 00:00 UTC:

**File:** `.github/workflows/upstream-sync.yml`

### What it does

1. Fetches `upstream/develop`
2. Checks if the fork is behind upstream
3. If behind: creates a branch `upstream-sync/YYYY-MM-DD`
4. Merges upstream with `--strategy-option=ours` (our changes win on conflicts)
5. Opens a PR against `develop` for manual review

### Manual trigger

The workflow can also be triggered manually from GitHub Actions → Upstream Sync → Run workflow.

## Manual Sync

For more control, sync manually:

```bash
# Fetch upstream changes
git fetch upstream

# See what's new
git log HEAD..upstream/develop --oneline

# Create a sync branch
git checkout -b upstream-sync/$(date +%Y-%m-%d)

# Merge (review conflicts carefully)
git merge upstream/develop

# Resolve conflicts, then push
git push origin upstream-sync/$(date +%Y-%m-%d)
```

## Merging Specific Releases

To pull a specific Chatwoot release:

```bash
# Fetch tags
git fetch upstream --tags

# List available versions
git tag -l 'v*' | sort -V | tail -20

# Merge a specific tag
git checkout -b upstream-sync/v4.1.0
git merge v4.1.0

# Resolve conflicts and push
git push origin upstream-sync/v4.1.0
```

## Conflict Resolution Strategy

### Low-risk files (auto-resolve)

Files that rarely conflict because we don't modify them:
- `app/controllers/` (core)
- `app/models/` (core)
- `app/services/` (core)
- `lib/` (core)

### High-attention files

Files we've modified that need careful review on merge:
- `config/application.rb` — our `saas/` autoload paths
- `config/routes.rb` — our SaaS route block
- `lib/chatwoot_app.rb` — our `extensions` override
- `config/installation_config.yml` — brand settings
- `theme/colors.js` — brand color
- `Gemfile` / `package.json` — dependency additions

### Safe files (ours always wins)

Files entirely under our control that should never accept upstream changes:
- `saas/` — entire directory
- `.github/workflows/upstream-sync.yml`
- `docs/`
- Locale files (brand name replacements)

## Best Practices

1. **Review every sync PR** — Don't auto-merge. Check for breaking changes in Chatwoot's changelog.
2. **Run tests after merge** — `bundle exec rspec` and `pnpm test` to catch integration issues.
3. **Keep saas/ isolated** — The less we modify core Chatwoot files, the fewer merge conflicts.
4. **Pin to releases** — For stability, prefer merging tagged releases over tracking `develop` head.
5. **Check Chatwoot changelog** — https://github.com/chatwoot/chatwoot/releases for breaking changes before merging.
