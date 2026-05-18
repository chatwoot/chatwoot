#!/usr/bin/env bash
# apply-host-edits.sh
# -------------------
# Idempotently applies the 5 host-side edits required to wire the
# chatwoot_kanban engine (and later chatwoot_glpi_integration) into a
# Chatwoot fork. Safe to re-run.
#
# Usage:   ./apply-host-edits.sh /path/to/chatwoot-fork
# Default: current directory.
#
# What it does (only if not already applied):
#   1. Appends `gem 'chatwoot_kanban', path: 'engines/chatwoot_kanban'` to Gemfile
#   2. Inserts `mount ChatwootKanban::Engine => '/'` before the final `end` of routes.rb
#   3. Adds import + module registration in app/javascript/dashboard/store/index.js
#   4. Adds import + spread in app/javascript/dashboard/routes/dashboard/dashboard.routes.js
#   5. (best-effort) injects a Kanban sidebar entry — non-fatal if Sidebar layout differs

set -euo pipefail

REPO_ROOT="${1:-$(pwd)}"
cd "$REPO_ROOT"

# Sanity check we're inside a Chatwoot fork
if [[ ! -f Gemfile || ! -f config/routes.rb ]]; then
  echo "[!] $REPO_ROOT does not look like a Chatwoot repo (no Gemfile / routes.rb)." >&2
  exit 1
fi

if [[ ! -d engines/chatwoot_kanban ]]; then
  echo "[!] engines/chatwoot_kanban not found. Copy it into the fork first:" >&2
  echo "    cp -r <source>/engines/chatwoot_kanban engines/" >&2
  exit 1
fi

GEM_LINE="gem 'chatwoot_kanban', path: 'engines/chatwoot_kanban'"
MOUNT_LINE="  mount ChatwootKanban::Engine => '/'"
STORE_IMPORT="import kanban from 'dashboard/modules/kanban/store/kanban';"
ROUTES_IMPORT="import kanbanRoutes from 'dashboard/modules/kanban/routes/kanban.routes';"

# ----------------------------------------------------------------------
echo "[1/5] Gemfile..."
if grep -qF "$GEM_LINE" Gemfile; then
  echo "    already present, skipping."
else
  printf '\n# Chatwoot Pro extensions\n%s\n' "$GEM_LINE" >> Gemfile
  echo "    added."
fi

# ----------------------------------------------------------------------
echo "[2/5] config/routes.rb..."
if grep -qF "ChatwootKanban::Engine" config/routes.rb; then
  echo "    already mounted, skipping."
else
  # Insert before the final top-level `end` of the file.
  # Uses Perl (ships with Git for Windows / standard on Linux/macOS).
  MOUNT_LINE="$MOUNT_LINE" perl -i -e '
    my @lines = <>;
    my $last_end = -1;
    for (my $i = $#lines; $i >= 0; $i--) {
      if ($lines[$i] =~ /^\s*end\s*\r?\n?$/) { $last_end = $i; last; }
    }
    if ($last_end >= 0) {
      splice(@lines, $last_end, 0, $ENV{MOUNT_LINE} . "\n");
    }
    print @lines;
  ' config/routes.rb
  echo "    mounted."
fi

# ----------------------------------------------------------------------
echo "[3/5] app/javascript/dashboard/store/index.js..."
STORE_FILE="app/javascript/dashboard/store/index.js"
if grep -qF "$STORE_IMPORT" "$STORE_FILE"; then
  echo "    already imports kanban module."
else
  STORE_IMPORT="$STORE_IMPORT" perl -i -e '
    my @lines = <>;
    my $last_import = -1;
    for (my $i = 0; $i <= $#lines; $i++) {
      if ($lines[$i] =~ /^import\s/) { $last_import = $i; }
    }
    if ($last_import >= 0) {
      splice(@lines, $last_import + 1, 0, $ENV{STORE_IMPORT} . "\n");
    }
    my $text = join("", @lines);
    # Inject into the first `modules: {` block we find.
    if ($text =~ s/(modules:\s*\{)/$1\n    kanban,/) {
      print $text;
      print STDERR "    registered.\n";
    } else {
      print $text;
      print STDERR "    WARN: could not find modules: { — register kanban manually.\n";
    }
  ' "$STORE_FILE"
fi

# ----------------------------------------------------------------------
echo "[4/5] app/javascript/dashboard/routes/dashboard/dashboard.routes.js..."
ROUTES_FILE="app/javascript/dashboard/routes/dashboard/dashboard.routes.js"
if grep -qF "$ROUTES_IMPORT" "$ROUTES_FILE"; then
  echo "    already imports kanbanRoutes."
else
  ROUTES_IMPORT="$ROUTES_IMPORT" perl -i -e '
    my @lines = <>;
    my $last_import = -1;
    for (my $i = 0; $i <= $#lines; $i++) {
      if ($lines[$i] =~ /^import\s/) { $last_import = $i; }
    }
    if ($last_import >= 0) {
      splice(@lines, $last_import + 1, 0, $ENV{ROUTES_IMPORT} . "\n");
    }
    my $text = join("", @lines);
    if ($text =~ s/(children:\s*\[)/$1\n          ...kanbanRoutes,/) {
      print $text;
      print STDERR "    registered.\n";
    } else {
      print $text;
      print STDERR "    WARN: could not find children: [ — register kanbanRoutes manually.\n";
    }
  ' "$ROUTES_FILE"
fi

# ----------------------------------------------------------------------
echo "[5/5] Symlinking frontend into dashboard/modules/kanban..."
TARGET="app/javascript/dashboard/modules/kanban"
mkdir -p "$(dirname "$TARGET")"
if [[ -L "$TARGET" || -d "$TARGET" ]]; then
  echo "    $TARGET already exists, skipping."
else
  ln -s ../../../../engines/chatwoot_kanban/frontend "$TARGET" \
    && echo "    symlinked." \
    || { cp -r engines/chatwoot_kanban/frontend "$TARGET"; echo "    copied (symlink failed)."; }
fi

echo
echo "DONE. Review with: git diff Gemfile config/routes.rb app/javascript/dashboard/"
echo "Then: bundle install && bundle exec rails db:migrate && pnpm install"
