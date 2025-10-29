#!/bin/bash

# CommMate Rebranding Automation Script
# Run this after merging new Chatwoot releases to reapply all branding changes
# Usage: ./custom/script/apply_commmate_branding.sh

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🎨 CommMate Rebranding Automation"
echo "=================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper functions
log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "$PROJECT_ROOT/package.json" ]; then
    log_error "Error: Not in Chatwoot project root!"
    exit 1
fi

cd "$PROJECT_ROOT"

echo "Step 1: Enable CommMate Initializers"
echo "-----------------------------------"

# Enable branding initializer
if [ -f "config/initializers/commmate_branding.rb.disabled" ]; then
    mv config/initializers/commmate_branding.rb.disabled config/initializers/commmate_branding.rb
    log_success "Enabled commmate_branding.rb"
elif [ -f "config/initializers/commmate_branding.rb" ]; then
    log_info "commmate_branding.rb already enabled"
else
    log_warning "commmate_branding.rb not found - will be created from template"
    cp custom/config/initializers/commmate_branding.rb config/initializers/commmate_branding.rb 2>/dev/null || true
fi

# Enable i18n initializer
if [ -f "config/initializers/commmate_i18n.rb.disabled" ]; then
    mv config/initializers/commmate_i18n.rb.disabled config/initializers/commmate_i18n.rb
    log_success "Enabled commmate_i18n.rb"
elif [ -f "config/initializers/commmate_i18n.rb" ]; then
    log_info "commmate_i18n.rb already enabled"
else
    log_warning "commmate_i18n.rb not found - will be created from template"
    cp custom/config/initializers/commmate_i18n.rb config/initializers/commmate_i18n.rb 2>/dev/null || true
fi

echo ""
echo "Step 2: Copy Custom Assets"
echo "-----------------------------------"

# Copy favicons
if [ -d "custom/assets/favicons" ]; then
    cp -r custom/assets/favicons/* public/
    log_success "Copied favicons to public/"
else
    log_error "custom/assets/favicons not found!"
fi

# Copy logos (both PNG and SVG)
if [ -d "custom/assets/logos" ]; then
    mkdir -p public/brand-assets
    cp custom/assets/logos/*.png public/brand-assets/ 2>/dev/null || true
    cp custom/assets/logos/*.svg public/brand-assets/ 2>/dev/null || true
    log_success "Copied logos (PNG & SVG) to public/brand-assets/"
else
    log_error "custom/assets/logos not found!"
fi

echo ""
echo "Step 3: Apply CSS Imports"
echo "-----------------------------------"

# Check if app.scss already has custom imports
if grep -q "CommMate Custom Branding" app/javascript/dashboard/assets/scss/app.scss; then
    log_info "CSS imports already applied"
else
    # Add custom CSS imports
    cat >> app/javascript/dashboard/assets/scss/app.scss << 'EOF'

// CommMate Custom Branding
@import '../../../../../custom/styles/variables';
@import '../../../../../custom/styles/branding';
EOF
    log_success "Added CSS imports to app.scss"
fi

echo ""
echo "Step 4: Replace Hardcoded Blue Colors"
echo "-----------------------------------"

# Function to replace color in file
replace_color() {
    local file=$1
    local old_color=$2
    local new_color=$3
    
    if [ -f "$file" ]; then
        if grep -q "$old_color" "$file"; then
            sed -i '' "s/$old_color/$new_color/g" "$file"
            log_success "Updated colors in $(basename $file)"
        fi
    fi
}

# Replace in JavaScript/Vue files
replace_color "app/javascript/shared/components/emoji/EmojiInput.vue" "#1f93ff" "#107e44"
replace_color "app/javascript/sdk/sdk.js" "#1f93ff" "#107e44"
replace_color "app/javascript/dashboard/routes/dashboard/settings/inbox/WidgetBuilder.vue" "#1f93ff" "#107e44"
replace_color "app/javascript/dashboard/helper/specs/fixtures/automationFixtures.js" "#1f93ff" "#107e44"
replace_color "app/javascript/dashboard/components/widgets/WootWriter/AudioRecorder.vue" "#1F93FF" "#107e44"
replace_color "app/javascript/dashboard/components/widgets/conversation/conversation/LabelSuggestion.vue" "#2781F6" "#107e44"
replace_color "app/javascript/dashboard/components-next/message/bubbles/Dyte.vue" "#2781F6" "#107e44"
replace_color "app/javascript/dashboard/components-next/icon/Logo.vue" "#2781F6" "#107e44"
replace_color "app/javascript/dashboard/components-next/HelpCenter/PortalSwitcher/CreatePortalDialog.vue" "#2781F6" "#107e44"

# Replace in SVG files
replace_color "public/brand-assets/logo.svg" "#47A7F6" "#107e44"
replace_color "public/brand-assets/logo_dark.svg" "#47A7F6" "#107e44"
replace_color "public/brand-assets/logo_thumbnail.svg" "#2781F6" "#107e44"

# Replace in hotkey SVG images
replace_color "public/assets/images/dashboard/profile/hot-key-enter.svg" "#4B7DFB" "#107e44"
replace_color "public/assets/images/dashboard/profile/hot-key-enter-dark.svg" "#4B7DFB" "#107e44"
replace_color "public/assets/images/dashboard/profile/hot-key-ctrl-enter.svg" "#4B7DFB" "#107e44"
replace_color "public/assets/images/dashboard/profile/hot-key-ctrl-enter-dark.svg" "#4B7DFB" "#107e44"

# Replace avatar placeholder colors (blue/purple → green)
if [ -f "app/javascript/dashboard/components-next/avatar/Avatar.vue" ]; then
  sed -i '' "s/#27264D', '#A19EFF/#0d6636', '#59b44b/g" app/javascript/dashboard/components-next/avatar/Avatar.vue
  sed -i '' "s/#1D2E62', '#9EB1FF/#0a4d2a', '#8cc540/g" app/javascript/dashboard/components-next/avatar/Avatar.vue
  sed -i '' "s/#EBEBFE', '#4747C2/#d7eee1', '#107e44/g" app/javascript/dashboard/components-next/avatar/Avatar.vue
  sed -i '' "s/#E1E9FF', '#3A5BC7/#c3e6d2', '#0d6636/g" app/javascript/dashboard/components-next/avatar/Avatar.vue
  log_success "Updated avatar placeholder colors"
fi

# Replace in HTML layouts
replace_color "app/views/layouts/vueapp.html.erb" "#1f93ff" "#107e44"

# Replace in manifest
replace_color "public/manifest.json" "#1f93ff" "#107e44"
sed -i '' 's/"Chatwoot"/"CommMate"/g' public/manifest.json

echo ""
echo "Step 5: Update Tailwind Colors"
echo "-----------------------------------"

# Update theme/colors.js
if grep -q "brand: '#2781F6'" theme/colors.js; then
    sed -i '' "s/brand: '#2781F6'/brand: '#107e44'/g" theme/colors.js
    log_success "Updated brand color in theme/colors.js"
fi

# Update woot palette to use green
if grep -q "25: blue.blue2" theme/colors.js; then
    sed -i '' 's/25: blue\.blue2/25: green.green2/g' theme/colors.js
    sed -i '' 's/50: blue\.blue3/50: green.green3/g' theme/colors.js
    sed -i '' 's/75: blue\.blue4/75: green.green4/g' theme/colors.js
    sed -i '' 's/100: blue\.blue5/100: green.green5/g' theme/colors.js
    sed -i '' 's/200: blue\.blue7/200: green.green7/g' theme/colors.js
    sed -i '' 's/300: blue\.blue8/300: green.green8/g' theme/colors.js
    sed -i '' 's/400: blueDark\.blue11/400: greenDark.green11/g' theme/colors.js
    sed -i '' 's/500: blueDark\.blue10/500: greenDark.green10/g' theme/colors.js
    sed -i '' 's/600: blueDark\.blue9/600: greenDark.green9/g' theme/colors.js
    sed -i '' 's/700: blueDark\.blue8/700: greenDark.green8/g' theme/colors.js
    sed -i '' 's/800: blueDark\.blue6/800: greenDark.green6/g' theme/colors.js
    sed -i '' 's/900: blueDark\.blue2/900: greenDark.green2/g' theme/colors.js
    log_success "Updated woot palette to green in theme/colors.js"
fi

# Check if tailwind.config.js has commmate colors
if ! grep -q "commmate" tailwind.config.js; then
    log_warning "Need to manually add commmate colors to tailwind.config.js"
    log_info "See: custom/docs/REBRANDING-GUIDE.md"
fi

echo ""
echo "Step 6: Fix Enterprise Edition Initializer"
echo "-----------------------------------"

# Fix the const_get_maybe_false method
if grep -q "mod&.const_defined?" config/initializers/01_inject_enterprise_edition_module.rb; then
    cat > /tmp/fix_enterprise_init.rb << 'EOF'
  def const_get_maybe_false(mod, name)
    return nil unless mod.is_a?(Module)

    mod.const_defined?(name, false) ? mod.const_get(name, false) : nil
  end
EOF
    
    # This is a complex replacement, better to warn user
    log_warning "Enterprise Edition initializer may need manual fix"
    log_info "Check: config/initializers/01_inject_enterprise_edition_module.rb"
else
    log_success "Enterprise Edition initializer looks good"
fi

echo ""
echo "Step 7: Fix Problematic Migration"
echo "-----------------------------------"

# Comment out problematic line in migration
if grep -q "ActsAsTaggableOn::Taggable::Cache.included" db/migrate/20231211010807_add_cached_labels_list.rb 2>/dev/null; then
    sed -i '' 's/^    ActsAsTaggableOn::Taggable::Cache\.included/    # ActsAsTaggableOn::Taggable::Cache.included/' db/migrate/20231211010807_add_cached_labels_list.rb
    log_success "Fixed migration 20231211010807_add_cached_labels_list.rb"
else
    log_info "Migration already fixed or not present"
fi

echo ""
echo "Step 8: Update Database Configs"
echo "-----------------------------------"

log_info "Updating InstallationConfig in database..."

eval "$(rbenv init -)" 2>/dev/null || true

bin/rails runner "
# Update branding
InstallationConfig.where(name: 'INSTALLATION_NAME').first&.update!(value: 'CommMate')
InstallationConfig.where(name: 'BRAND_NAME').first&.update!(value: 'CommMate')

# Update URLs
InstallationConfig.where(name: 'BRAND_URL').first&.update!(value: 'https://commmate.com')
InstallationConfig.where(name: 'WIDGET_BRAND_URL').first&.update!(value: 'https://commmate.com')
InstallationConfig.where(name: 'TERMS_URL').first&.update!(value: 'https://commmate.com/terms')
InstallationConfig.where(name: 'PRIVACY_URL').first&.update!(value: 'https://commmate.com/privacy')

# Update logos
InstallationConfig.where(name: 'LOGO').first&.update!(value: '/brand-assets/logo-full.png')
InstallationConfig.where(name: 'LOGO_DARK').first&.update!(value: '/brand-assets/logo-full-dark.png')
InstallationConfig.where(name: 'LOGO_THUMBNAIL').first&.update!(value: '/brand-assets/logo_thumbnail.png')

# Disable SSO/OAuth on login page
InstallationConfig.where(name: 'IS_ENTERPRISE').delete_all

puts '✓ CommMate branding applied (logos, URLs, SSO disabled)'
" 2>&1 | grep -v "warning:" | grep -v "DEPRECATION"

if [ $? -eq 0 ]; then
    log_success "Updated database configs"
else
    log_warning "Could not update database (Rails may not be running or DB may not exist)"
fi

echo ""
echo "Step 9: Verification"
echo "-----------------------------------"

# Check if all files are in place
checks_passed=0
checks_total=0

check_file() {
    checks_total=$((checks_total + 1))
    if [ -f "$1" ]; then
        log_success "$2"
        checks_passed=$((checks_passed + 1))
        return 0
    else
        log_error "$2 - FILE MISSING: $1"
        return 1
    fi
}

check_file "config/initializers/commmate_branding.rb" "Branding initializer"
check_file "config/initializers/commmate_i18n.rb" "I18n initializer"
check_file "custom/config/branding.yml" "Branding config"
check_file "custom/styles/variables.scss" "CSS variables"
check_file "custom/styles/branding.scss" "Branding styles"
check_file "custom/locales/pt_BR_custom.yml" "Portuguese translations"
check_file "public/favicon-32x32.png" "Favicon"
check_file "public/brand-assets/logo-full.png" "Logo"

echo ""
echo "=================================="
echo "Checks passed: $checks_passed/$checks_total"
echo ""

if [ $checks_passed -eq $checks_total ]; then
    echo -e "${GREEN}✓ All branding files in place!${NC}"
else
    echo -e "${YELLOW}⚠ Some files are missing - check errors above${NC}"
fi

echo ""
echo "Next Steps:"
echo "-----------------------------------"
echo "1. Restart development servers:"
echo "   pkill -f 'rails s' && pkill -f 'vite' && pkill -f sidekiq"
echo "   bin/rails s -p 3000"
echo "   bin/vite dev"
echo "   bundle exec sidekiq -C config/sidekiq.yml"
echo ""
echo "2. Hard refresh browser (Cmd/Ctrl + Shift + R)"
echo ""
echo "3. Run verification script:"
echo "   ./custom/script/verify_branding.sh"
echo ""
echo -e "${GREEN}✓ Rebranding script complete!${NC}"

