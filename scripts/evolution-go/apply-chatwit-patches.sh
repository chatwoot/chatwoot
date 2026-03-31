#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVOLUTION_DIR="${1:-$ROOT_DIR/evolution-go}"
PATCH_SPECS=(
  "$ROOT_DIR/patches/evolution-go/0001-disable-license-gate.patch|pkg/core/c0.go|chatwitLicenseBypass = true"
  "$ROOT_DIR/patches/evolution-go/0002-disable-external-telemetry.patch|pkg/telemetry/telemetry.go|_ = route"
)

format_target() {
  local target_file="$1"
  local relative_target="$2"

  case "$target_file" in
    *.go) ;;
    *) return ;;
  esac

  if command -v gofmt >/dev/null 2>&1; then
    gofmt -w "$target_file"
    return
  fi

  if command -v docker >/dev/null 2>&1; then
    docker run --rm -v "$EVOLUTION_DIR:/src" -w /src golang:1.25 gofmt -w "$relative_target" >/dev/null
    return
  fi

  echo "[evolution-go] Aviso: gofmt indisponível; patch aplicado sem formatação." >&2
}

apply_patch_if_missing() {
  local patch_file="$1"
  local relative_target="$2"
  local marker="$3"
  local target_file="$EVOLUTION_DIR/$relative_target"

  if [ ! -e "$target_file" ]; then
    echo "[evolution-go] Arquivo alvo não encontrado em $target_file" >&2
    exit 1
  fi

  if [ ! -e "$patch_file" ]; then
    echo "[evolution-go] Patch não encontrado em $patch_file" >&2
    exit 1
  fi

  if grep -q "$marker" "$target_file"; then
    echo "[evolution-go] Patch $(basename "$patch_file") já aplicado."
    return
  fi

  if ! git -C "$EVOLUTION_DIR" apply --check --whitespace=nowarn "$patch_file"; then
    echo "[evolution-go] Não foi possível reaplicar $(basename "$patch_file") no upstream atual." >&2
    echo "[evolution-go] Revise $patch_file e atualize a documentação em chatwitdocs antes de seguir." >&2
    exit 1
  fi

  git -C "$EVOLUTION_DIR" apply --whitespace=nowarn "$patch_file"
  format_target "$target_file" "$relative_target"
  echo "[evolution-go] Patch $(basename "$patch_file") reaplicado com sucesso."
}

for spec in "${PATCH_SPECS[@]}"; do
  IFS='|' read -r patch_file relative_target marker <<< "$spec"
  apply_patch_if_missing "$patch_file" "$relative_target" "$marker"
done
