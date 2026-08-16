#!/usr/bin/env bash
set -Eeuo pipefail

deployment_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_path="${ENV_FILE:-$deployment_dir/.env}"
compose=(docker compose --project-directory "$deployment_dir" --env-file "$env_path" -f "$deployment_dir/compose.yaml")

set -a
# shellcheck disable=SC1090
source "$env_path"
set +a

[[ "$LOCAL_SMOKE" != true ]] || {
  printf 'Storage migration is restricted to production mode.\n' >&2
  exit 1
}
[[ "$ACTIVE_STORAGE_SERVICE" == s3_compatible ]] || {
  printf 'ACTIVE_STORAGE_SERVICE must be s3_compatible.\n' >&2
  exit 1
}
[[ "${STORAGE_MIGRATION_CONFIRMATION:-}" == "migrate:local:s3_compatible" ]] || {
  printf 'Set STORAGE_MIGRATION_CONFIRMATION=migrate:local:s3_compatible.\n' >&2
  exit 1
}

before="$("${compose[@]}" exec -T rails bundle exec rails runner '
  puts({
    blobs: ActiveStorage::Blob.count,
    attachments: ActiveStorage::Attachment.count,
    local_blobs: ActiveStorage::Blob.where(service_name: "local").count,
    target_blobs: ActiveStorage::Blob.where(service_name: "s3_compatible").count
  }.to_json)
')"

if [[ "$(jq -r '.local_blobs' <<<"$before")" != 0 ]]; then
  "${compose[@]}" exec -T -e FROM=local -e TO=s3_compatible -e UPDATE_BLOB_SERVICE_NAME=true rails \
    bundle exec rake storage:migrate
fi

"${compose[@]}" exec -T rails bundle exec rails runner '
  require "active_storage/service/s3_service"
  require "digest"

  service = ActiveStorage::Blob.service
  raise "S3-compatible service is not active" unless service.is_a?(ActiveStorage::Service::S3Service)
  versioning = service.client.client.get_bucket_versioning(bucket: service.bucket.name).status
  raise "Object storage versioning is not enabled" unless versioning == "Enabled"

  blobs = ActiveStorage::Blob.order(:id).to_a
  attachments = ActiveStorage::Attachment.count
  raise "Blob service migration is incomplete" unless blobs.all? { |blob| blob.service_name == "s3_compatible" }

  blobs.each do |blob|
    content = blob.download
    raise "Blob readback checksum mismatch" unless Digest::MD5.base64digest(content) == blob.checksum
  end

  object_count = service.bucket.objects.count
  raise "Object storage has fewer objects than database blobs" if object_count < blobs.length

  puts({
    event: "storage_migration_verified",
    blobs: blobs.length,
    attachments: attachments,
    object_count: object_count,
    versioning: versioning
  }.to_json)
'
