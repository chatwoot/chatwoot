#!/bin/bash

# Find all Chatwoot references in the codebase
# This helps identify what still needs to be rebranded

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Finding Chatwoot References...       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Directories to search
SEARCH_DIRS="app/javascript app/views config/locales"

# Directories to exclude
EXCLUDE_DIRS="node_modules tmp log"

# Count references
echo -e "${YELLOW}📊 Counting Chatwoot references...${NC}"
echo ""

# Frontend (JavaScript/Vue)
echo -e "${BLUE}🎨 Frontend (JavaScript/Vue):${NC}"
FRONTEND_COUNT=$(grep -r "Chatwoot\|chatwoot" app/javascript --include="*.js" --include="*.vue" 2>/dev/null | wc -l || echo "0")
echo "   Found: $FRONTEND_COUNT references"

# Backend (Ruby)
echo -e "${BLUE}💎 Backend (Ruby):${NC}"
BACKEND_COUNT=$(grep -r "Chatwoot\|chatwoot" app/views --include="*.erb" --include="*.jbuilder" 2>/dev/null | wc -l || echo "0")
echo "   Found: $BACKEND_COUNT references"

# Locales
echo -e "${BLUE}🌍 Translations (Locales):${NC}"
LOCALE_COUNT=$(grep -r "Chatwoot\|chatwoot" config/locales --include="*.yml" 2>/dev/null | wc -l || echo "0")
echo "   Found: $LOCALE_COUNT references"

# Total
TOTAL=$((FRONTEND_COUNT + BACKEND_COUNT + LOCALE_COUNT))
echo ""
echo -e "${YELLOW}📈 Total References: $TOTAL${NC}"
echo ""

# Show top files with most references
echo -e "${BLUE}📁 Top files with Chatwoot references:${NC}"
echo ""
grep -r "Chatwoot\|chatwoot" app/javascript app/views config/locales --include="*.js" --include="*.vue" --include="*.erb" --include="*.yml" 2>/dev/null | cut -d: -f1 | sort | uniq -c | sort -rn | head -10

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Analysis Complete                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}💡 What to do next:${NC}"
echo ""
echo "1. Review custom/locales/en_commmate_complete.yml"
echo "2. Add more overrides as needed"
echo "3. Set HIDE_BRANDING=true in .env"
echo "4. Rebuild image to apply changes"
echo ""
echo -e "${BLUE}📚 See: REBRANDING_GUIDE.md for detailed steps${NC}"

