class EnableFasszapEnterprise < ActiveRecord::Migration[7.0]
  def up
    # Set enterprise as default plan
    InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN') do |config|
      config.value = 'enterprise'
      config.locked = true
    end

    InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY') do |config|
      config.value = 10
      config.locked = true
    end

    # Update branding configs to FassZap
    branding_configs = {
      'INSTALLATION_NAME' => 'FassZap',
      'BRAND_NAME' => 'FassZap',
      'BRAND_URL' => 'https://www.fasszap.com',
      'WIDGET_BRAND_URL' => 'https://www.fasszap.com',
      'TERMS_URL' => 'https://www.fasszap.com/terms-of-service',
      'PRIVACY_URL' => 'https://www.fasszap.com/privacy-policy',
      'LOGO' => '/brand-assets/fasszap_logo.svg',
      'LOGO_DARK' => '/brand-assets/fasszap_logo_dark.svg',
      'LOGO_THUMBNAIL' => '/brand-assets/fasszap_logo_thumbnail.svg'
    }

    branding_configs.each do |name, value|
      config = InstallationConfig.find_or_initialize_by(name: name)
      config.value = value
      config.save!
    end

    # Configure Fabiana AI
    fabiana_configs = {
      'FABIANA_AI_PROVIDER' => 'openai'
    }

    fabiana_configs.each do |name, value|
      config = InstallationConfig.find_or_initialize_by(name: name)
      config.value = value
      config.save!
    end

    # Enable enterprise features for all existing accounts
    if defined?(Account)
      Account.find_each do |account|
        begin
          account.enable_features!(
            'disable_branding',
            'audit_logs',
            'sla',
            'fabiana_integration',
            'custom_roles'
          )
        rescue => e
          Rails.logger.warn "Could not enable features for account #{account.id}: #{e.message}"
        end
      end
    end

    Rails.logger.info "FassZap Enterprise migration completed successfully"
  end

  def down
    # Revert to community plan
    InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.update(value: 'community')
    InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')&.update(value: 0)
    
    Rails.logger.info "Reverted FassZap Enterprise migration"
  end
end
