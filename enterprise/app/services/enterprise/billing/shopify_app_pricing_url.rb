class Enterprise::Billing::ShopifyAppPricingUrl
  APP_HANDLE_FORMAT = /\A[a-z0-9][a-z0-9-]*\z/

  class Error < StandardError; end
  class ConfigurationError < Error; end
  class NotEligible < Error; end

  def initialize(account:)
    @account = account
  end

  def perform
    ensure_eligible!

    "https://admin.shopify.com/store/#{store_handle}/charges/#{app_handle}/pricing_plans"
  end

  private

  attr_reader :account

  def ensure_eligible!
    raise NotEligible, 'Shopify App Pricing is disabled' unless Shopify::FeatureGate.enabled?(account: account)
    return if account.billing_provider == 'shopify' && account.signup_source == 'shopify'

    raise NotEligible, 'Account is not billed through Shopify'
  end

  def store_handle
    domain = Shopify::ShopDomain.normalize(shopify_hook.reference_id)
    raise ConfigurationError, 'Shopify integration has an invalid shop domain' unless Shopify::ShopDomain.valid?(domain)

    domain.sub(/\.myshopify\.(?:com|io)\z/, '')
  end

  def app_handle
    handle = GlobalConfigService.load('SHOPIFY_APP_HANDLE', nil).to_s
    raise ConfigurationError, 'SHOPIFY_APP_HANDLE is invalid' unless handle.match?(APP_HANDLE_FORMAT)

    handle
  end

  def shopify_hook
    @shopify_hook ||= account.hooks.find_by!(app_id: 'shopify')
  end
end
