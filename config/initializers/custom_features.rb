# Custom Features Initializer
# Validates configuration and initializes the service

Rails.application.config.after_initialize do
  begin
    Rails.logger.info 'Initializing custom features system...'

    # Pre-load and validate configuration
    features = CustomFeaturesService.all_features
    feature_names = CustomFeaturesService.feature_names

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

    # Make service available globally for easier access
    Rails.application.config.custom_features = CustomFeaturesService

    Rails.logger.info '🎉 Custom features system initialized successfully'

  rescue StandardError => e
    Rails.logger.error "❌ Failed to initialize custom features system: #{e.message}"
    Rails.logger.error 'The application will continue to work, but custom features may not be available.'
    Rails.logger.debug e.backtrace.join("\n") if Rails.logger.level <= Logger::DEBUG

    # Ensure a fallback service is available
    Rails.application.config.custom_features = CustomFeaturesService
  end
end