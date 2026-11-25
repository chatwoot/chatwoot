#!/bin/sh

# Brings enterprise/ into the app at boot, from the official tag in VERSION_CW, when the
# edition asks for it. The image itself ships without the tree. Two places are involved:
#
#   storage/.cw-enterprise/<version>-<hash>/enterprise
#       the verified tree, in the volume the stock composes already share between the web
#       and worker containers. One directory per version and hash, published by an atomic
#       rename and never changed afterwards, so a restart or a recreate on the same version
#       needs no network and no container ever sees a tree change under it.
#   tmp/cw-enterprise
#       this container's own activation: a link to that tree, made only with CW_EDITION=ee
#       and removed otherwise. /app/enterprise is a link to it, made at build time. A new
#       container starts without it, so it boots as Community until this helper says
#       otherwise, and what one container decides never reaches another. tmp/ has to be
#       writable, which Rails already needs for its pids and caches.
#
# While tmp/cw-enterprise is missing the chain dangles, and a dangling link does not exist
# as far as Rails is concerned (ChatwootApp.enterprise? asks Pathname#exist?, which follows
# it). A `docker exec ... rails console` sees the same edition as the container's server.
#
#   enterprise.sh ensure          run by every entrypoint before anything boots Rails
#   enterprise.sh lock <out_dir>  build time: download the official tree, write the lock
#   enterprise.sh tree-hash <dir> the hash both sides agree on, for one enterprise/ tree
#
# The hash covers the tree, not the tarball: one sha256 per regular file, in a stable
# order, hashed again. GitHub does not promise byte-stable archives, so hashing the
# download would break on a recompression that changed nothing that runs.
#
# With CW_EDITION=ee, a missing lock, a lock for another version, a download that fails and
# a tree that does not match the lock all stop the boot with a message saying which.
# Booting without enterprise/ instead would quietly turn an Enterprise installation into a
# Community one: custom roles fall back to the plain agent role, SAML sign-in goes away, and
# nothing on screen says why. A container that refuses to start is the louder and safer
# failure. CW_EDITION=ce boots without it, on purpose. An intact tree in the cache is used
# without taking a lock or writing to the volume, so a read-only volume works; only a
# download writes there, under an exclusive lock on storage/.cw-enterprise/.lock.
#
# Settings, both optional:
#   CW_ENTERPRISE_SOURCE_URL     a mirror of the official tarball for the tag. The tree is
#                                checked against the same pinned hash, wherever it came from.
#   CW_ENTERPRISE_FETCH_RETRIES  download attempts after the first one (default 3).

set -eu
# So a download cut halfway fails as a download, not as a tree that hashes wrong.
# shellcheck disable=SC3040 # busybox ash and bash have it; a shell without it skips it
(set -o pipefail) 2>/dev/null && set -o pipefail

APP_ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
LOCK_FILE="$APP_ROOT/.enterprise_lock"
TARGET="$APP_ROOT/enterprise"
CACHE_ROOT="$APP_ROOT/storage/.cw-enterprise"
ACTIVE="$APP_ROOT/tmp/cw-enterprise"

log() {
  echo "[enterprise] $*" >&2
}

fail() {
  log "ERROR: $*"
  exit 1
}

sha256_of_stdin() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | cut -d ' ' -f 1
  else
    shasum -a 256 | cut -d ' ' -f 1
  fi
}

# sha256 lines for the NUL-separated paths on stdin, in one process per batch rather than
# one per file: a fork per file put a single check of the tree at about a second.
sha256_lines() {
  if command -v sha256sum >/dev/null 2>&1; then
    xargs -0 sha256sum
  else
    xargs -0 shasum -a 256
  fi
}

# Prints the tree hash of an enterprise/ directory. Paths are taken relative to its
# parent, so the same tree hashes the same wherever it was extracted.
tree_hash() {
  dir=$1
  [ -d "$dir" ] || return 1
  parent=$(dirname "$dir")
  name=$(basename "$dir")
  (
    cd "$parent"
    # Anything that is neither a directory nor a regular file (a symlink, above all) could
    # point outside the tree, and the hash would not cover what it points to.
    if [ -n "$(find "$name/" ! -type d ! -type f -print | head -n 1)" ]; then
      echo "unexpected non-regular file under $name" >&2
      exit 1
    fi
    find "$name/" -type f -print | sed 's|//*|/|g' | LC_ALL=C sort | tr '\n' '\0' | sha256_lines | sha256_of_stdin
  )
}

intact() {
  [ "$(tree_hash "$1" 2>/dev/null || true)" = "$PINNED" ]
}

# Reads the lock into VERSION and PINNED, and refuses one that does not belong to this image.
read_lock() {
  [ -f "$LOCK_FILE" ] || fail "this image has no $LOCK_FILE, so there is no hash to check enterprise/ against"
  VERSION=$(tr -d '[:space:]' < "$APP_ROOT/VERSION_CW")
  locked_version=$(sed -n 's/^version=//p' "$LOCK_FILE" | head -n 1)
  PINNED=$(sed -n 's/^sha256=//p' "$LOCK_FILE" | head -n 1)
  [ -n "$PINNED" ] || fail "$LOCK_FILE has no sha256"
  [ "$locked_version" = "$VERSION" ] || fail "$LOCK_FILE pins v$locked_version, but this image is v$VERSION"
  ENTRY="$CACHE_ROOT/$VERSION-$PINNED"
}

# Downloads the official tarball for a version and extracts only enterprise/ from it, into
# <dest>/enterprise. Streams straight into tar, so the rest of the repository never lands
# on disk.
download_tree() {
  version=$1
  dest=$2
  url=${CW_ENTERPRISE_SOURCE_URL:-https://codeload.github.com/chatwoot/chatwoot/tar.gz/refs/tags/v$version}
  retries=${CW_ENTERPRISE_FETCH_RETRIES:-3}
  top="chatwoot-$version"

  log "downloading enterprise/ for v$version from $url"
  # Each attempt is the whole pipeline into a clean directory. curl's own --retry would
  # restart the transfer into the same pipe, after tar had already read part of the first
  # archive, and the stream would never extract.
  attempt=0
  while :; do
    rm -rf "$dest/extract"
    mkdir -p "$dest/extract"
    if curl --fail --silent --show-error --location \
      --connect-timeout 15 --max-time 600 \
      "$url" | tar -xzf - -C "$dest/extract" "$top/enterprise" &&
      [ -d "$dest/extract/$top/enterprise" ]; then
      break
    fi
    attempt=$((attempt + 1))
    if [ "$attempt" -gt "$retries" ]; then
      rm -rf "$dest/extract"
      return 1
    fi
    log "download attempt $attempt failed, retrying ($attempt of $retries)"
    sleep 2
  done
  mv "$dest/extract/$top/enterprise" "$dest/enterprise"
  rm -rf "$dest/extract"
}

cmd_tree_hash() {
  [ "$#" -eq 1 ] || fail "usage: enterprise.sh tree-hash <enterprise_dir>"
  tree_hash "$1" || fail "could not hash $1"
}

cmd_lock() {
  [ "$#" -eq 1 ] || fail "usage: enterprise.sh lock <out_dir>"
  out=$1
  version=$(tr -d '[:space:]' < "$APP_ROOT/VERSION_CW")
  [ -n "$version" ] || fail "VERSION_CW is empty"
  mkdir -p "$out"
  download_tree "$version" "$out" || fail "download of v$version failed"
  sha=$(tree_hash "$out/enterprise") || fail "could not hash the official tree"
  printf 'version=%s\nsha256=%s\n' "$version" "$sha" > "$out/enterprise_lock"
  log "pinned v$version at $sha"
}

# The image's link has to lead to the entry just verified, before Rails boots. Comparing
# where both resolve is enough: the entry's contents were hashed a moment ago.
check_target() {
  [ "$(cd "$TARGET/" 2>/dev/null && pwd -P)" = "$(cd "$ENTRY/enterprise" && pwd -P)" ] ||
    fail "$TARGET does not lead to the verified tree in $ENTRY"
}

# Points this container's activation link at the verified entry, by an atomic rename.
activate() {
  mkdir -p "$(dirname "$ACTIVE")"
  tmp="$ACTIVE.$$"
  rm -f "$tmp"
  ln -s "$ENTRY/enterprise" "$tmp"
  ruby -e 'File.rename(ARGV[0], ARGV[1])' "$tmp" "$ACTIVE"
  check_target
}

# A published entry is never replaced at boot: other containers may be running on it, and a
# verified tree that stopped matching its hash was damaged or tampered with after the fact,
# which an operator has to look at. Repairing it means stopping what mounts the volume
# first. Existence is checked before the hash: entries appear only by an atomic rename of a
# verified tree, so one that exists is complete, and one published by another container
# between two checks is hashed rather than reported as damaged. Runs before the lock too,
# so a volume this container cannot write still gets the path and the way out instead of a
# failure to open the lock. Returns only when there is no entry yet.
use_published() {
  [ -e "$ENTRY" ] || return 0
  if intact "$ENTRY/enterprise"; then
    activate
    log "enterprise/ v$VERSION in place from $ENTRY"
    exit 0
  fi
  fail "$ENTRY no longer matches the pinned hash $PINNED. Stop every container that mounts this volume, remove it (rm -rf $ENTRY) and start them again; the next boot downloads it anew"
}

cmd_ensure() {
  edition=${CW_EDITION:-}
  if [ "$edition" != "ee" ] || [ -n "${DISABLE_ENTERPRISE+set}" ]; then
    # ChatwootApp.enterprise? is false whenever DISABLE_ENTERPRISE is set, to any value.
    log "edition '${edition:-unset}'${DISABLE_ENTERPRISE+, DISABLE_ENTERPRISE set}: not using enterprise/"
    rm -f "$ACTIVE"
    if [ -L "$TARGET" ] && [ -e "$TARGET/" ]; then
      fail "$TARGET still leads to a tree"
    fi
    exit 0
  fi

  read_lock
  use_published

  # Downloading writes to the shared cache, so it happens under an exclusive lock there: a
  # second run waits, then finds the entry the first one published. flock on NFS becomes a
  # POSIX lock, which needs the file open for writing.
  if [ ! -d "$CACHE_ROOT" ]; then
    { mkdir -p "$CACHE_ROOT" && chmod 755 "$CACHE_ROOT"; } || fail "cannot create $CACHE_ROOT"
  fi
  ruby -e '
    path = ARGV.shift
    begin
      lock = File.open(path, File::RDWR | File::CREAT, 0o644)
    rescue SystemCallError => e
      warn "[enterprise] ERROR: cannot open #{path} for writing (#{e.message}), and #{File.dirname(path)} holds no verified tree for this version"
      exit 1
    end
    lock.chmod(0o644) rescue nil
    lock.flock(File::LOCK_EX)
    exit(system(*ARGV) ? 0 : 1)
  ' "$CACHE_ROOT/.lock" "$0" ensure-locked
}

cmd_ensure_locked() {
  read_lock
  use_published

  # Downloads only run under this lock, so an .incoming directory found here belongs to one
  # that was killed halfway.
  rm -rf "$CACHE_ROOT"/.incoming.*
  work=$(mktemp -d "$CACHE_ROOT/.incoming.XXXXXX")
  if ! download_tree "$VERSION" "$work"; then
    rm -rf "$work"
    fail "could not download enterprise/ for v$VERSION (network, or a source without that tag). Not starting: remove CW_EDITION=ee to run without Enterprise on purpose"
  fi
  actual=$(tree_hash "$work/enterprise" 2>/dev/null || true)
  if [ "$actual" != "$PINNED" ]; then
    rm -rf "$work"
    fail "downloaded enterprise/ for v$VERSION hashes to ${actual:-nothing}, the image pins $PINNED. Not starting"
  fi
  # mktemp made the directory 0700, and the tarball's modes went through this process's
  # umask: publish it readable by every UID that may mount this volume later.
  chmod -R u=rwX,go=rX "$work"
  mv "$work" "$ENTRY"
  activate
  log "enterprise/ v$VERSION downloaded, verified and installed"
}

command=${1:-}
[ "$#" -gt 0 ] && shift
case "$command" in
  ensure) cmd_ensure "$@" ;;
  ensure-locked) cmd_ensure_locked "$@" ;;
  lock) cmd_lock "$@" ;;
  tree-hash) cmd_tree_hash "$@" ;;
  *) fail "usage: enterprise.sh ensure | lock <out_dir> | tree-hash <enterprise_dir>" ;;
esac
