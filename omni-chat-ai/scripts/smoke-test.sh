#!/usr/bin/env bash
# Post-deploy smoke test. Verifies the services are up and the AI service is reachable.
# Run after ./deploy.sh and after entering your keys in the admin panel.
#
#   bash scripts/smoke-test.sh
#
# Env overrides: AI_URL (default :8080), CHATWOOT_URL (:3000), LANGFUSE_URL (:3001).
set -uo pipefail

AI_URL="${AI_URL:-http://localhost:8080}"
CHATWOOT_URL="${CHATWOOT_URL:-http://localhost:3000}"
LANGFUSE_URL="${LANGFUSE_URL:-http://localhost:3001}"

pass=0; fail=0
check() {
  local name="$1" url="$2"
  if curl -fsS -o /dev/null --max-time 10 "$url"; then
    echo "  ✓ $name"; pass=$((pass+1))
  else
    echo "  ✗ $name  ($url)"; fail=$((fail+1))
  fi
}

echo "▶ Service reachability"
check "AI service /health"      "$AI_URL/health"
check "AI admin panel"          "$AI_URL/admin/login"
check "Chatwoot"                "$CHATWOOT_URL"
check "Langfuse"                "$LANGFUSE_URL"

echo
echo "Next (manual, in the browser):"
echo "  1. $AI_URL/admin → create admin, add Anthropic + KeyCRM keys, hit 'Test connection'."
echo "  2. Channels → create the website widget, paste the snippet on a page, send a message."
echo "  3. Watch the AI reply in Chatwoot; ask for a refund to see the human handoff."
echo "  4. Open Langfuse to confirm the turn was traced with token/cost."
echo
echo "Result: $pass passed, $fail failed."
[[ "$fail" -eq 0 ]]
