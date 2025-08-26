# Custom Features Initializer
# Validates configuration, sets up file watching, and initializes the service

Rails.application.config.after_initialize do
  service = CustomFeaturesService.instance

  begin
    Rails.logger.info 'Initializing custom features system...'

    # Pre-load and validate configuration
    features = service.all_features
    feature_names = service.feature_names

    if features.any?
      Rails.logger.info "✅ Successfully loaded #{features.count} custom features: #{feature_names.join(', ')}"

      # Log feature details in debug mode
      if Rails.logger.level <= Logger::DEBUG
        features.each do |feature|
          Rails.logger.debug "  - #{feature['name']}: #{feature['display_name']} (#{feature['tier'] || 'no tier'})"
        end
      end
    else
      Rails.logger.info 'ℹ️  No custom features configured. Add features to config/custom_features.yml to enable custom functionality.'
    end

    # Setup configuration watching
    # In development: Use file watching for immediate feedback
    # In production: Use automatic file change detection via Redis cache
    if Rails.env.development? && ENV['CUSTOM_FEATURES_FILE_WATCHING'] != 'false'
      service.setup_file_watching(enabled: true)
      Rails.logger.info '🔧 File watching enabled for custom features configuration (development mode)'
    else
      Rails.logger.info '📋 Automatic file change detection enabled via Redis cache (works in all environments)'
    end

    # Make service available globally for easier access
    Rails.application.config.custom_features = service

    Rails.logger.info '🎉 Custom features system initialized successfully'

  rescue StandardError => e
    Rails.logger.error "❌ Failed to initialize custom features system: #{e.message}"
    Rails.logger.error 'The application will continue to work, but custom features may not be available.'
    Rails.logger.debug e.backtrace.join("\n") if Rails.logger.level <= Logger::DEBUG

    # Ensure a fallback service is available
    Rails.application.config.custom_features = service
  end
end

# Graceful shutdown of file watching
at_exit do
  CustomFeaturesService.instance.stop_file_watching
rescue StandardError => e
  Rails.logger.debug { "Error stopping custom features file watching: #{e.message}" }
end