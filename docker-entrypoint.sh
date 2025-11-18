#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Chatwoot...${NC}"

# Function to wait for PostgreSQL to be ready
wait_for_postgres() {
  echo -e "${YELLOW}Waiting for PostgreSQL to be ready...${NC}"

  max_attempts=30
  attempt=0

  until PGPASSWORD=$POSTGRES_PASSWORD psql -h "$POSTGRES_HOST" -U "$POSTGRES_USERNAME" -d "postgres" -c '\q' 2>/dev/null; do
    attempt=$((attempt + 1))

    if [ $attempt -eq $max_attempts ]; then
      echo -e "${RED}PostgreSQL is not available after $max_attempts attempts${NC}"
      exit 1
    fi

    echo -e "${YELLOW}PostgreSQL is unavailable - sleeping (attempt $attempt/$max_attempts)${NC}"
    sleep 2
  done

  echo -e "${GREEN}PostgreSQL is ready!${NC}"
}

# Function to wait for Redis to be ready
wait_for_redis() {
  if [ -n "$REDIS_URL" ]; then
    echo -e "${YELLOW}Checking Redis connection...${NC}"

    # Extract host and port from REDIS_URL
    # Format: redis://[:password@]host:port[/db_number]
    REDIS_HOST=$(echo $REDIS_URL | sed -e 's/redis:\/\///' -e 's/@.*//' -e 's/:.*//')
    if [[ $REDIS_URL == *"@"* ]]; then
      REDIS_HOST=$(echo $REDIS_URL | sed -e 's/.*@//' -e 's/:.*//')
    fi

    max_attempts=30
    attempt=0

    until timeout 2 bash -c "echo > /dev/tcp/$REDIS_HOST/6379" 2>/dev/null; do
      attempt=$((attempt + 1))

      if [ $attempt -eq $max_attempts ]; then
        echo -e "${YELLOW}Warning: Redis may not be available, but continuing...${NC}"
        break
      fi

      echo -e "${YELLOW}Redis is unavailable - sleeping (attempt $attempt/$max_attempts)${NC}"
      sleep 2
    done

    echo -e "${GREEN}Redis connection check complete!${NC}"
  fi
}

# Function to run database migrations
run_migrations() {
  echo -e "${YELLOW}Running database setup and migrations...${NC}"

  # Use the same command from Procfile's release phase
  if bundle exec rails db:chatwoot_prepare; then
    echo -e "${GREEN}Database migrations completed successfully!${NC}"
  else
    echo -e "${RED}Database migrations failed!${NC}"
    exit 1
  fi
}

# Function to setup IP lookup database
setup_ip_lookup() {
  echo -e "${YELLOW}Setting up IP lookup database...${NC}"

  if bundle exec rails ip_lookup:setup; then
    echo -e "${GREEN}IP lookup setup completed!${NC}"
  else
    echo -e "${YELLOW}Warning: IP lookup setup failed, but continuing...${NC}"
  fi
}

# Main execution
main() {
  # Wait for services
  wait_for_postgres
  wait_for_redis

  # Run migrations only if RUN_MIGRATIONS is set to true (default: true)
  if [ "${RUN_MIGRATIONS:-true}" = "true" ]; then
    run_migrations
  else
    echo -e "${YELLOW}Skipping migrations (RUN_MIGRATIONS=$RUN_MIGRATIONS)${NC}"
  fi

  # Setup IP lookup
  setup_ip_lookup

  # Start the application
  echo -e "${GREEN}Starting Puma web server...${NC}"
  echo -e "${GREEN}Environment: $RAILS_ENV${NC}"
  echo -e "${GREEN}Port: ${PORT:-3000}${NC}"

  # Execute the command passed to docker run or use default
  if [ $# -eq 0 ]; then
    # Default: start web server (same as Procfile web command)
    exec bundle exec puma -C config/puma.rb
  else
    # Execute custom command (useful for running workers, console, etc.)
    exec "$@"
  fi
}

# Run main function
main "$@"
