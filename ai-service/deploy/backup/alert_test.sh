#!/usr/bin/env bash
# Tests for alert.sh: email payload and wording. Issue: DEV-Johnstocker/chatwoot#1
# Run: bash deploy/backup/alert_test.sh   (CI runs it; needs jq, no network)
set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=alert.sh
source "$here/alert.sh"

failures=0
check() { # check <name> <want> <got>
  if [[ "$2" == "$3" ]]; then
    echo "ok   $1"
  else
    echo "FAIL $1: want [$2] got [$3]"
    failures=$((failures + 1))
  fi
}

# --- payload: valid JSON whatever the log text contains ---
text=$'line "one" \\ back\nline two\tTab — ไทย'
payload=$(build_payload "Backups <alerts@example.com>" "owner@example.com" "subject" "$text")
check "payload is valid JSON" "ok" "$(jq -e . >/dev/null <<<"$payload" && echo ok)"
check "to is a one-item list" '["owner@example.com"]' "$(jq -c .to <<<"$payload")"
check "from kept" "Backups <alerts@example.com>" "$(jq -r .from <<<"$payload")"
check "text round-trips exactly" "$text" "$(jq -r .text <<<"$payload")"
check "only expected fields" "from,subject,text,to" "$(jq -r 'keys | join(",")' <<<"$payload")"

# --- wording ---
check "subject names host and unit" "[ai-service backup] FAILED on vps1 (aisvc-backup.service)" \
  "$(alert_subject vps1 aisvc-backup.service)"
check "exit 1 explained" "the restore drill failed; the new dump is kept as aisvc-failed-*" "$(explain_status 1)"
check "exit 2 explained" "setup or pg_dump failed; no new backup was made" "$(explain_status 2)"
check "exit 3 explained" "the backup is verified locally but the R2 copy failed" "$(explain_status 3)"
check "other status explained" "unexpected exit status 137 (killed or timed out?)" "$(explain_status 137)"

# --- Slack payload: valid JSON, subject first, logs in a code block ---
slack=$(build_slack_payload "the subject" "$text")
check "slack payload is valid JSON" "ok" "$(jq -e . >/dev/null <<<"$slack" && echo ok)"
check "slack payload has only text" "text" "$(jq -r 'keys | join(",")' <<<"$slack")"
check "slack text starts with bold subject" "*the subject*" "$(jq -r .text <<<"$slack" | head -1)"
check "slack text keeps the log exactly" "yes" "$(jq -r .text <<<"$slack" | grep -qF 'line "one" \ back' && echo yes || echo no)"
check "raw triple backticks removed from logs" "0" \
  "$(build_slack_payload s $'a ```b``` c' | jq -r .text | grep -c '```b```' || true)"
check "triple backticks are softened" "yes" \
  "$(build_slack_payload s $'a ```b``` c' | jq -r .text | grep -qF "a '''b''' c" && echo yes || echo no)"

# --- which channels are on ---
channels() { (RESEND_BACKUP_ALERT_KEY=$1 ALERT_TO=$2 SLACK_BACKUP_WEBHOOK_URL=$3; alert_channels); }
check "email only" "email" "$(channels k to@example.com '')"
check "slack only" "slack" "$(channels '' '' https://hooks.slack.com/services/x)"
check "both" "email slack" "$(channels k to@example.com https://hooks.slack.com/services/x)"
check "email needs key and address" "slack" "$(channels k '' https://hooks.slack.com/services/x)"
check "none" "" "$(channels '' '' '')"
check "non-https webhook ignored" "" "$(channels '' '' http://hooks.slack.com/services/x)"

# --- refuses to run without any channel ---
if (unset RESEND_BACKUP_ALERT_KEY ALERT_TO SLACK_BACKUP_WEBHOOK_URL; main aisvc-backup.service) >/dev/null 2>&1; then
  check "missing settings refused" "refused" "accepted"
else
  check "missing settings refused" "refused" "refused"
fi

if [[ $failures -gt 0 ]]; then
  echo "$failures failed"
  exit 1
fi
echo "all passed"
