#!/usr/bin/env bash
set -Eeuo pipefail

deployment_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_path="${ENV_FILE:-$deployment_dir/.env}"
snapshot="${1:-}"

[[ -n "$snapshot" && -d "$snapshot" ]] || {
  printf 'Usage: %s <completed-snapshot-directory>\n' "$0" >&2
  exit 1
}
snapshot="$(cd "$snapshot" && pwd)"
snapshot_name="$(basename "$snapshot")"
[[ -f "$snapshot/SHA256SUMS" ]] || {
  printf 'Snapshot has no SHA256SUMS: %s\n' "$snapshot" >&2
  exit 1
}
(cd "$snapshot" && shasum -a 256 -c SHA256SUMS >/dev/null)

set -a
# shellcheck disable=SC1090
source "$env_path"
set +a

[[ -n "${BACKUP_GPG_RECIPIENT:-}" ]] || {
  printf 'BACKUP_GPG_RECIPIENT is required.\n' >&2
  exit 1
}
[[ -n "${BACKUP_OFFSITE_REMOTE:-}" ]] || {
  printf 'BACKUP_OFFSITE_REMOTE is required.\n' >&2
  exit 1
}
for command_name in gpg jq rclone shasum tar; do
  command -v "$command_name" >/dev/null 2>&1 || {
    printf '%s is required for off-host backup.\n' "$command_name" >&2
    exit 1
  }
done
gpg --dump-options | grep -qx -- '--force-aead' || {
  printf 'GnuPG with authenticated-encryption support is required.\n' >&2
  exit 1
}

archive_name="${snapshot_name}.tar.gpg"
remote_path="${BACKUP_OFFSITE_REMOTE%/}/$archive_name"
encrypted_archive="$(mktemp "${snapshot}.offsite.XXXXXX.tar.gpg")"
retained_archive="${snapshot}.tar.gpg"
receipt_path="${snapshot}.offsite-receipt.json"
cleanup_archive() { rm -f -- "$encrypted_archive"; }
trap cleanup_archive EXIT
chmod 600 "$encrypted_archive"

tar -C "$(dirname "$snapshot")" -cf - "$snapshot_name" |
  gpg --batch --yes --trust-model always --force-aead --aead-algo OCB --cipher-algo AES256 \
    --recipient "$BACKUP_GPG_RECIPIENT" --output "$encrypted_archive" --encrypt
local_sha256="$(shasum -a 256 "$encrypted_archive" | awk '{print $1}')"

rclone copyto --immutable "$encrypted_archive" "$remote_path"
remote_sha256="$(rclone cat "$remote_path" | shasum -a 256 | awk '{print $1}')"
[[ "$remote_sha256" == "$local_sha256" ]] || {
  printf 'Off-host ciphertext checksum verification failed.\n' >&2
  exit 1
}

temporary_receipt="${receipt_path}.tmp.$$"
trap 'rm -f -- "$temporary_receipt"; cleanup_archive' EXIT
jq -cn \
  --arg snapshot "$snapshot_name" --arg remote "$remote_path" --arg sha256 "$local_sha256" \
  --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{snapshot:$snapshot,remote:$remote,sha256:$sha256,encryption:"OpenPGP-AEAD-OCB-AES256",created_at:$created_at}' \
  > "$temporary_receipt"
chmod 600 "$temporary_receipt"
mv "$temporary_receipt" "$receipt_path"
mv "$encrypted_archive" "$retained_archive"
trap - EXIT
printf 'Authenticated encrypted snapshot uploaded and remotely checksum-verified: %s\n' "$remote_path"
