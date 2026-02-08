#!/bin/sh

set -x

echo "🚀 Initializing Chatwoot Enterprise Edition..."

# Remove a potentially pre-existing server.pid for Rails.
rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

echo "Waiting for postgres to become ready...."

# Let DATABASE_URL env take presedence over individual connection params.
$(docker/entrypoints/helpers/pg_database_url.rb)

# Set default values if not provided
export POSTGRES_PORT=${POSTGRES_PORT:-5432}
export POSTGRES_HOST=${POSTGRES_HOST:-postgres}
export POSTGRES_USERNAME=${POSTGRES_USERNAME:-postgres}

PG_READY="pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME"

until $PG_READY
do
  echo "Waiting for PostgreSQL..."
  sleep 2;
done

echo "✅ Database ready to accept connections."

# Install missing gems for local dev as we are using base image compiled for production
bundle install

BUNDLE="bundle check"

until $BUNDLE
do
  echo "Waiting for bundle..."
  sleep 2;
done

echo "✅ Bundle check passed."

# Prepare database and run migrations
echo "🔧 Preparing database..."
bundle exec rails db:chatwoot_prepare

echo "🏢 Configuring Enterprise features..."

# Apply Enterprise configurations if not already set
bundle exec rails runner "
  begin
    puts '🔧 Setting up Enterprise configuration...'
    
    # Set Enterprise plan
    enterprise_plan = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN')
    if enterprise_plan.value != 'enterprise'
      enterprise_plan.value = 'enterprise'
      enterprise_plan.save!
      puts '✅ Enterprise plan configured'
    end
    
    # Set agent quantity
    agent_quantity = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')
    if agent_quantity.value.to_i < 100
      agent_quantity.value = 100
      agent_quantity.save!
      puts '✅ Agent quantity set to 100'
    end
    
    # Enable Enterprise features for all accounts (only if settings column exists)
    if ActiveRecord::Base.connection.column_exists?(:accounts, :settings)
      Account.find_each do |account|
        enterprise_features = [
          'disable_branding',
          'audit_logs', 
          'sla',
          'captain_integration',
          'custom_roles',
          'response_bot'
        ]
        
        account.enable_features!(*enterprise_features)
        puts \"✅ Enterprise features enabled for account: #{account.name}\"
      end
    else
      puts '⚠️ Settings column not found - features will be enabled after migration'
    end
    
    puts '🎉 Enterprise setup completed!'
  rescue => e
    puts \"⚠️ Enterprise setup skipped (database not ready): #{e.message}\"
  end
"

echo "🚀 Starting Chatwoot Enterprise..."

# Execute the main process of the container
exec "$@" 