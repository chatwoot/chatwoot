#!/bin/sh
set -e

echo "🚀 Starting CommMate..."

# Wait for database
echo "⏳ Waiting for database..."
until PGPASSWORD=$POSTGRES_PASSWORD psql -h "$POSTGRES_HOST" -U "$POSTGRES_USERNAME" -d "$POSTGRES_DATABASE" -c '\q' 2>/dev/null; do
  echo "Waiting for PostgreSQL..."
  sleep 2
done
echo "✅ Database is ready"

# Run migrations
echo "📦 Running database migrations..."
bundle exec rails db:migrate

# Apply CommMate branding (idempotent - safe to run on every installation)
bundle exec rails commmate:branding

# Start Rails
echo "🎉 Starting Rails server..."
exec bundle exec rails s -b 0.0.0.0

