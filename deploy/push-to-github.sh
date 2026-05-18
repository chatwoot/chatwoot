#!/usr/bin/env bash
# push-to-github.sh
# -----------------
# Roda no SEU PC. Aplica o overlay (engines + patches) num clone fresco do
# fork e faz push para a branch feat/kanban-engine no GitHub.
#
# Pré-requisitos:
#   - git instalado e configurado (`git config --global user.email/.name`)
#   - SSH key do GitHub configurada OU PAT no git credential helper
#   - este script rodando do diretório que contém engines/ e deploy/
#
# Uso:
#   ./push-to-github.sh
#   ./push-to-github.sh /caminho/para/clone-existente   # se você já clonou

set -euo pipefail

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'
log()  { echo -e "${BLUE}[push]${NC} $*"; }
ok()   { echo -e "${GREEN}[ ok ]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
die()  { echo -e "${RED}[fail]${NC} $*"; exit 1; }

OVERLAY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORK_DIR="${1:-/tmp/chatwoot-pro-push}"
FORK_REPO="${FORK_REPO:-https://github.com/fabriciomuaca1989/chatwoot-pro.git}"
BRANCH="${BRANCH:-feat/kanban-engine}"

if [[ ! -d "$OVERLAY_DIR/engines/chatwoot_kanban" ]]; then
  die "Run this script from inside the chatwootPro/ folder (the one containing engines/)"
fi

# ---- 1. Clone or reuse the fork ---------------------------------------------
if [[ -d "$FORK_DIR/.git" ]]; then
  log "Reusing existing clone at $FORK_DIR"
  cd "$FORK_DIR"
  # Clean leftover overlay files from previous runs so checkout doesn't abort
  git reset --hard >/dev/null 2>&1 || true
  git clean -fdx >/dev/null 2>&1 || true
  git fetch origin
  git checkout -B "$BRANCH" origin/develop 2>/dev/null || git checkout -B "$BRANCH"
else
  log "Cloning $FORK_REPO into $FORK_DIR ..."
  git clone "$FORK_REPO" "$FORK_DIR"
  cd "$FORK_DIR"
  git checkout -B "$BRANCH"
fi
ok "On branch $BRANCH"

# ---- 2. Copy overlay --------------------------------------------------------
log "Copying engines + deploy + frontend module ..."
mkdir -p engines deploy app/javascript/dashboard/modules
cp -r "$OVERLAY_DIR/engines/." engines/
cp -r "$OVERLAY_DIR/deploy/." deploy/
# Resolve the frontend symlink to real files
rm -rf app/javascript/dashboard/modules/kanban
cp -r "$OVERLAY_DIR/engines/chatwoot_kanban/frontend" app/javascript/dashboard/modules/kanban
ok "Files copied."

# ---- 3. Apply host edits ----------------------------------------------------
log "Applying host edits (Gemfile, routes.rb, store, dashboard routes) ..."
bash deploy/apply-host-edits.sh .
ok "Host edits applied."

# ---- 4. Make deploy scripts executable --------------------------------------
chmod +x deploy/*.sh

# ---- 5. Stage + commit ------------------------------------------------------
log "Staging changes ..."
git add engines/ deploy/ \
        Gemfile config/routes.rb \
        app/javascript/dashboard/store/index.js \
        app/javascript/dashboard/routes/dashboard/dashboard.routes.js \
        app/javascript/dashboard/modules/kanban \
        2>&1 || true

# Some Chatwoot repos ignore engines/ — force-add if needed
git add -f engines/ 2>/dev/null || true

if git diff --cached --quiet; then
  warn "No changes to commit — branch already up to date."
else
  git commit -m "feat: add Chatwoot Kanban engine + deploy scripts

- engines/chatwoot_kanban: full Rails engine (models, controllers,
  policies, services, ActionCable channel, listeners, jbuilders, specs)
- engines/chatwoot_glpi_integration: GLPI 11.x OAuth2 integration engine
- 5 host edits (Gemfile, routes.rb, frontend store + routes, modules/kanban)
- deploy/: docker-compose, Caddyfile, Coolify compose, bootstrap script,
  smoke tests, runbook, upstream sync strategy"
  ok "Commit created."
fi

# ---- 6. Push ----------------------------------------------------------------
log "Pushing to origin/$BRANCH ..."
git push -u origin "$BRANCH"
ok "Pushed."

# ---- 7. Final hint ----------------------------------------------------------
cat <<DONE

${GREEN}========================================================================${NC}
${GREEN}  Push successful${NC}
${GREEN}========================================================================${NC}

  Branch: $BRANCH
  Repo:   $FORK_REPO

  Next step on Coolify:
    1. Sources → connect this fork (if not already)
    2. New Application → Docker Compose → branch $BRANCH
    3. Compose file: deploy/docker-compose.coolify.yaml
    4. Paste env vars from deploy/COOLIFY_DEPLOY.md section 5
    5. Deploy

  See deploy/COOLIFY_DEPLOY.md for the full Coolify walkthrough.

DONE
