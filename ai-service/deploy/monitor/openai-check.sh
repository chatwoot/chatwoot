#!/usr/bin/env bash
# Tell the owner in Slack when the bot's model provider stops answering:
# out of credit, key rejected, or unreachable. Issue: DEV-Johnstocker/chatwoot#1
#
# Run by aisvc-openai-check.timer every 30 minutes. For each running
# ai-service container (production and staging) it:
#   1. reads the embeddings key, base URL and model from the container's env
#      (EMBED_* falling back to LLM_*, like the service) and sends one tiny
#      embeddings request (about $0.0000002);
#   2. counts quota errors (429, insufficient_quota) in the last 35 minutes
#      of the container's log.
# When the primary fails it also probes the embeddings fallback
# (EMBED_FALLBACK_*); if that answers, the state is on_fallback (warning)
# instead of a failure.
# It posts to Slack only when a target's state changes (failing <-> ok),
# plus a reminder every REMIND_HOURS while it stays down. A network error
# or a 5xx must happen twice in a row before it alerts, so one blip is quiet.
# Keys go to curl through a root-only config file, never the command line,
# and are never printed.
#
# Settings: SLACK_BACKUP_WEBHOOK_URL (shared with the backup alert,
# /etc/aisvc-backup-alert.env). Optional /etc/aisvc-openai-check.env:
#   OPENAI_CHECK_CONTAINERS  "label=container ..." (default: every running
#                            *ai-service-1 container; "staging" in the name
#                            labels it staging, otherwise production)
#   REMIND_HOURS             default 6
#   STATE_DIR                default /var/lib/aisvc-openai-check
set -euo pipefail

default_base='https://openrouter.ai/api/v1'

# classify <http status> <error code> prints the state: ok, no_credit,
# bad_key, rate_limited, provider_error or unreachable.
classify() {
  case "$1" in
    2??) echo ok ;;
    401 | 403) echo bad_key ;;
    402) echo no_credit ;;
    429)
      case "$2" in
        insufficient_quota | credit_balance_exhausted | billing_hard_limit_reached) echo no_credit ;;
        *) echo rate_limited ;;
      esac
      ;;
    000 | '') echo unreachable ;;
    *) echo provider_error ;;
  esac
}

# transient <state> succeeds for states that must repeat before alerting.
transient() { [[ "$1" == unreachable || "$1" == provider_error || "$1" == rate_limited ]]; }

explain() {
  case "$1" in
    ok) echo "answering normally" ;;
    on_fallback) echo "PRIMARY FAILING, bot answering through the fallback provider. Fix the primary (credit or key); the fallback may be rate limited." ;;
    no_credit) echo "OUT OF CREDIT: the bot cannot search the knowledge base or answer. Add credit in the provider's billing page." ;;
    bad_key) echo "KEY REJECTED (revoked or wrong): the bot cannot answer. Replace the key in Dokploy." ;;
    rate_limited) echo "rate limited twice in a row: answers may fail or be slow." ;;
    provider_error) echo "the provider returned server errors twice in a row." ;;
    unreachable) echo "the provider could not be reached twice in a row." ;;
    *) echo "unknown state $1" ;;
  esac
}

# decide <previous state> <previous streak> <last alert epoch> <new state> <now epoch> <remind seconds>
# prints "<action> <streak>": action is alert, recovered, remind or quiet.
decide() {
  local prev=$1 streak=$2 last=$3 new=$4 now=$5 remind=$6
  if [[ "$new" == ok ]]; then
    if [[ "$prev" != ok && "$last" -gt 0 ]]; then echo "recovered 0"; else echo "quiet 0"; fi
    return
  fi
  if [[ "$new" == "$prev" ]]; then streak=$((streak + 1)); else streak=1; fi
  if transient "$new" && [[ $streak -lt 2 ]]; then echo "quiet $streak"; return; fi
  if [[ "$last" -eq 0 || ("$new" != "$prev" && $streak -eq 1) ]] || { transient "$new" && [[ $streak -eq 2 ]]; }; then
    echo "alert $streak"
  elif [[ $((now - last)) -ge $remind ]]; then
    echo "remind $streak"
  else
    echo "quiet $streak"
  fi
}

# list_targets prints "label=container" lines.
list_targets() {
  if [[ -n "${OPENAI_CHECK_CONTAINERS:-}" ]]; then
    tr ' ' '\n' <<<"$OPENAI_CHECK_CONTAINERS" | grep -v '^$'
    return
  fi
  local name
  docker ps --format '{{.Names}}' | grep -E 'ai-service-1$' | while read -r name; do
    if [[ "$name" == *staging* ]]; then echo "staging=$name"; else echo "production=$name"; fi
  done
}

# env_value <env lines> <name> prints that variable's value.
env_value() { sed -n "s/^$2=//p" <<<"$1" | head -1; }

# probe_provider <base url> <key> <model> prints "<http status> <error code>"
# for one tiny embeddings request.
probe_provider() {
  local base=$1 key=$2 model=$3 cfg body code status
  cfg=$(mktemp) body=$(mktemp)
  printf 'header = "Authorization: Bearer %s"\n' "$key" >"$cfg"
  status=$(jq -n --arg m "$model" '{model: $m, input: "ping"}' |
    curl --silent --max-time 20 -o "$body" -w '%{http_code}' -K "$cfg" \
      -H 'Content-Type: application/json' --data-binary @- "${base%/}/embeddings" || true)
  code=$(jq -r '.error.code // .error.type // empty' "$body" 2>/dev/null | head -1 | tr -cd 'A-Za-z0-9_.-' || true)
  rm -f "$cfg" "$body"
  echo "${status:-000} ${code:--}"
}

# url_host <url> prints only the host[:port]: no user info, path, query or
# fragment, and "redacted" if anything else is left.
url_host() {
  local host=${1#*://}
  host=${host%%[/?#]*}
  host=${host##*@}
  [[ "$host" =~ ^[A-Za-z0-9.-]+(:[0-9]+)?$ ]] || host=redacted
  echo "$host"
}

container_env() { docker inspect "$1" --format '{{range .Config.Env}}{{println .}}{{end}}'; }

# probe <container> probes the primary provider: EMBED_* falling back to
# LLM_*, like the service.
probe() {
  local envs base key model
  envs=$(container_env "$1")
  base=$(env_value "$envs" EMBED_BASE_URL)
  key=$(env_value "$envs" EMBED_API_KEY)
  model=$(env_value "$envs" EMBED_MODEL)
  [[ -n "$base" ]] || base=$(env_value "$envs" LLM_BASE_URL)
  [[ -n "$key" ]] || key=$(env_value "$envs" LLM_API_KEY)
  probe_provider "${base:-$default_base}" "$key" "${model:-text-embedding-3-small}"
}

# probe_fallback <container> probes the embeddings fallback and prints
# "<http status> <error code> <host>", or "none" when the service would not
# use one (it needs base URL, key and model, like settings.Configured).
probe_fallback() {
  local envs base key model host
  envs=$(container_env "$1")
  base=$(env_value "$envs" EMBED_FALLBACK_BASE_URL)
  key=$(env_value "$envs" EMBED_FALLBACK_API_KEY)
  model=$(env_value "$envs" EMBED_FALLBACK_MODEL)
  if [[ -z "$base" || -z "$key" || -z "$model" ]]; then
    echo none
    return
  fi
  host=$(url_host "$base")
  echo "$(probe_provider "$base" "$key" "$model") $host"
}

quota_errors() { # <container>
  docker logs --since 35m "$1" 2>&1 | grep -ciE 'insufficient_quota|credit_balance|no credits|status 429' || true
}

post_slack() { # <text>
  local cfg ok=1
  cfg=$(mktemp)
  printf 'url = "%s"\n' "$SLACK_BACKUP_WEBHOOK_URL" >"$cfg"
  jq -n --arg t "$1" '{text: $t}' |
    curl --fail --silent --show-error --retry 3 --retry-all-errors -o /dev/null -K "$cfg" \
      -H 'Content-Type: application/json' --data-binary @- && ok=0
  rm -f "$cfg"
  return "$ok"
}

# message <action> <label> <state> <http> <code> <log errors> <since> [fallback note]
message() {
  local icon=':x:' head
  [[ "$3" == on_fallback ]] && icon=':warning:'
  case "$1" in
    recovered) icon=':white_check_mark:' head="$2 bot: model provider OK again" ;;
    remind) head="$2 bot: STILL degraded (since $7)" ;;
    *) if [[ "$3" == on_fallback ]]; then head="$2 bot: answering through fallback"; else head="$2 bot: model provider failing"; fi ;;
  esac
  printf '%s *%s*\n%s\nPrimary probe: HTTP %s %s · quota errors in log (35 min): %s%s\nHost: %s · check: systemctl start aisvc-openai-check' \
    "$icon" "$head" "$(explain "$3")" "$4" "$5" "$6" "${8:+$'\n'$8}" "$(hostname)"
}

check_target() { # <label> <container> <state dir> <now> <remind seconds>
  local label=$1 container=$2 dir=$3 now=$4 remind=$5
  local file="$dir/$label" prev=ok streak=0 last=0 since=$now
  # shellcheck disable=SC1090
  [[ -f "$file" ]] && source "$file"
  local http code state logs action
  local fb fhttp fcode fhost note=''
  read -r http code < <(probe "$container")
  state=$(classify "$http" "$code")
  if [[ "$state" != ok ]]; then
    fb=$(probe_fallback "$container")
    if [[ "$fb" != none ]]; then
      read -r fhttp fcode fhost <<<"$fb"
      note="fallback $fhost: HTTP $fhttp $fcode"
      [[ "$(classify "$fhttp" "$fcode")" == ok ]] && state=on_fallback
    else
      note="no fallback configured"
    fi
  fi
  logs=$(quota_errors "$container")
  [[ "$state" == "$prev" ]] || since=$now
  read -r action streak < <(decide "$prev" "$streak" "$last" "$state" "$now" "$remind")
  echo "$label: $state (HTTP $http $code${note:+, $note}, log quota errors $logs) -> $action"
  if [[ "$action" != quiet ]]; then
    if post_slack "$(message "$action" "$label" "$state" "$http" "$code" "$logs" "$(date -u -d "@$since" '+%F %H:%M UTC' 2>/dev/null || echo "$since")" "$note")"; then
      last=$now
      [[ "$action" == recovered ]] && last=0
    else
      echo "SLACK POST FAILED for $label" >&2
    fi
  fi
  printf 'prev=%q\nstreak=%q\nlast=%q\nsince=%q\n' "$state" "$streak" "$last" "$since" >"$file"
}

main() {
  if [[ "${SLACK_BACKUP_WEBHOOK_URL:-}" != https://* ]]; then
    echo "needs SLACK_BACKUP_WEBHOOK_URL (https)" >&2
    return 2
  fi
  local dir=${STATE_DIR:-/var/lib/aisvc-openai-check} now remind t found=0
  umask 077
  mkdir -p "$dir"
  now=$(date +%s)
  remind=$((${REMIND_HOURS:-6} * 3600))
  while read -r t; do
    [[ -n "$t" ]] || continue
    found=1
    check_target "${t%%=*}" "${t#*=}" "$dir" "$now" "$remind"
  done < <(list_targets)
  if [[ $found -eq 0 ]]; then
    echo "no ai-service container found" >&2
    return 2
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
