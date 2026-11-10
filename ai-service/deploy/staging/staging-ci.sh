#!/bin/sh
# Forced command for the GitHub Actions staging key. Issue: DEV-Johnstocker/chatwoot#38 (refs #1)
#
# Installed on the VPS as /usr/local/bin/staging-ci and bound to one key in
# /root/.ssh/authorized_keys:
#   restrict,command="/usr/local/bin/staging-ci" ssh-ed25519 AAAA... github-staging-ci
# sshd puts the requested command in SSH_ORIGINAL_COMMAND; only the keywords
# below are accepted, and they only read or test the staging stack.
#
#   free-gb     free disk on / in GB (the deploy gate)
#   containers  name<TAB>status of every staging container
#   smoke       seed the sample shop (idempotent) into test account 9001 and
#               run the answer smoke check there, so whatever is being tried
#               on the real staging accounts cannot change its result
set -eu

staging_prefix() {
  docker ps --format '{{.Names}}' | sed -n 's/-stg-ai-service-1$//p' | grep chatwootstaging | head -1
}

case "${SSH_ORIGINAL_COMMAND:-}" in
  free-gb)
    df -BG --output=avail / | tail -1
    ;;
  containers)
    docker ps -a --filter name=chatwootstaging --format '{{.Names}}\t{{.Status}}' | grep -- '-stg-'
    ;;
  smoke)
    prefix=$(staging_prefix)
    [ -n "$prefix" ] || { echo "staging ai-service is not running" >&2; exit 1; }
    exec timeout 900 docker exec "$prefix-stg-ai-service-1" /answer-eval \
      -seed-kb /testdata/sample-kb/faq.json -seed-profile /testdata/sample-kb/profile.json \
      -seed-account 9001 -account 9001 -cases /testdata/answers-smoke.json \
      -min-pass 0.8 -strict-faithful
    ;;
  *)
    echo "refused: staging-ci accepts only free-gb, containers or smoke" >&2
    exit 2
    ;;
esac
