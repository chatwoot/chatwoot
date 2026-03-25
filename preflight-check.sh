#!/bin/bash

# Pre-flight Check - Chatwoot-FazerAI Development Environment
# Este script verifica se seu ambiente está pronto para desenvolvimento

set +e  # Continue even if some checks fail

echo "=========================================="
echo "🔍 Chatwoot-FazerAI Pre-Flight Check"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
WARNINGS=0

# Function to print check result
check() {
  local name=$1
  local command=$2
  local required=${3:-true}  # true=required, false=optional

  if eval "$command" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} $name"
    ((PASSED++))
  else
    if [ "$required" = "true" ]; then
      echo -e "${RED}✗${NC} $name ${RED}[REQUIRED]${NC}"
      ((FAILED++))
    else
      echo -e "${YELLOW}⚠${NC} $name ${YELLOW}[OPTIONAL]${NC}"
      ((WARNINGS++))
    fi
  fi
}

echo -e "${BLUE}1. Programming Languages${NC}"
check "Ruby 3.4.4" "ruby -v | grep -q '3.4.4'" true
check "Node.js 24.13.0" "node -v | grep -q 'v24.13.0'" true
check "pnpm" "pnpm -v" true
check "npm" "npm -v" false

echo ""
echo -e "${BLUE}2. Databases & Messaging${NC}"
check "PostgreSQL 16" "psql --version | grep -q '16'" true
check "Redis" "redis-cli ping 2>/dev/null | grep -q 'PONG'" false
check "Docker (optional)" "docker --version" false
check "Docker Compose (optional)" "docker-compose --version" false

echo ""
echo -e "${BLUE}3. Build & Testing Tools${NC}"
check "Git" "git --version" true
check "Bundler" "bundle --version" true
check "RuboCop (optional)" "bundle show rubocop > /dev/null 2>&1" false
check "ESLint (optional)" "pnpm list eslint > /dev/null 2>&1" false

echo ""
echo -e "${BLUE}4. Repository${NC}"
check "Git repository initialized" "git rev-parse --git-dir > /dev/null 2>&1" true
check "Origin remote configured" "git remote get-url origin | grep -q 'fazer-ai/chatwoot'" true
check "Upstream remote configured" "git remote get-url upstream 2>/dev/null | grep -q 'chatwoot/chatwoot'" true

echo ""
echo -e "${BLUE}5. Project Files${NC}"
check "Gemfile present" "test -f Gemfile" true
check "package.json present" "test -f package.json" true
check ".env file present" "test -f .env" false
check "docker-compose.dev.yaml present" "test -f docker-compose.dev.yaml" false
check "Setup script present" "test -f setup-dev.sh && test -x setup-dev.sh" false

echo ""
echo -e "${BLUE}6. Database Files${NC}"
check "db/migrate directory" "test -d db/migrate" true
check "db/seeds.rb present" "test -f db/seeds.rb" false

echo ""
echo -e "${BLUE}7. Configuration${NC}"
check "Rails environment config" "test -d config/environments" true
check "Localizations present" "test -f config/locales/en.yml" true

echo ""
echo "=========================================="

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All required checks passed!${NC}"
else
  echo -e "${RED}✗ Some required checks failed${NC}"
fi

echo ""
echo "Summary:"
echo -e "  ${GREEN}Passed${NC}:   $PASSED"
echo -e "  ${RED}Failed${NC}:   $FAILED"
echo -e "  ${YELLOW}Warnings${NC}: $WARNINGS"
echo ""

if [ $FAILED -gt 0 ]; then
  echo -e "${RED}Action required:${NC}"
  echo "1. Read: INSTALL_DEPENDENCIES.md"
  echo "2. Install missing required tools"
  echo "3. Run this script again to verify"
  exit 1
fi

if [ $WARNINGS -gt 0 ]; then
  echo -e "${YELLOW}Note:${NC} Some optional tools are missing"
  echo "Consider installing Docker for better isolation"
  echo "See: DOCKER_DEV.md"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "✓ Environment is ready for development!"
echo "==========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Run: ./setup-dev.sh"
echo "2. Or run: make setup-local"
echo "3. Then: pnpm dev"
echo ""
echo "Access app at: http://localhost:3000"
echo ""
