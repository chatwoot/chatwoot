#!/usr/bin/env bash
set -Eeuo pipefail

deployment_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/support-structure-wrapper.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

cat >"$work_dir/docker" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"$FAKE_DOCKER_ARGUMENTS"
printf '%s\n' "${SUPPORT_ROSTERS_JSON:-}" >"$FAKE_DOCKER_ROSTER"
printf '%s\n' "${SUPPORT_STRUCTURE_CONFIRMATION:-}" >"$FAKE_DOCKER_CONFIRMATION"
SH
chmod 700 "$work_dir/docker"

run_wrapper() {
  PATH="$work_dir:$PATH" \
    ENV_FILE="$work_dir/production.env" \
    FAKE_DOCKER_ARGUMENTS="$work_dir/arguments" \
    FAKE_DOCKER_ROSTER="$work_dir/roster" \
    FAKE_DOCKER_CONFIRMATION="$work_dir/confirmation" \
    SUPPORT_ROSTERS_JSON='private-roster-sentinel' \
    SUPPORT_STRUCTURE_CONFIRMATION='private-confirmation-sentinel' \
    bash "$deployment_dir/scripts/bootstrap-support-structure.rb" "$@"
}

: >"$work_dir/production.env"
run_wrapper
grep -Fxq 'SUPPORT_STRUCTURE_MODE=dry-run' "$work_dir/arguments"
grep -Fxq 'SUPPORT_ROSTERS_JSON' "$work_dir/arguments"
if grep -Fq 'private-roster-sentinel' "$work_dir/arguments"; then
  printf 'Support roster leaked into Docker arguments.\n' >&2
  exit 1
fi
grep -Fxq 'private-roster-sentinel' "$work_dir/roster"
grep -Fxq 'private-confirmation-sentinel' "$work_dir/confirmation"

run_wrapper --apply
grep -Fxq 'SUPPORT_STRUCTURE_MODE=apply' "$work_dir/arguments"
grep -Fxq 'SUPPORT_STRUCTURE_CONFIRMATION' "$work_dir/arguments"
if grep -Fq 'private-confirmation-sentinel' "$work_dir/arguments"; then
  printf 'Support confirmation leaked into Docker arguments.\n' >&2
  exit 1
fi

if run_wrapper unexpected >/dev/null 2>&1; then
  printf 'Invalid support-structure mode was accepted.\n' >&2
  exit 1
fi

printf 'Support structure wrapper is host-Ruby independent and secret-safe.\n'
