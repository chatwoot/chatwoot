#!/bin/bash

# Environment check script
set -e

echo "🔍 Checking development environment..."
echo ""

# Check Node.js
if command -v node &> /dev/null; then
  echo "✅ Node.js: $(node --version)"
else
  echo "❌ Node.js: Not installed"
  exit 1
fi

# Check pnpm
if command -v pnpm &> /dev/null; then
  echo "✅ pnpm: $(pnpm --version)"
else
  echo "❌ pnpm: Not installed. Please install pnpm: npm install -g pnpm"
  exit 1
fi

# Check PostgreSQL
if command -v psql &> /dev/null; then
  echo "✅ PostgreSQL: $(psql --version | head -n 1)"
else
  echo "⚠️  PostgreSQL: Not installed or not in PATH"
fi

# Check Redis
if command -v redis-cli &> /dev/null; then
  echo "✅ Redis: $(redis-cli --version)"
else
  echo "⚠️  Redis: Not installed or not in PATH"
fi

# Check if .env exists
if [ -f .env ]; then
  echo "✅ .env file exists"
else
  echo "❌ .env file not found. Run 'pnpm run setup:dev' to create it."
  exit 1
fi

# Check if node_modules exists
if [ -d node_modules ]; then
  echo "✅ Dependencies installed"
else
  echo "❌ Dependencies not installed. Run 'pnpm install'."
  exit 1
fi

# Try to connect to PostgreSQL
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
  if PGPASSWORD=$DATABASE_PASSWORD psql -h $DATABASE_HOST -p $DATABASE_PORT -U $DATABASE_USERNAME -d postgres -c '\q' 2>/dev/null; then
    echo "✅ PostgreSQL connection successful"
  else
    echo "❌ PostgreSQL connection failed. Check your .env credentials."
  fi

  # Try to connect to Redis
  if redis-cli -h $REDIS_HOST -p $REDIS_PORT ping 2>/dev/null | grep -q PONG; then
    echo "✅ Redis connection successful"
  else
    echo "❌ Redis connection failed. Make sure Redis is running."
  fi
fi

echo ""
echo "✨ Environment check complete!"
