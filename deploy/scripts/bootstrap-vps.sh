#!/bin/bash
# ============================================================================
# Bootstrap idempotente do layout canônico /opt/synapseos/ na VPS.
# ============================================================================
# Estrutura criada:
#   /opt/synapseos/
#     ├── stack/<client>/        — compose/stack files por cliente
#     ├── scripts/               — deploy/backup/wipe scripts compartilhados
#     ├── sql/                   — SQL one-off (wipe, migrations, fix-it)
#     ├── backups/<client>/      — pg_dumps timestamped
#     └── README.md              — quick reference do layout
#
# Usage (na VPS, primeira vez):
#   sudo bash bootstrap-vps.sh
#
# Re-rodar é seguro (idempotente): só cria o que não existe, não sobrescreve.

set -euo pipefail

ROOT=/opt/synapseos
CLIENT="${SYNAPSEOS_CLIENT:-audi}"
OWNER="${SUDO_USER:-ubuntu}"

echo "==> Bootstrap /opt/synapseos/ (cliente: ${CLIENT}, owner: ${OWNER})"

# 1. Diretórios canônicos
sudo mkdir -p \
  "${ROOT}/stack/${CLIENT}" \
  "${ROOT}/scripts" \
  "${ROOT}/sql/wipe" \
  "${ROOT}/sql/migrations" \
  "${ROOT}/backups/${CLIENT}"

sudo chown -R "${OWNER}:${OWNER}" "${ROOT}"

# 2. Migrar artefatos legados do ~ pro layout novo
HOME_DIR="/home/${OWNER}"

# 2a. Backups antigos em ~/backups/ → /opt/synapseos/backups/<client>/legacy/
if [ -d "${HOME_DIR}/backups" ] && [ ! -L "${HOME_DIR}/backups" ]; then
  echo "==> Movendo ~/backups/ → ${ROOT}/backups/${CLIENT}/legacy/"
  mkdir -p "${ROOT}/backups/${CLIENT}/legacy"
  mv "${HOME_DIR}/backups/"* "${ROOT}/backups/${CLIENT}/legacy/" 2>/dev/null || true
  rmdir "${HOME_DIR}/backups" 2>/dev/null || true
  ln -s "${ROOT}/backups/${CLIENT}" "${HOME_DIR}/backups"
  echo "    (~/backups agora é symlink pra ${ROOT}/backups/${CLIENT})"
fi

# 2b. Scripts soltos em ~/ → /opt/synapseos/scripts/
for script in 00-backup-postgres.sh 04-redeploy-chatwoot.sh 05-rolling-update.sh; do
  if [ -f "${HOME_DIR}/${script}" ] && [ ! -e "${ROOT}/scripts/${script}" ]; then
    echo "==> Movendo ~/${script} → ${ROOT}/scripts/"
    mv "${HOME_DIR}/${script}" "${ROOT}/scripts/"
  fi
done

# 3. README do layout
cat > "${ROOT}/README.md" <<'EOF'
# /opt/synapseos/

Layout canônico de operações da VPS. Cada cliente Synapseos roda como stack
isolado dentro de `stack/<client>/`. Scripts e SQLs são compartilhados.

## Estrutura

```
stack/
  audi/                 — Audi piloto (chatwoot fork synapseos)
    docker-compose.prod.yml
    .env
scripts/
  00-backup-postgres.sh — pg_dump postgres + pgvector → backups/<client>/
  04-redeploy-chatwoot.sh — first-install only (DESTRUTIVO)
  05-rolling-update.sh  — swarm service update sem perder volumes
  06-db-wipe.sh         — wrapper que roda os SQLs de sql/wipe/
sql/
  wipe/                 — reset zero-state (chatwoot + synapseos_audi)
  migrations/           — patches manuais avulsos
backups/
  audi/                 — pg_dumps timestamped (também symlinked de ~/backups)
```

## Deploy típico (rolling update + zero-state)

```bash
cd /opt/synapseos
bash scripts/00-backup-postgres.sh                            # backup ANTES
bash scripts/05-rolling-update.sh v0.X.Y-synapseos            # roll image
bash scripts/06-db-wipe.sh audi                               # reset state (opt)
```

## Adicionar cliente novo

```bash
sudo SYNAPSEOS_CLIENT=<slug> bash /opt/synapseos/scripts/bootstrap-vps.sh
# então scp do stack file pro stack/<slug>/
```
EOF
sudo chown "${OWNER}:${OWNER}" "${ROOT}/README.md"

# 4. Resumo
echo ""
echo "==> Bootstrap OK. Layout:"
tree -L 2 "${ROOT}" 2>/dev/null || find "${ROOT}" -maxdepth 2 -type d | sort

echo ""
echo "==> Próximos passos:"
echo "    1. scp do seu Mac:"
echo "       scp /tmp/wipe_*.sql ubuntu@<vps>:${ROOT}/sql/wipe/"
echo "       scp deploy/scripts/0[0-6]-*.sh ubuntu@<vps>:${ROOT}/scripts/"
echo "    2. (opcional) scp do compose file:"
echo "       scp docker-compose.prod.yml ubuntu@<vps>:${ROOT}/stack/${CLIENT}/"
