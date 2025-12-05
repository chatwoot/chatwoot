# ActiveStorage configuration for better URL handling
# This helps ensure that URLs generated for external services are more robust

Rails.application.configure do
  # Ensure URLs are generated with consistent host options
  config.after_initialize do
    # Make sure ActiveStorage uses the correct URL options
    ActiveStorage::Current.url_options = Rails.application.routes.default_url_options
  end
end
