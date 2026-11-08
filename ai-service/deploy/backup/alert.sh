#!/usr/bin/env bash
# Email the owner when a backup run fails. Issue: DEV-Johnstocker/chatwoot#1
#
# Started by systemd only on failure: aisvc-backup.service has
# OnFailure=aisvc-backup-alert@%n.service, which runs `alert.sh <unit>`.
# Sends one email through Resend's API with the unit's result, exit status
# and its last 30 journal lines (file names, checksums and counts; the
# backup scripts never log secrets).
#
# Settings (/etc/aisvc-backup-alert.env, mode 600):
#   RESEND_BACKUP_ALERT_KEY  Resend key, Sending access, one domain only
#   ALERT_TO                 recipient address
#   ALERT_FROM               sender, default below (domain must be verified)
set -euo pipefail

default_from='ai-service backups <alerts@chat.johnstockeraistudio.com>'

# build_payload <from> <to> <subject> <text> prints the Resend JSON body.
build_payload() {
  jq -n --arg from "$1" --arg to "$2" --arg subject "$3" --arg text "$4" \
    '{from: $from, to: [$to], subject: $subject, text: $text}'
}

alert_subject() { printf '[ai-service backup] FAILED on %s (%s)' "$1" "$2"; }

# explain_status <exit status> maps backup.sh exit codes to plain words.
explain_status() {
  case "$1" in
    1) echo "the restore drill failed; the new dump is kept as aisvc-failed-*" ;;
    2) echo "setup or pg_dump failed; no new backup was made" ;;
    3) echo "the backup is verified locally but the R2 copy failed" ;;
    *) echo "unexpected exit status $1 (killed or timed out?)" ;;
  esac
}

main() {
  local unit=${1:-}
  if [[ -z "$unit" || -z "${RESEND_BACKUP_ALERT_KEY:-}" || -z "${ALERT_TO:-}" ]]; then
    echo "usage: alert.sh <failed unit>; needs RESEND_BACKUP_ALERT_KEY and ALERT_TO" >&2
    return 2
  fi
  local host result status logs text cfg
  host=$(hostname)
  result=$(systemctl show -p Result --value "$unit" 2>/dev/null || echo unknown)
  status=$(systemctl show -p ExecMainStatus --value "$unit" 2>/dev/null || echo unknown)
  logs=$(journalctl -u "$unit" -n 30 --no-pager -o short-iso 2>&1 || true)
  text="The ai-service database backup failed.

Host:    $host
Unit:    $unit
Result:  $result, exit status $status
Meaning: $(explain_status "$status")

Check:   journalctl -u $unit -n 100
Run now: systemctl start $unit
Backups: /root/backups on the VPS; offsite copies in R2 under daily/

Last 30 log lines:
$logs"

  umask 077
  cfg=$(mktemp)
  # The key reaches curl through a root-only file, never the command line.
  printf 'header = "Authorization: Bearer %s"\n' "$RESEND_BACKUP_ALERT_KEY" >"$cfg"
  local sent=0
  if build_payload "${ALERT_FROM:-$default_from}" "$ALERT_TO" "$(alert_subject "$host" "$unit")" "$text" |
     curl --fail --silent --show-error --retry 3 --retry-all-errors -o /dev/null \
       -K "$cfg" -H 'Content-Type: application/json' --data-binary @- https://api.resend.com/emails; then
    sent=1
  fi
  rm -f "$cfg"
  if (( sent )); then
    echo "alert sent for $unit"
  else
    echo "ALERT EMAIL FAILED for $unit" >&2
    return 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
