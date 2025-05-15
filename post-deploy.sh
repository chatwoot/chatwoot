#!/bin/bash

# Run migrations
bundle exec rails db:migrate

# Ensure installation type is set correctly
bundle exec rails runner "
  begin
    installation_config = InstallationConfig.find_by(name: 'INSTALLATION_CONFIG')
    installation_config = InstallationConfig.new(name: 'INSTALLATION_CONFIG') if installation_config.nil?
    installation_config.value = { installation_type: 'self_hosted' }.to_json
    installation_config.save!
    
    env_config = GlobalConfig.find_by(name: 'INSTALLATION_ENV')
    env_config = GlobalConfig.new(name: 'INSTALLATION_ENV') if env_config.nil?
    env_config.value = 'self_hosted'
    env_config.save!
    
    puts 'Successfully set Chatwoot to community edition (self-hosted mode)'
  rescue => e
    puts \"Error setting installation type: #{e.message}\"
  end
"

# Continue with regular startup
exec "$@"