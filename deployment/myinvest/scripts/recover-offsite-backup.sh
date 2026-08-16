#!/usr/bin/env bash
set -Eeuo pipefail

receipt_path="${1:-}"
recovery_root="${2:-}"
[[ -n "$receipt_path" && -f "$receipt_path" && -n "$recovery_root" ]] || {
  printf 'Usage: RECOVERY_CONFIRMATION=recover:<snapshot-name> %s <offsite-receipt.json> <empty-recovery-root>\n' "$0" >&2
  exit 1
}
for command_name in gpg jq rclone shasum tar; do
  command -v "$command_name" >/dev/null 2>&1 || {
    printf '%s is required for off-host recovery.\n' "$command_name" >&2
    exit 1
  }
done
remote_path="$(jq -er '.remote | select(type == "string" and length > 0)' "$receipt_path")"
expected_sha256="$(jq -er '.sha256 | select(type == "string" and test("^[0-9a-fA-F]{64}$"))' "$receipt_path")"
snapshot_name="$(jq -er '.snapshot | select(type == "string" and test("^20[0-9]{6}T[0-9]{6}Z$"))' "$receipt_path")"
[[ "${RECOVERY_CONFIRMATION:-}" == "recover:$snapshot_name" ]] || {
  printf 'Set RECOVERY_CONFIRMATION=recover:%s to materialize this plaintext recovery snapshot.\n' "$snapshot_name" >&2
  exit 1
}

mkdir -p "$recovery_root"
recovery_root="$(cd "$recovery_root" && pwd)"
case "$recovery_root" in
  /|"$HOME")
    printf 'Unsafe recovery root: %s\n' "$recovery_root" >&2
    exit 1
    ;;
esac
target="$recovery_root/$snapshot_name"
[[ ! -e "$target" ]] || {
  printf 'Recovery target already exists: %s\n' "$target" >&2
  exit 1
}

work_dir="$(mktemp -d "$recovery_root/.recover.XXXXXX")"
cleanup_work_dir() { find "$work_dir" -depth -delete 2>/dev/null || true; }
trap cleanup_work_dir EXIT
chmod 700 "$work_dir"
rclone copyto "$remote_path" "$work_dir/snapshot.tar.gpg"
downloaded_sha256="$(shasum -a 256 "$work_dir/snapshot.tar.gpg" | awk '{print $1}')"
[[ "$downloaded_sha256" == "$expected_sha256" ]] || {
  printf 'Downloaded off-host ciphertext checksum does not match the receipt.\n' >&2
  exit 1
}
gpg --batch --quiet --decrypt "$work_dir/snapshot.tar.gpg" | tar -xf - -C "$work_dir"
[[ -d "$work_dir/$snapshot_name" ]] || {
  printf 'Decrypted archive did not contain the receipt snapshot.\n' >&2
  exit 1
}
(cd "$work_dir/$snapshot_name" && shasum -a 256 -c SHA256SUMS >/dev/null)
mv "$work_dir/$snapshot_name" "$target"
cleanup_work_dir
trap - EXIT
chmod 700 "$target"
printf 'Authenticated recovery snapshot materialized at %s; pass it to restore.sh only after approval.\n' "$target"
