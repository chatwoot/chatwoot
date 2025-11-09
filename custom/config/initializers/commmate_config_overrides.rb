# CommMate Configuration Overrides
# This initializer runs AFTER the default ConfigLoader
# and overrides only CommMate-specific configs (branding, privacy)

Rails.application.config.after_initialize do
  begin
    # Check if database and table exist
    return unless ActiveRecord::Base.connection.active?
    return unless ActiveRecord::Base.connection.table_exists?('installation_configs')

    commmate_config_path = Rails.root.join('custom/config/installation_config.yml')
    return unless File.exist?(commmate_config_path)

    Rails.logger.info '🎨 Applying CommMate config overrides...'

    # Load CommMate overrides
    commmate_configs = YAML.safe_load(File.read(commmate_config_path))

  # Apply each override (only if not already set by user)
  commmate_configs.each do |config|
    config = config.with_indifferent_access
    existing = InstallationConfig.find_by(name: config[:name])

    if existing
      # Only override if current value is still the default Chatwoot value
      chatwoot_defaults = {
        'INSTALLATION_NAME' => 'Chatwoot',
        'BRAND_NAME' => 'Chatwoot',
        'BRAND_URL' => 'https://www.chatwoot.com',
        'WIDGET_BRAND_URL' => 'https://www.chatwoot.com',
        'TERMS_URL' => 'https://www.chatwoot.com/terms-of-service',
        'PRIVACY_URL' => 'https://www.chatwoot.com/privacy-policy',
        'LOGO' => '/brand-assets/logo.svg',
        'LOGO_DARK' => '/brand-assets/logo_dark.svg',
        'LOGO_THUMBNAIL' => '/brand-assets/logo_thumbnail.svg'
      }

      # Override if value is still Chatwoot default
      if existing.value == chatwoot_defaults[config[:name]]
        existing.update!(value: config[:value])
        Rails.logger.info "  ✓ Overrode #{config[:name]}: #{config[:value]}"
      end
    else
      # Create if doesn't exist
      InstallationConfig.create!(
        name: config[:name],
        value: config[:value],
        locked: config[:locked] || false
      )
      Rails.logger.info "  ✓ Created #{config[:name]}: #{config[:value]}"
    end
  end

    # Clear cache to pick up new values
    GlobalConfig.clear_cache

    Rails.logger.info '✅ CommMate config overrides applied'
  rescue StandardError => e
    # Silently skip if database not ready or any error occurs
    # This is expected during initial setup or migrations
    Rails.logger.debug "CommMate config overrides skipped: #{e.message}" if Rails.logger
  end
end

