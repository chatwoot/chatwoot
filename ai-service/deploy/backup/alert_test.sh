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

# --- refuses to run without its settings ---
if (unset RESEND_BACKUP_ALERT_KEY ALERT_TO; main aisvc-backup.service) >/dev/null 2>&1; then
  check "missing settings refused" "refused" "accepted"
else
  check "missing settings refused" "refused" "refused"
fi

if [[ $failures -gt 0 ]]; then
  echo "$failures failed"
  exit 1
fi
echo "all passed"
