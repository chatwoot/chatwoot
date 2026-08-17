#!/usr/bin/env bash
set -Eeuo pipefail

deployment_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_path="${ENV_FILE:-$deployment_dir/.env}"
compose=(docker compose --project-directory "$deployment_dir" --env-file "$env_path" -f "$deployment_dir/compose.yaml")

set -a
# shellcheck disable=SC1090
source "$env_path"
set +a

deadline=$((SECONDS + ${SMOKE_TIMEOUT_SECONDS:-240}))
until "${compose[@]}" exec -T rails ruby -rnet/http -e \
  "uri = URI('http://127.0.0.1:3000/health'); request = Net::HTTP::Get.new(uri); request['X-Forwarded-Proto'] = 'https'; response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }; exit(response.is_a?(Net::HTTPSuccess) ? 0 : 1)"; do
  if (( SECONDS >= deadline )); then
    printf 'Chatwoot did not become healthy in time.\n' >&2
    "${compose[@]}" ps
    exit 1
  fi
  sleep 5
done

for service in rails sidekiq postgres redis claude-agent caddy; do
  while true; do
    container_id="$("${compose[@]}" ps -q "$service")"
    if [[ -n "$container_id" ]]; then
      state="$(docker inspect --format '{{.State.Status}} {{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$container_id")"
      [[ "$state" == 'running healthy' ]] && break
    fi
    if (( SECONDS >= deadline )); then
      printf 'Service did not become healthy: %s\n' "$service" >&2
      exit 1
    fi
    sleep 3
  done
done

"${compose[@]}" exec -T \
  -e MYINVEST_ACCOUNT_NAME -e ACADEMY_NEW_ACCOUNT_NAME -e ACADEMY_LEGACY_ACCOUNT_NAME \
  rails bundle exec rails runner '
  expected = [ENV.fetch("MYINVEST_ACCOUNT_NAME"), ENV.fetch("ACADEMY_NEW_ACCOUNT_NAME"), ENV.fetch("ACADEMY_LEGACY_ACCOUNT_NAME")]
  missing = expected - Account.where(name: expected).pluck(:name)
  abort("Missing account boundaries: #{missing.join(", ")}") if missing.any?
'

"${compose[@]}" exec -T rails ruby -rsocket -e \
  "Socket.getaddrinfo('example.com', 443, Socket::AF_UNSPEC, Socket::SOCK_STREAM)"
"${compose[@]}" exec -T claude-agent node -e \
  "require('node:dns').promises.lookup('example.com').catch(() => process.exit(1))"

if [[ "$LOCAL_SMOKE" != true ]]; then
  "${compose[@]}" exec -T claude-agent node dist/provider-check.js
  "${compose[@]}" exec -T rails bundle exec rails runner '
    require "active_storage/service/s3_service"
    require "net/smtp"
    smtp = Net::SMTP.new(ENV.fetch("SMTP_ADDRESS"), Integer(ENV.fetch("SMTP_PORT", "587")))
    smtp.open_timeout = 10
    smtp.read_timeout = 10
    smtp.enable_starttls_auto if ENV.fetch("SMTP_ENABLE_STARTTLS_AUTO", "true") == "true"
    smtp.start(
      ENV.fetch("SMTP_DOMAIN"), ENV.fetch("SMTP_USERNAME"), ENV.fetch("SMTP_PASSWORD"),
      ENV.fetch("SMTP_AUTHENTICATION", "login").to_sym
    ) {}
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("myinvest-storage-check"),
      filename: "myinvest-storage-check.txt",
      content_type: "text/plain"
    )
    raise "Object storage readback failed" unless blob.download == "myinvest-storage-check"
    blob.purge
    service = ActiveStorage::Blob.service
    unless service.is_a?(ActiveStorage::Service::S3Service) &&
           service.client.client.get_bucket_versioning(bucket: service.bucket.name).status == "Enabled"
      raise "Object storage bucket versioning is not enabled"
    end
  '
fi

base_url="${FRONTEND_URL%/}"
smoke_url="${SMOKE_URL:-$base_url/health}"
curl_tls=()
[[ "$LOCAL_SMOKE" == true ]] && curl_tls+=(--insecure)

root_headers="$(curl "${curl_tls[@]}" --silent --show-error --max-time 15 --output /dev/null --dump-header - "$base_url/")"
root_status="$(awk '/^HTTP\// { status = $2 } END { print status }' <<<"$root_headers")"
root_location="$(awk 'BEGIN { IGNORECASE = 1 } /^Location:/ { sub(/\r$/, "", $2); location = $2 } END { print location }' <<<"$root_headers")"
[[ "$root_status" == 302 && "$root_location" == /app/login ]] || {
  printf 'Unexpected public root response: status=%s location=%s\n' "$root_status" "$root_location" >&2
  exit 1
}

login_status="$(curl "${curl_tls[@]}" --silent --show-error --max-time 15 --output /dev/null --write-out '%{http_code}' "$base_url/app/login")"
[[ "$login_status" == 200 ]] || {
  printf 'Unexpected login response: status=%s\n' "$login_status" >&2
  exit 1
}

health_status="$(curl "${curl_tls[@]}" --silent --show-error --max-time 15 --output /dev/null --write-out '%{http_code}' "$smoke_url")"
[[ "$health_status" == 200 ]] || {
  printf 'Unexpected health response: status=%s\n' "$health_status" >&2
  exit 1
}

for asset in logo.svg logo_dark.svg logo_thumbnail.png; do
  asset_status="$(curl "${curl_tls[@]}" --silent --show-error --max-time 15 --output /dev/null --write-out '%{http_code}' "$base_url/brand-assets/$asset")"
  [[ "$asset_status" == 200 ]] || {
    printf 'Unexpected branding asset response for %s: status=%s\n' "$asset" "$asset_status" >&2
    exit 1
  }
done

printf 'Smoke test passed: services, egress, root redirect, login, health, branding assets, and three account boundaries.\n'
