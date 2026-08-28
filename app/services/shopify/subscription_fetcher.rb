class Shopify::SubscriptionFetcher
  CACHE_TTL = 2.minutes

  class NotEligible < StandardError; end

  def initialize(account:)
    @account = account
  end

  def perform(force: false)
    ensure_eligible!
    cached_snapshot = Rails.cache.read(cache_key) unless force
    return Shopify::SubscriptionSnapshot.from_h(cached_snapshot) if cached_snapshot.present?

    hook.with_lock do
      verified_at = Time.current
      snapshot = Shopify::PartnerClient.new.subscription_snapshot(
        shop_id: Shopify::ShopIdentity.new(hook: hook).shop_id,
        verified_at: verified_at
      )
      Rails.cache.write(cache_key, snapshot.to_h, expires_in: CACHE_TTL)
      snapshot
    end
  end

  private

  attr_reader :account

  def ensure_eligible!
    raise NotEligible, 'Shopify subscription lookup is disabled' unless Shopify::FeatureGate.enabled?(account: account)
    return if account.billing_provider == 'shopify' && account.signup_source == 'shopify'

    raise NotEligible, 'Account is not billed through Shopify'
  end

  def hook
    @hook ||= account.hooks.find_by!(app_id: 'shopify', status: 'enabled')
  end

  def cache_key
    "shopify:subscription_snapshot:account:#{account.id}"
  end
end
