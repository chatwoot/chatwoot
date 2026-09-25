#!/usr/bin/env bash
# End-to-end test of the Docker Compose deploy path (docker-compose.production.yaml + docker/deploy.sh).
#
# Requires docker with compose v2, curl, and an image to test passed as CHATWOOT_IMAGE.
# Refuses to run if a .env already exists at the repo root (it writes a temporary one).
#
# Scenarios:
#   1. Rolling update under load: every request returns 200, and every enqueued job runs exactly
#      once, even though worker replicas are drained while jobs are running.
#   2. Bad migration: the deploy fails, the old containers are left running, and requests keep succeeding.
#   3. Unhealthy release: the deploy fails, the old containers are left running, and requests keep succeeding.
set -euo pipefail

cd "$(dirname "$0")/../.."

: "${CHATWOOT_IMAGE:?set CHATWOOT_IMAGE to the image under test}"
export CHATWOOT_IMAGE
export COMPOSE_PROJECT_NAME="chatwoot-zdt"
export WEB_REPLICAS=2
export WORKER_REPLICAS=2
export DEPLOY_PULL=0

TEST_DIR="docker/test"
RESULTS_DIR="$TEST_DIR/results"
BASE_FILES="docker-compose.production.yaml:$TEST_DIR/compose.test.yaml"
JOB_COUNT=200
LOAD_CONCURRENCY=10
LOAD_STOP_FILE=$(mktemp -u)
LOAD_LOG=$(mktemp)
DEPLOY_LOG=$(mktemp)
FAILURES=0

fail() {
  echo "FAIL: $*"
  FAILURES=$((FAILURES + 1))
}

pass() { echo "PASS: $*"; }

cleanup() {
  touch "$LOAD_STOP_FILE"
  wait 2>/dev/null || true
  COMPOSE_FILE="$BASE_FILES" docker compose down -v --remove-orphans >/dev/null 2>&1 || true
  rm -f .env "$LOAD_LOG" "$DEPLOY_LOG"
  rm -rf "$RESULTS_DIR"
}
trap cleanup EXIT

if [ -e .env ]; then
  echo "A .env already exists at the repo root; refusing to overwrite it."
  exit 1
fi

cat > .env <<EOF
SECRET_KEY_BASE=zdt-test-secret-key-base-0123456789
FRONTEND_URL=http://localhost:3000
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=zdt-test-password
REDIS_URL=redis://redis:6379
REDIS_PASSWORD=zdt-redis-password
RAILS_LOG_TO_STDOUT=true
EOF

mkdir -p "$RESULTS_DIR"
rm -f "$RESULTS_DIR/completions.log"

dc() { COMPOSE_FILE="$BASE_FILES" docker compose "$@"; }

# Container IDs for one service, including stopped ones.
ids_of() { COMPOSE_FILE="$1" docker compose ps -aq "$2" | sort; }

# Run the deploy script with a given compose file set, capturing its output.
deploy() {
  local files="$1"
  COMPOSE_FILE="$files" docker/deploy.sh >"$DEPLOY_LOG" 2>&1
}

# ---- load generator -------------------------------------------------------

start_load() {
  : >"$LOAD_LOG"
  for _ in $(seq 1 "$LOAD_CONCURRENCY"); do
    (
      while [ ! -e "$LOAD_STOP_FILE" ]; do
        curl -s -o /dev/null -m 10 -w '%{http_code}\n' http://127.0.0.1:3000/api >>"$LOAD_LOG" || true
      done
    ) &
  done
}

stop_load() {
  touch "$LOAD_STOP_FILE"
  wait 2>/dev/null || true
  rm -f "$LOAD_STOP_FILE"
  local total bad
  total=$(wc -l <"$LOAD_LOG" | tr -d ' ')
  bad=$(grep -vc '^200$' "$LOAD_LOG" || true)
  echo "load: $total requests, $bad non-200"
  [ "$total" -gt 0 ] || fail "load generator sent no requests"
  [ "$bad" -eq 0 ] || fail "$bad requests did not return 200 during the deploy"
}

# ---- jobs -----------------------------------------------------------------

# Push JOB_COUNT SlowTestJob payloads straight onto the Sidekiq queue with Redis' protocol.
enqueue_jobs() {
  local now json i
  now=$(date +%s)
  for i in $(seq 1 "$JOB_COUNT"); do
    json="{\"class\":\"SlowTestJob\",\"args\":[\"job-$i\"],\"retry\":false,\"queue\":\"default\",\"jid\":\"job-$i\",\"created_at\":$now,\"enqueued_at\":$now}"
    printf '*3\r\n$5\r\nLPUSH\r\n$13\r\nqueue:default\r\n$%d\r\n%s\r\n' "${#json}" "$json"
  done | dc exec -T redis sh -c 'redis-cli --pipe -a "$REDIS_PASSWORD"' >/dev/null
}

completed_count() {
  if [ -f "$RESULTS_DIR/completions.log" ]; then
    wc -l <"$RESULTS_DIR/completions.log" | tr -d ' '
  else
    echo 0
  fi
}

wait_for_jobs() {
  local deadline=$(($(date +%s) + 600))
  while [ "$(completed_count)" -lt "$JOB_COUNT" ]; do
    if [ "$(date +%s)" -ge "$deadline" ]; then
      echo "timed out waiting for jobs: $(completed_count)/$JOB_COUNT completed"
      return 1
    fi
    sleep 2
  done
}

check_jobs() {
  local completed unique duplicates
  completed=$(completed_count)
  unique=$(sort -u "$RESULTS_DIR/completions.log" 2>/dev/null | wc -l | tr -d ' ')
  duplicates=$(sort "$RESULTS_DIR/completions.log" 2>/dev/null | uniq -d | wc -l | tr -d ' ')
  echo "jobs: $completed completed, $unique unique, $duplicates duplicated (expected $JOB_COUNT each)"
  [ "$completed" -eq "$JOB_COUNT" ] || fail "expected $JOB_COUNT job completions, got $completed (dropped jobs)"
  [ "$unique" -eq "$JOB_COUNT" ] || fail "expected $JOB_COUNT unique jobs, got $unique"
  [ "$duplicates" -eq 0 ] || fail "$duplicates jobs ran more than once"
}

# ---- scenario 1: rolling update under load --------------------------------

echo "== Scenario 1: rolling update under load"
COMPOSE_FILE="$BASE_FILES" docker/deploy.sh >"$DEPLOY_LOG" 2>&1 || { cat "$DEPLOY_LOG"; echo "first start failed"; exit 1; }
pass "first start"

old_rails=$(ids_of "$BASE_FILES" rails)
old_sidekiq=$(ids_of "$BASE_FILES" sidekiq)

start_load
enqueue_jobs "$JOB_COUNT"

# Roll with the same image: this exercises surge, health gating, and drain on every replica.
if ! deploy "$BASE_FILES"; then
  fail "rolling deploy failed"
fi
cat "$DEPLOY_LOG"

wait_for_jobs || fail "jobs did not finish after the rollout"
stop_load
check_jobs

if grep -q 'WARNING' "$DEPLOY_LOG"; then
  fail "a replaced replica did not exit cleanly (see WARNING above)"
else
  pass "every replaced replica exited with code 0"
fi

new_rails=$(ids_of "$BASE_FILES" rails)
new_sidekiq=$(ids_of "$BASE_FILES" sidekiq)
[ -z "$(comm -12 <(echo "$old_rails") <(echo "$new_rails"))" ] || fail "old rails replicas are still running"
[ -z "$(comm -12 <(echo "$old_sidekiq") <(echo "$new_sidekiq"))" ] || fail "old sidekiq replicas are still running"

# ---- scenario 2: bad migration ---------------------------------------------

BAD_FILES="$BASE_FILES:$TEST_DIR/compose.bad-migration.yaml"
echo "== Scenario 2: bad migration"
before_rails=$(ids_of "$BASE_FILES" rails)
before_sidekiq=$(ids_of "$BASE_FILES" sidekiq)
start_load

if deploy "$BAD_FILES"; then
  fail "deploy succeeded despite a failing migration"
else
  pass "deploy failed on the failing migration"
fi
grep -q 'simulated bad migration' "$DEPLOY_LOG" && pass "migration error is in the deploy output" || fail "migration error missing from deploy output"

[ "$(ids_of "$BASE_FILES" rails)" = "$before_rails" ] || fail "rails containers changed after a failed migration"
[ "$(ids_of "$BASE_FILES" sidekiq)" = "$before_sidekiq" ] || fail "sidekiq containers changed after a failed migration"
stop_load

# ---- scenario 3: unhealthy replacement --------------------------------------

UNHEALTHY_FILES="$BASE_FILES:$TEST_DIR/compose.unhealthy.yaml"
echo "== Scenario 3: unhealthy release"
before_rails=$(ids_of "$BASE_FILES" rails)
start_load

if deploy "$UNHEALTHY_FILES"; then
  fail "deploy succeeded despite unhealthy replicas"
else
  pass "deploy failed on unhealthy replicas"
fi

[ "$(ids_of "$BASE_FILES" rails)" = "$before_rails" ] || fail "old rails containers were replaced by an unhealthy release"
stop_load

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "All zero-downtime checks passed."
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
