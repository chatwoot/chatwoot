#!/bin/bash

# Chatwoot Local Development Setup Script
# This script sets up the chatwoot-fazerai development environment

set -e

echo "=========================================="
echo "Chatwoot Local Development Setup"
echo "=========================================="
echo ""

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${YELLOW}1. Checking Prerequisites...${NC}"

# Check Ruby version
if ! command -v ruby &> /dev/null; then
    echo -e "${RED}❌ Ruby is not installed${NC}"
    echo "Please install Ruby 3.4.4 using rvm: rvm install 3.4.4"
    exit 1
fi

RUBY_VERSION=$(ruby -v | awk '{print $2}')
echo -e "${GREEN}✓ Ruby $RUBY_VERSION installed${NC}"

# Check Node version
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed${NC}"
    echo "Please install Node.js 24.13.0 using nvm"
    exit 1
fi

NODE_VERSION=$(node -v)
echo -e "${GREEN}✓ Node.js $NODE_VERSION installed${NC}"

# Check if pnpm is installed
if ! command -v pnpm &> /dev/null; then
    echo -e "${YELLOW}⚠ pnpm is not installed, installing...${NC}"
    npm install -g pnpm
fi

PNPM_VERSION=$(pnpm -v)
echo -e "${GREEN}✓ pnpm $PNPM_VERSION installed${NC}"

# Check if PostgreSQL is installed or running
if ! command -v psql &> /dev/null; then
    echo -e "${YELLOW}⚠ PostgreSQL client not found locally${NC}"
    echo "Ensure PostgreSQL 16 is running on localhost:5432"
fi

# Check if Redis is installed or running
if ! command -v redis-cli &> /dev/null; then
    echo -e "${YELLOW}⚠ Redis client not found locally${NC}"
    echo "Ensure Redis is running on localhost:6379"
fi

echo ""
echo -e "${YELLOW}2. Installing Dependencies...${NC}"

# Install Ruby dependencies
echo "Installing Ruby gems..."
bundle install

# Install Node dependencies
echo "Installing Node.js packages..."
pnpm install

echo -e "${GREEN}✓ Dependencies installed${NC}"

echo ""
echo -e "${YELLOW}3. Setting up Database...${NC}"

# Create database
echo "Creating database..."
bundle exec rails db:create 2>/dev/null || true

# Run migrations
echo "Running migrations..."
bundle exec rails db:migrate

echo -e "${GREEN}✓ Database setup completed${NC}"

echo ""
echo -e "${YELLOW}4. Generating encryption keys (if needed)...${NC}"

# Check if encryption keys are already set
if ! grep -q "ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=" .env | grep -v "^#"; then
    echo "Generating Active Record encryption keys..."
    bundle exec rails db:encryption:init >> .env 2>/dev/null || true
fi

echo -e "${GREEN}✓ Encryption keys configured${NC}"

echo ""
echo -e "${YELLOW}5. Seeding Test Data (Optional)...${NC}"
echo "You can seed test data with:"
echo "  - bundle exec rails db:seed (minimal data)"
echo "  - bundle exec rails search:setup_test_data (bulk test data)"
echo ""

echo ""
echo -e "${GREEN}=========================================="
echo "✓ Setup completed successfully!"
echo "==========================================${NC}"
echo ""
echo "To start the development server:"
echo "  ${YELLOW}pnpm dev${NC} or ${YELLOW}overmind start -f ./Procfile.dev${NC}"
echo ""
echo "Services will be available at:"
echo "  - App: http://localhost:3000"
echo "  - Vite Dev Server: http://localhost:3036"
echo "  - MailHog (Email testing): http://localhost:1025"
echo ""
echo "To run tests:"
echo "  - Backend: bundle exec rspec spec/path/to/file_spec.rb"
echo "  - Frontend: pnpm test"
echo ""
