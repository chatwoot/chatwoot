#!/usr/bin/env bash
# Tell the owner when a backup run fails: email and/or Slack.
# Issue: DEV-Johnstocker/chatwoot#1
#
# Started by systemd only on failure: aisvc-backup.service has
# OnFailure=aisvc-backup-alert@%n.service, which runs `alert.sh <unit>`.
# Each configured channel gets the unit's result, exit status in plain words
# and its last 30 journal lines (file names, checksums and counts; the
# backup scripts never log secrets). Channels are independent: one failing
# does not stop the other.
#
# Settings (/etc/aisvc-backup-alert.env, mode 600); at least one channel:
#   RESEND_BACKUP_ALERT_KEY  email: Resend key, Sending access, one domain only
#   ALERT_TO                 email: recipient address
#   ALERT_FROM               email: sender, default below (verified domain)
#   SLACK_BACKUP_WEBHOOK_URL Slack: incoming webhook (https) for the channel
set -euo pipefail

default_from='ai-service backups <alerts@chat.johnstockeraistudio.com>'

# build_payload <from> <to> <subject> <text> prints the Resend JSON body.
build_payload() {
  jq -n --arg from "$1" --arg to "$2" --arg subject "$3" --arg text "$4" \
    '{from: $from, to: [$to], subject: $subject, text: $text}'
}

# build_slack_payload <subject> <text> prints the webhook JSON body: the
# subject in bold, then the details in a code block. Triple backticks inside
# the text are softened so they cannot close the block early.
build_slack_payload() {
  local body=${2//\`\`\`/\'\'\'}
  jq -n --arg subject "$1" --arg body "$body" \
    '{text: ("*" + $subject + "*\n```\n" + $body + "\n```")}'
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

# alert_channels prints the configured channels: "email", "slack" or both.
alert_channels() {
  local on=()
  [[ -n "${RESEND_BACKUP_ALERT_KEY:-}" && -n "${ALERT_TO:-}" ]] && on+=(email)
  [[ "${SLACK_BACKUP_WEBHOOK_URL:-}" == https://* ]] && on+=(slack)
  echo "${on[*]:-}"
}

# post_json <curl config file> <url or ""> reads a JSON body on stdin.
# Secrets (API key header, webhook URL) live only in the root-only config.
post_json() {
  local cfg=$1 url=$2
  local args=(--fail --silent --show-error --retry 3 --retry-all-errors -o /dev/null
    -K "$cfg" -H 'Content-Type: application/json' --data-binary @-)
  [[ -z "$url" ]] || args+=("$url")
  curl "${args[@]}"
}

send_email() { # <subject> <text>
  local cfg ok=1
  cfg=$(mktemp)
  printf 'header = "Authorization: Bearer %s"\n' "$RESEND_BACKUP_ALERT_KEY" >"$cfg"
  build_payload "${ALERT_FROM:-$default_from}" "$ALERT_TO" "$1" "$2" |
    post_json "$cfg" https://api.resend.com/emails && ok=0
  rm -f "$cfg"
  return "$ok"
}

send_slack() { # <subject> <text>
  local cfg ok=1
  cfg=$(mktemp)
  printf 'url = "%s"\n' "$SLACK_BACKUP_WEBHOOK_URL" >"$cfg"
  build_slack_payload "$1" "$2" | post_json "$cfg" "" && ok=0
  rm -f "$cfg"
  return "$ok"
}

main() {
  local unit=${1:-} channels
  channels=$(alert_channels)
  if [[ -z "$unit" || -z "$channels" ]]; then
    echo "usage: alert.sh <failed unit>; needs RESEND_BACKUP_ALERT_KEY + ALERT_TO and/or SLACK_BACKUP_WEBHOOK_URL" >&2
    return 2
  fi
  local host result status logs text subject
  host=$(hostname)
  result=$(systemctl show -p Result --value "$unit" 2>/dev/null || echo unknown)
  status=$(systemctl show -p ExecMainStatus --value "$unit" 2>/dev/null || echo unknown)
  logs=$(journalctl -u "$unit" -n 30 --no-pager -o short-iso 2>&1 || true)
  subject=$(alert_subject "$host" "$unit")
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
  local channel failed=0
  for channel in $channels; do
    if "send_$channel" "$subject" "$text"; then
      echo "alert sent by $channel for $unit"
    else
      echo "ALERT BY $channel FAILED for $unit" >&2
      failed=1
    fi
  done
  return "$failed"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
