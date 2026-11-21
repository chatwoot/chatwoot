#!/usr/bin/env bash
# Sincroniza develop e main do fork com o upstream, SEM tocar na premium.
# Uso: scripts/sync-develop.sh
set -euo pipefail
cd "$(dirname "$0")/.."

git fetch upstream --tags

for b in develop main; do
  if git show-ref --verify --quiet "refs/heads/$b"; then
    git checkout "$b"
    git merge --ff-only "upstream/$b"
    git push origin "$b" || echo "AVISO: push de $b falhou (sem credenciais no servidor)."
    echo "branch '$b' sincronizada com upstream."
  else
    echo "branch '$b' não existe localmente; pulando."
  fi
done

git checkout premium
echo "develop/main sincronizadas. Branch atual: premium (intacta)."