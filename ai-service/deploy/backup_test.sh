#!/usr/bin/env bash
# Tests for backup.sh: URL cleaning and retention. Issue: DEV-Johnstocker/chatwoot#1
# Run: bash deploy/backup_test.sh   (CI runs it; needs no Docker or database)
set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=backup.sh
source "$here/backup.sh"

failures=0
check() { # check <name> <want> <got>
  if [[ "$2" == "$3" ]]; then
    echo "ok   $1"
  else
    echo "FAIL $1: want [$2] got [$3]"
    failures=$((failures + 1))
  fi
}

# --- strip_pool_params: pgx pool options removed, everything else kept ---
base='postgres://user:p%40ss@db.example.com:5432/postgres'
check "no query"            "$base"                         "$(strip_pool_params "$base")"
check "only pool option"    "$base"                         "$(strip_pool_params "$base?pool_max_conns=5")"
check "pool option first"   "$base?sslmode=require"         "$(strip_pool_params "$base?pool_max_conns=5&sslmode=require")"
check "pool option last"    "$base?sslmode=require"         "$(strip_pool_params "$base?sslmode=require&pool_max_conns=5")"
check "pool option middle"  "$base?sslmode=require&x=1"     "$(strip_pool_params "$base?sslmode=require&pool_max_conns=5&x=1")"
check "two pool options"    "$base?sslmode=require"         "$(strip_pool_params "$base?pool_max_conns=5&pool_min_conns=1&sslmode=require")"
check "other options kept"  "$base?sslmode=require&connect_timeout=5" "$(strip_pool_params "$base?sslmode=require&connect_timeout=5")"
check "lookalike kept"      "$base?mypool_size=2"           "$(strip_pool_params "$base?mypool_size=2")"

# --- prune_old: keep every dump of the newest N dates, touch nothing else ---
count_dumps() { find "$1" -name 'aisvc-full-????????-??????.dump' | wc -l | tr -d ' '; }
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
dump() { touch "$dir/aisvc-full-$1.dump" "$dir/aisvc-full-$1.dump.sha256"; }
for day in 01 02 03 04 05 06 07 08 09 10; do dump "202611${day}-030000"; done
dump 20261102-120000                       # a second run on an old day
touch "$dir/aisvc-kb-20261107-181325.sql" "$dir/profile-acct1.json" "$dir/aisvc-failed-20261101-030000.dump" \
  "$dir/aisvc-full-manual.dump"            # not a dated name: never touched
mkdir "$dir/langfuse-auto-update"

# Many runs on the newest day must not push any older day out.
for t in 090000 120000 150000 180000 210000; do dump "20261110-$t"; done
check "repeat runs on one day: 7-day keep deletes only days 01-03" \
  "aisvc-full-20261101-030000.dump aisvc-full-20261102-030000.dump aisvc-full-20261102-120000.dump aisvc-full-20261103-030000.dump " \
  "$(prune_old "$dir" 7 | tr '\n' ' ')"
check "every dump of the 7 newest days kept" "12" "$(count_dumps "$dir")"
check "checksums pruned with their dumps" "12" "$(find "$dir" -name 'aisvc-full-*.dump.sha256' | wc -l | tr -d ' ')"
check "oldest kept day intact" "yes" "$([[ -f "$dir/aisvc-full-20261104-030000.dump.sha256" ]] && echo yes || echo no)"
check "other files untouched" "4" "$(find "$dir" -mindepth 1 -maxdepth 1 ! -name 'aisvc-full-*' | wc -l | tr -d ' ')"
check "undated manual dump untouched" "yes" "$([[ -f "$dir/aisvc-full-manual.dump" ]] && echo yes || echo no)"

check "fewer days than keep: nothing deleted" "" "$(prune_old "$dir" 30)"
check "fewer days than keep: still 12" "12" "$(count_dumps "$dir")"
check "keep 1 day keeps all of the newest day" \
  "6" "$(prune_old "$dir" 1 >/dev/null; count_dumps "$dir")"
check "single day: nothing more to delete" "" "$(prune_old "$dir" 1)"

for bad in 0 -1 x ""; do
  if prune_old "$dir" "$bad" >/dev/null 2>&1; then
    check "keep=$bad refused" "refused" "accepted"
  else
    check "keep=$bad refused" "refused" "refused"
  fi
done
check "refused keep deletes nothing" "6" "$(count_dumps "$dir")"

if [[ $failures -gt 0 ]]; then
  echo "$failures failed"
  exit 1
fi
echo "all passed"
