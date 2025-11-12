#!/bin/bash

# Database reset script - WARNING: This will drop all data!
set -e

echo "⚠️  WARNING: This script will drop and recreate the database!"
read -p "Are you sure you want to continue? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^yes$ ]]; then
  echo "❌ Database reset cancelled."
  exit 1
fi

# Load environment variables
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

echo "🗑️  Dropping database..."
PGPASSWORD=$DATABASE_PASSWORD psql -h $DATABASE_HOST -p $DATABASE_PORT -U $DATABASE_USERNAME -d postgres -c "DROP DATABASE IF EXISTS $DATABASE_NAME;"

echo "📦 Creating database..."
PGPASSWORD=$DATABASE_PASSWORD psql -h $DATABASE_HOST -p $DATABASE_PORT -U $DATABASE_USERNAME -d postgres -c "CREATE DATABASE $DATABASE_NAME;"

echo "🔄 Running migrations..."
pnpm migration:run

echo "✅ Database reset complete!"
