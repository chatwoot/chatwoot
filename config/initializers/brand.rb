# frozen_string_literal: true

# Brand Configuration Initializer
# Centralizes brand configuration from environment variables
# with sensible defaults for SynkiCRM

module Brand
  # Brand name used throughout the application
  BRAND_NAME = ENV.fetch('BRAND_NAME', 'SynkiCRM').freeze
  
  # Product name (can differ from brand name)
  PRODUCT_NAME = ENV.fetch('BRAND_NAME', ENV.fetch('INSTALLATION_NAME', 'SynkiCRM')).freeze
  
  # Website URL
  WEBSITE = ENV.fetch('BRAND_WEBSITE', 'https://synkicrm.com.br/').freeze
  
  # Support email
  SUPPORT_EMAIL = ENV.fetch('BRAND_SUPPORT_EMAIL', 'suporte@synkicrm.com.br').freeze
  
  # Legal name (for legal documents)
  LEGAL_NAME = ENV.fetch('BRAND_LEGAL_NAME', 'SynkiCRM').freeze
  
  # Domain
  DOMAIN = ENV.fetch('BRAND_DOMAIN', 'synkicrm.com.br').freeze

  # Helper method to get all brand config as hash
  def self.config
    {
      brand_name: BRAND_NAME,
      product_name: PRODUCT_NAME,
      website: WEBSITE,
      support_email: SUPPORT_EMAIL,
      legal_name: LEGAL_NAME,
      domain: DOMAIN
    }
  end

  # Helper to replace Chatwoot references with brand name
  def self.replace_brand_name(text)
    return text unless text.is_a?(String)
    text.gsub(/Chatwoot/i, BRAND_NAME)
  end
end

