#!/usr/bin/env bash
# [whisker] Conventional-commit driven SemVer bump.
# Reads commits since the last tag and prints the next version tag:
#   BREAKING CHANGE / feat!:/fix!:  -> major
#   feat:                           -> minor
#   fix:/perf:                      -> patch
#   nothing relevant                -> prints "none"
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

LAST_TAG="$(git describe --tags --abbrev=0 2>/dev/null || true)"
RANGE="${LAST_TAG:+${LAST_TAG}..HEAD}"
RANGE="${RANGE:-HEAD}"

SUBJECTS="$(git log --pretty=format:%s ${RANGE})"

MAJOR=0 MINOR=0 PATCH=0
while IFS= read -r subject; do
  [ -z "$subject" ] && continue
  case "$subject" in
    *"!"*":"*|BREAKING\ CHANGE*|breaking*) MAJOR=1 ;;
    feat*|FEAT*) MINOR=1 ;;
    fix*|perf*|FIX*|PERF*) PATCH=1 ;;
  esac
done <<< "${SUBJECTS}"

CURRENT="$(sed -nE "s/^  version: '([^']+)'.*/\1/p" config/app.yml | head -n1)"
[ -z "$CURRENT" ] && { echo "cannot read current version from config/app.yml" >&2; exit 1; }
IFS='.' read -r MA MI PA <<< "$CURRENT"

if [ "$MAJOR" -eq 1 ]; then
  MA=$((MA + 1)); MI=0; PA=0
elif [ "$MINOR" -eq 1 ]; then
  MI=$((MI + 1)); PA=0
elif [ "$PATCH" -eq 1 ]; then
  PA=$((PA + 1))
else
  echo "none"
  exit 0
fi

echo "v${MA}.${MI}.${PA}"
