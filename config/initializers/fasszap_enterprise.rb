# FassZap Enterprise Configuration
# This initializer ensures all enterprise features are enabled by default

Rails.application.configure do
  # Force enterprise mode
  config.after_initialize do
    # Ensure enterprise features are always enabled
    if defined?(Account)
      Account.all.each do |account|
        # Enable all premium features for existing accounts
        account.enable_features!(
          'disable_branding',
          'audit_logs',
          'sla',
          'fabiana_integration',
          'custom_roles'
        )
      rescue => e
        Rails.logger.warn "FassZap: Could not enable features for account #{account.id}: #{e.message}"
      end
    end

    # Set installation configs for enterprise
    begin
      InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN') do |config|
        config.value = 'enterprise'
        config.locked = true
      end

      InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY') do |config|
        config.value = 10
        config.locked = true
      end

      # Configure Fabiana AI
      InstallationConfig.find_or_create_by(name: 'FABIANA_AI_PROVIDER') do |config|
        config.value = 'openai'
        config.locked = false
      end

      Rails.logger.info "FassZap: Enterprise features and Fabiana AI activated successfully"
    rescue => e
      Rails.logger.error "FassZap: Error setting enterprise configs: #{e.message}"
    end
  end
end
