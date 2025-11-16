# Configure Koala to use the Facebook API version from environment
Rails.application.reloader.to_prepare do
  facebook_api_version = ENV.fetch('FACEBOOK_API_VERSION', 'v23.0')
  Koala.config.api_version = facebook_api_version
  Rails.logger.info "Koala configured to use Facebook API version: #{facebook_api_version}"
end
