#!/usr/bin/env bash
# GP Bikes AI Assistant - Render Build Script
# Version: 1.0.0
# Last Updated: 2025-10-01
#
# This script runs on Render during the build phase before deployment.
# It handles Ruby gems, Node.js packages, and asset compilation.

# Exit on any error
set -o errexit
# Exit on undefined variable
set -o nounset
# Pipelines fail on first error
set -o pipefail

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔨 GP Bikes AI Assistant - Render Build Process"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 1. RUBY DEPENDENCIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo "📦 Step 1/4: Installing Ruby gems..."
echo "   Ruby version: $(ruby --version)"
echo "   Bundler version: $(bundle --version)"
echo ""

# Install gems in parallel (4 jobs) with retries
# Exclude development and test gems for production
bundle install \
  --without development test \
  --jobs 4 \
  --retry 3 \
  --deployment

echo "✅ Ruby gems installed successfully"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 2. NODE.JS DEPENDENCIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo "📦 Step 2/4: Installing Node.js packages with pnpm..."
echo "   Node.js version: $(node --version)"
echo ""

# Enable corepack (Node.js package manager manager)
corepack enable

# Prepare and activate pnpm 10.2.0 (exact version from package.json)
corepack prepare pnpm@10.2.0 --activate

echo "   pnpm version: $(pnpm --version)"
echo ""

# Install Node.js dependencies
# --frozen-lockfile: Don't update pnpm-lock.yaml (reproducible builds)
# --prod: Skip devDependencies (reduces install time and image size)
# --ignore-scripts: Skip prepare/postinstall scripts (husky, etc.)
pnpm install --frozen-lockfile --prod --ignore-scripts

echo "✅ Node.js packages installed successfully"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 3. ASSET COMPILATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo "🎨 Step 3/4: Compiling frontend assets with Vite..."
echo ""

# Precompile assets (Vite builds Vue.js frontend)
# Sets NODE_ENV=production for optimizations (minification, tree-shaking)
NODE_ENV=production bundle exec rails assets:precompile

echo "✅ Assets compiled successfully"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 4. BUILD VERIFICATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo "✅ Step 4/4: Verifying build artifacts..."
echo ""

# Check if Vite manifest exists (critical for Rails to find compiled assets)
VITE_MANIFEST="public/vite/.vite/manifest.json"
if [ ! -f "$VITE_MANIFEST" ]; then
  echo "❌ ERROR: Vite manifest not found at $VITE_MANIFEST"
  echo "   This usually means asset compilation failed."
  echo "   Check logs above for errors."
  exit 1
fi

echo "   ✓ Vite manifest found: $VITE_MANIFEST"

# Check if compiled JS bundles exist
COMPILED_JS_COUNT=$(find public/vite/assets -name "*.js" 2>/dev/null | wc -l)
if [ "$COMPILED_JS_COUNT" -eq 0 ]; then
  echo "❌ ERROR: No compiled JavaScript files found in public/vite/assets/"
  echo "   This usually means Vite build failed silently."
  exit 1
fi

echo "   ✓ Found $COMPILED_JS_COUNT compiled JavaScript files"

# Check if compiled CSS bundles exist
COMPILED_CSS_COUNT=$(find public/vite/assets -name "*.css" 2>/dev/null | wc -l)
if [ "$COMPILED_CSS_COUNT" -eq 0 ]; then
  echo "⚠️  WARNING: No compiled CSS files found"
  echo "   This might be expected if using Tailwind via JS"
else
  echo "   ✓ Found $COMPILED_CSS_COUNT compiled CSS files"
fi

# Print build summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Build Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Ruby gems: $(bundle list | wc -l | xargs) installed"
echo "   Node packages: $(pnpm list --depth=0 2>/dev/null | wc -l | xargs) installed"
echo "   JS bundles: $COMPILED_JS_COUNT files"
echo "   CSS bundles: $COMPILED_CSS_COUNT files"
echo "   Build time: ${SECONDS}s"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Build completed successfully!"
echo "   Ready for deployment 🚀"
echo ""


