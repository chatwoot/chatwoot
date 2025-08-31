# frozen_string_literal: true

# Subresource Integrity (SRI) configuration for WSC
# https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity

Rails.application.configure do
  # Enable SRI in production for asset integrity verification
  if Rails.env.production?
    config.assets.integrity = true
    
    # Generate SRI hashes for all assets
    # This ensures that resources haven't been tampered with
    config.assets.sri_hashes = %w[sha256 sha384 sha512]
  else
    # Disable SRI in development/test for easier debugging
    config.assets.integrity = false
  end
end