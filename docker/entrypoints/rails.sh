#!/bin/sh

set -x

# Remove a potentially pre-existing server.pid for Rails.
rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

echo "Waiting for postgres to become ready...."

# Let DATABASE_URL env take presedence over individual connection params.
# This is done to avoid printing the DATABASE_URL in the logs
$(docker/entrypoints/helpers/pg_database_url.rb)

# Check if pg_isready is available
if command -v pg_isready > /dev/null; then
  PG_READY="pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME"
  
  until $PG_READY
  do
    echo "Waiting for PostgreSQL to be ready..."
    sleep 2;
  done
else
  # If pg_isready is not available, use a simple connection test with timeout
  echo "pg_isready command not found, using alternative connection test"
  
  # Wait for database to be ready with a timeout
  MAX_TRIES=30
  TRIES=0
  
  while [ $TRIES -lt $MAX_TRIES ]; do
    # Try to connect using the Rails database connection
    if bundle exec rails runner 'ActiveRecord::Base.connection.execute("SELECT 1")' > /dev/null 2>&1; then
      echo "Database connection successful"
      break
    else
      echo "Waiting for database connection... (attempt $((TRIES+1))/$MAX_TRIES)"
      TRIES=$((TRIES+1))
      sleep 2
    fi
  done
  
  if [ $TRIES -eq $MAX_TRIES ]; then
    echo "Warning: Could not connect to database after $MAX_TRIES attempts, but continuing anyway"
  fi
fi

echo "Database ready to accept connections."

# Install missing gems (in production, this is a fast no-op since gems are in the image)
bundle install

# Verify gems are ready (with a timeout to avoid infinite loops)
BUNDLE_TRIES=0
BUNDLE_MAX=10
while ! bundle check > /dev/null 2>&1; do
  BUNDLE_TRIES=$((BUNDLE_TRIES+1))
  if [ $BUNDLE_TRIES -ge $BUNDLE_MAX ]; then
    echo "Warning: bundle check failed after $BUNDLE_MAX attempts, continuing anyway..."
    break
  fi
  echo "Waiting for bundle... (attempt $BUNDLE_TRIES/$BUNDLE_MAX)"
  sleep 2
done

# Prepare and migrate the database
echo "Preparing and migrating the database..."
if [ "$RAILS_ENV" = "development" ]; then
  bundle exec rails db:chatwoot_prepare || echo "Warning: Database preparation failed, but continuing..."
else
  # In production, we want to run migrations but not reset the database
  echo "Setting up database connection..."
  # We're using a managed database in Digital Ocean, so we don't need to create it
  echo "Using existing managed database in Digital Ocean..."
  
  # Wait a bit for the database connection to be ready
  sleep 5
  
  # Try to run migrations
  echo "Attempting to run database migrations..."
  if bundle exec rails db:migrate 2>&1; then
    echo "Database migrations completed successfully."
  else
    echo "Warning: Database migration failed, but continuing anyway..."
  fi
fi

# Execute the main process of the container
exec "$@"
