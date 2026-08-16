#!/usr/bin/env bash
set -Eeuo pipefail

receipt_path="${1:-}"
[[ -n "$receipt_path" && -f "$receipt_path" ]] || {
  printf 'Usage: %s <offsite-receipt.json>\n' "$0" >&2
  exit 1
}
for command_name in gpg jq rclone shasum tar; do
  command -v "$command_name" >/dev/null 2>&1 || {
    printf '%s is required for recovery verification.\n' "$command_name" >&2
    exit 1
  }
done
remote_path="$(jq -er '.remote | select(type == "string" and length > 0)' "$receipt_path")"
expected_sha256="$(jq -er '.sha256 | select(type == "string" and test("^[0-9a-fA-F]{64}$"))' "$receipt_path")"
expected_snapshot="$(jq -er '.snapshot | select(type == "string" and test("^20[0-9]{6}T[0-9]{6}Z$"))' "$receipt_path")"

work_dir="$(mktemp -d)"
cleanup_work_dir() { find "$work_dir" -depth -delete 2>/dev/null || true; }
trap cleanup_work_dir EXIT
chmod 700 "$work_dir"
encrypted_archive="$work_dir/snapshot.tar.gpg"
rclone copyto "$remote_path" "$encrypted_archive"
downloaded_sha256="$(shasum -a 256 "$encrypted_archive" | awk '{print $1}')"
[[ "$downloaded_sha256" == "$expected_sha256" ]] || {
  printf 'Downloaded off-host ciphertext checksum does not match the receipt.\n' >&2
  exit 1
}

mkdir -m 700 "$work_dir/recovered"
gpg --batch --quiet --decrypt "$encrypted_archive" | tar -xf - -C "$work_dir/recovered"
snapshot="$work_dir/recovered/$expected_snapshot"
[[ -d "$snapshot" ]] || {
  printf 'Decrypted archive did not contain a snapshot directory.\n' >&2
  exit 1
}
for file in chatwoot.dump claude-agent.dump storage.tar.gz redis.tar.gz object-storage.tar.gz object-storage-manifest.json environment.env.gpg SHA256SUMS; do
  [[ -f "$snapshot/$file" ]] || {
    printf 'Recovered snapshot is incomplete: %s\n' "$file" >&2
    exit 1
  }
done
(cd "$snapshot" && shasum -a 256 -c SHA256SUMS >/dev/null)
printf 'Off-host recovery proof passed: AEAD decryption and all internal checksums verified.\n'
