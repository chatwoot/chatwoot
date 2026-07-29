class Shopify::FeatureGate
  ACCOUNT_FEATURE = 'shopify_integration'.freeze
  GLOBAL_CONFIG = 'ENABLE_SHOPIFY_INTEGRATION'.freeze

  def self.enabled?(account: nil)
    return false unless globally_enabled?

    account.nil? || account.feature_enabled?(ACCOUNT_FEATURE)
  end

  def self.globally_enabled?
    ActiveModel::Type::Boolean.new.cast(GlobalConfigService.load(GLOBAL_CONFIG, 'false'))
  end
end
