#!/bin/bash
# Script to verify that no "Chatwoot" branding appears in user-facing content
# Usage: bash scripts/check_branding.sh

set -e

echo "🔍 Checking for Chatwoot branding in user-facing content..."
echo ""

# Directories to check (excluding node_modules, vendor, .git)
SEARCH_DIRS="app/javascript app/views config app/mailers"

# Patterns to search for
PATTERNS=(
  "Chatwoot"
  "chatwoot"
  "chatwoot\.com"
  "www\.chatwoot\.com"
)

# Files to exclude (technical references, comments, etc.)
EXCLUDE_PATTERNS=(
  "node_modules"
  "vendor"
  ".git"
  "spec/"
  "test/"
  "\.spec\."
  "\.test\."
  "CHANGELOG"
  "LICENSE"
  "README"
  "Gemfile\.lock"
  "package-lock"
  "yarn\.lock"
  "pnpm-lock"
)

# Build exclude string for grep
EXCLUDE_STRING=""
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
  EXCLUDE_STRING="$EXCLUDE_STRING --exclude-dir=$pattern"
done

ERRORS=0
WARNINGS=0

# Check each pattern
for pattern in "${PATTERNS[@]}"; do
  echo "Checking for: $pattern"
  
  # Search in specified directories
  RESULTS=$(grep -r -n "$pattern" $SEARCH_DIRS $EXCLUDE_STRING 2>/dev/null || true)
  
  if [ -n "$RESULTS" ]; then
    # Filter out known acceptable occurrences
    FILTERED=$(echo "$RESULTS" | grep -v -E "(useBranding|replaceInstallationName|Brand\.|BRAND_|#.*Chatwoot|//.*Chatwoot|/\*.*Chatwoot)" || true)
    
    if [ -n "$FILTERED" ]; then
      echo "  ⚠️  Found occurrences:"
      echo "$FILTERED" | while IFS= read -r line; do
        # Check if it's a comment or technical reference
        if echo "$line" | grep -qE "(#|//|/\*|\*|import|require|module|export|const|let|var|function|class).*Chatwoot"; then
          echo "    ⚠️  WARNING (likely technical): $line"
          WARNINGS=$((WARNINGS + 1))
        else
          echo "    ❌ ERROR (user-facing): $line"
          ERRORS=$((ERRORS + 1))
        fi
      done
    fi
  else
    echo "  ✅ No occurrences found"
  fi
  echo ""
done

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary:"
echo "  Errors (user-facing): $ERRORS"
echo "  Warnings (technical): $WARNINGS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ERRORS -gt 0 ]; then
  echo ""
  echo "❌ Found $ERRORS user-facing references to Chatwoot"
  echo "Please review and replace with SynkiCRM branding"
  exit 1
else
  echo ""
  echo "✅ No user-facing Chatwoot references found!"
  if [ $WARNINGS -gt 0 ]; then
    echo "⚠️  Note: $WARNINGS technical references found (these are acceptable)"
  fi
  exit 0
fi

