#!/usr/bin/env bash
set -euo pipefail

# Uso:
#  ./scripts/docker-build-safe.sh [--user USERNAME] [--skip-login] -- [build-producao.sh args...]
# Exemplo:
#  ./scripts/docker-build-safe.sh --user witrocha -- -v v4.4 --latest --no-push
#
# Se a variável DOCKER_PWD estiver definida, o script usará --password-stdin (mais seguro).
# Sem DOCKER_PWD, será solicitado a senha interativamente.

print_usage() {
  cat <<EOF
Usage: $0 [--user USERNAME] [--skip-login] -- [build args...]
  --user USERNAME    Docker username (default: whoami)
  --skip-login       Do not perform docker login (useful if you already have valid auth)
  --                 Separator; everything after is passed to ./build-producao.sh
EOF
}

# defaults
USERNAME="$(whoami)"
SKIP_LOGIN=0
BUILD_ARGS=()

# parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --user) USERNAME="$2"; shift 2 ;;
    --skip-login) SKIP_LOGIN=1; shift ;;
    --) shift; BUILD_ARGS=("$@"); break ;;
    -h|--help) print_usage; exit 0 ;;
    *) echo "Unknown arg: $1"; print_usage; exit 2 ;;
  esac
done

# If DOCKER_PWD is not set, try to read docker_dckr_pat from a .env file in the repo root
# We do NOT 'source' the file to avoid executing arbitrary code; just parse the key value.
if [[ -z "${DOCKER_PWD-}" && -f .env ]]; then
  docker_pat_line=$(grep -m1 -E '^\s*docker_dckr_pat\s*=' .env || true)
  if [[ -n "$docker_pat_line" ]]; then
    # extract value after '=' and strip surrounding quotes
    docker_pat_value=$(printf '%s' "$docker_pat_line" | sed -E 's/^[^=]*=//')
    # remove leading/trailing quotes if present
    docker_pat_value=${docker_pat_value%"}
    docker_pat_value=${docker_pat_value#"}
    docker_pat_value=${docker_pat_value%\'}
    docker_pat_value=${docker_pat_value#\'}
    if [[ -n "$docker_pat_value" ]]; then
      DOCKER_PWD="$docker_pat_value"
      export DOCKER_PWD
      echo "Loaded docker PAT from .env (docker_dckr_pat)."
      echo "Note: storing PAT in repository files is insecure — consider using environment variables or a secrets manager."
    fi
  fi
fi

TMP_DOCKER_CONFIG="$(mktemp -d)"
# ensure cleanup
cleanup() { rm -rf "$TMP_DOCKER_CONFIG"; }
trap cleanup EXIT

umask 077
mkdir -p "$TMP_DOCKER_CONFIG"
echo '{}' > "$TMP_DOCKER_CONFIG/config.json"
export DOCKER_CONFIG="$TMP_DOCKER_CONFIG"

if [[ "$SKIP_LOGIN" -eq 0 ]]; then
  if [[ -n "${DOCKER_PWD-}" ]]; then
    # use password via stdin and force the temporary DOCKER_CONFIG to avoid system credential helpers
    printf '%s' "$DOCKER_PWD" | DOCKER_CONFIG="$TMP_DOCKER_CONFIG" docker login --username "$USERNAME" --password-stdin
  else
    echo "Performing interactive docker login for user: $USERNAME (using temporary DOCKER_CONFIG)"
    DOCKER_CONFIG="$TMP_DOCKER_CONFIG" docker login --username "$USERNAME"
  fi
else
  echo "Skipping docker login as requested (--skip-login)."
fi

# Run the build script with the temporary DOCKER_CONFIG to avoid using the host ~/.docker config
echo "Running: DOCKER_CONFIG=$TMP_DOCKER_CONFIG ./build-producao.sh ${BUILD_ARGS[*]}"
DOCKER_CONFIG="$TMP_DOCKER_CONFIG" ./build-producao.sh "${BUILD_ARGS[@]}"