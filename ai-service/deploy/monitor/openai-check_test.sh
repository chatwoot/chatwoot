#!/usr/bin/env bash
# Tests for openai-check.sh. Issue: DEV-Johnstocker/chatwoot#1
# Run: bash deploy/monitor/openai-check_test.sh   (CI runs it; needs jq, no network)
set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=openai-check.sh
source "$here/openai-check.sh"

failures=0
check() { # check <name> <want> <got>
  if [[ "$2" == "$3" ]]; then
    echo "ok   $1"
  else
    echo "FAIL $1: want [$2] got [$3]"
    failures=$((failures + 1))
  fi
}

# --- classify: HTTP status + provider error code -> state ---
check "200 is ok" ok "$(classify 200 -)"
check "429 out of credit" no_credit "$(classify 429 insufficient_quota)"
check "429 credit balance exhausted" no_credit "$(classify 429 credit_balance_exhausted)"
check "402 is no credit (OpenRouter)" no_credit "$(classify 402 -)"
check "429 other is rate limit" rate_limited "$(classify 429 rate_limit_exceeded)"
check "401 bad key" bad_key "$(classify 401 invalid_api_key)"
check "403 bad key" bad_key "$(classify 403 -)"
check "500 provider error" provider_error "$(classify 500 -)"
check "no answer unreachable" unreachable "$(classify 000 -)"

# --- decide: alert on change, remind every 6h, recover once ---
H=21600
check "ok stays quiet" "quiet 0" "$(decide ok 0 0 ok 1000 $H)"
check "first credit failure alerts" "alert 1" "$(decide ok 0 0 no_credit 1000 $H)"
check "still failing within 6h is quiet" "quiet 2" "$(decide no_credit 1 1000 no_credit 2800 $H)"
check "still failing after 6h reminds" "remind 9" "$(decide no_credit 8 1000 no_credit $((1000 + H)) $H)"
check "failure kind change alerts" "alert 1" "$(decide no_credit 3 1000 bad_key 2000 $H)"
check "recovery after alert posts" "recovered 0" "$(decide no_credit 3 1000 ok 2000 $H)"
check "recovery without alert is quiet" "quiet 0" "$(decide unreachable 1 0 ok 2000 $H)"
check "one network blip is quiet" "quiet 1" "$(decide ok 0 0 unreachable 1000 $H)"
check "second blip in a row alerts" "alert 2" "$(decide unreachable 1 0 unreachable 2800 $H)"
check "third blip is quiet" "quiet 3" "$(decide unreachable 2 2800 unreachable 4600 $H)"
check "failed Slack post retries next run" "alert 2" "$(decide no_credit 1 0 no_credit 2800 $H)"

# --- message wording ---
msg=$(message alert production no_credit 429 insufficient_quota 3 x)
check "alert names target" "yes" "$(grep -qF '*production bot: model provider failing*' <<<"$msg" && echo yes || echo no)"
check "alert says out of credit" "yes" "$(grep -qF 'OUT OF CREDIT' <<<"$msg" && echo yes || echo no)"
check "alert shows probe result" "yes" "$(grep -qF 'HTTP 429 insufficient_quota' <<<"$msg" && echo yes || echo no)"
check "recovery has check mark" ":white_check_mark:" "$(message recovered staging ok 200 - 0 x | head -1 | cut -d" " -f1)"
check "reminder says since" "yes" "$(message remind production no_credit 429 - 0 '2026-11-10 03:00 UTC' | grep -qF 'STILL failing (since 2026-11-10 03:00 UTC)' && echo yes || echo no)"

# --- targets from settings ---
check "configured targets" $'production=a-ai-service-1\nstaging=b' \
  "$(OPENAI_CHECK_CONTAINERS='production=a-ai-service-1  staging=b' list_targets)"

# --- probe: key goes through the curl config file, never argv or output ---
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
marker='PLACEHOLDER-VALUE-7'
docker() { printf 'EMBED_API_KEY=%s\nEMBED_MODEL=text-embedding-3-small\nLLM_BASE_URL=https://api.openai.com/v1/\n' "$marker"; }
curl() {
  local cfg='' out='' prev=''
  for a in "$@"; do
    [[ "$prev" == -K ]] && cfg=$a
    [[ "$prev" == -o ]] && out=$a
    prev=$a
  done
  printf '%s\n' "$@" >"$tmp/argv"
  cat "$cfg" >"$tmp/cfg"
  cat >"$tmp/body"
  echo '{"error":{"code":"insufficient_quota","type":"insufficient_quota"}}' >"$out"
  printf 429
}
got=$(probe some-container)
check "probe reads status and code" "429 insufficient_quota" "$got"
check "key not on curl argv" "0" "$(grep -c "$marker" "$tmp/argv" || true)"
check "key in curl config" "1" "$(grep -c "Bearer $marker" "$tmp/cfg" || true)"
check "falls back to LLM base URL" "1" "$(grep -cx 'https://api.openai.com/v1/embeddings' "$tmp/argv" || true)"
check "request is tiny" '{"model":"text-embedding-3-small","input":"ping"}' "$(jq -c . "$tmp/body")"
check "key not in probe output" "0" "$(grep -c "$marker" <<<"$got" || true)"
unset -f docker curl

# --- check_target: state file round trip, Slack only on change ---
posts=0
probe() { echo "$PROBE"; }
quota_errors() { echo 2; }
post_slack() { posts=$((posts + 1)); echo "$1" >"$tmp/slack"; }
PROBE="429 insufficient_quota" check_target production c "$tmp" 1000 $H >/dev/null
check "first failure posts" 1 "$posts"
check "Slack text has no key" "0" "$(grep -c "$marker" "$tmp/slack" || true)"
PROBE="429 insufficient_quota" check_target production c "$tmp" 2800 $H >/dev/null
check "second failure quiet" 1 "$posts"
PROBE="200 -" check_target production c "$tmp" 4600 $H >/dev/null
check "recovery posts" 2 "$posts"
check "state saved ok" "prev=ok" "$(head -1 "$tmp/production")"
PROBE="200 -" check_target production c "$tmp" 6400 $H >/dev/null
check "ok after recovery quiet" 2 "$posts"

# --- refuses to run without a Slack webhook ---
if (unset SLACK_BACKUP_WEBHOOK_URL; main) >/dev/null 2>&1; then
  check "missing webhook refused" refused accepted
else
  check "missing webhook refused" refused refused
fi
if (SLACK_BACKUP_WEBHOOK_URL=http://hooks.slack.com/x main) >/dev/null 2>&1; then
  check "http webhook refused" refused accepted
else
  check "http webhook refused" refused refused
fi

if [[ $failures -gt 0 ]]; then
  echo "$failures failed"
  exit 1
fi
echo "all passed"
