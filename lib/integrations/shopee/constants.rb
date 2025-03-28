class Integrations::Shopee::Constants
  PRODUCTION_DOMAIN = 'https://partner.shopeemobile.com'.freeze
  SANDBOX_DOMAIN = 'https://partner.test-stable.shopeemobile.com'.freeze

  def self.partner_id
    @partner_id ||= ENV.fetch('SHOPEE_PARTNER_ID', nil)
  end

  def self.partner_id!
    partner_id || raise('SHOPEE_PARTNER_ID is missing')
  end

  def self.partner_key
    @partner_key ||= ENV.fetch('SHOPEE_PARTNER_KEY', nil)
  end

  def self.partner_key!
    partner_key || raise('SHOPEE_PARTNER_KEY is missing')
  end

  def self.base_url
    Rails.env.production? ? PRODUCTION_DOMAIN : SANDBOX_DOMAIN
  end
end
